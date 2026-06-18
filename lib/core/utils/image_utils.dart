import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Preprocessing mode for different AI models.
enum PreprocessMode {
  /// Standard normalization to [0.0, 1.0] range.
  /// Used by Model A (BYOL) and Model B (Baseline).
  standard,

  /// ResNet50 preprocessing: RGB→BGR channel swap + ImageNet mean subtraction.
  /// Used by Model C (ResNet50).
  /// Matches `tf.keras.applications.resnet.preprocess_input` from training.
  resnet50,
}

/// Holds a resized image as interleaved RGB float data ([0, 255]) plus its
/// dimensions. Produced by [ImageUtils._resizeAspectPreserveFloat].
class _FloatImage {
  _FloatImage(this.data, this.width, this.height);

  /// Interleaved RGB floats, length == width * height * 3, values in [0, 255].
  final Float32List data;
  final int width;
  final int height;
}

/// Utility class for preprocessing images before TFLite inference.
///
/// Implements preprocessing pipelines that match the exact TensorFlow/Keras
/// preprocessing used during model training, ensuring consistent inference
/// results between the Python notebook and the mobile device.
///
/// Training/val/test pipeline (from `crack_detection_ResNet50_tf_fixed.ipynb`):
/// ```python
/// img = tf.image.decode_image(raw, channels=3)
/// img = tf.cast(img, tf.float32)              # cast to float BEFORE resize
/// img = resize_preserve_aspect(img)           # shortest side -> 256, bilinear
/// img = center_crop(img)                      # center-crop to 224x224
/// img = tf.keras.applications.resnet.preprocess_input(img)  # BGR mean sub
/// ```
class ImageUtils {
  ImageUtils._();

  // ImageNet channel means used by ResNet50 preprocessing.
  // These values match tf.keras.applications.resnet.preprocess_input exactly.
  // Applied in BGR order after channel swap.
  static const double _imagenetMeanB = 103.939;
  static const double _imagenetMeanG = 116.779;
  static const double _imagenetMeanR = 123.68;

  /// Default shortest-side resize target (matches notebook `RESIZE_TO = 256`).
  static const int defaultResizeShortestSide = 256;

  /// Decodes raw image bytes (JPEG/PNG) into an [img.Image].
  static img.Image? decodeImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  /// Aspect-preserving bilinear resize performed in float32, replicating
  /// `resize_preserve_aspect` from the training notebook.
  ///
  /// The shortest side is scaled to [shortestSide] while preserving the aspect
  /// ratio; both output dimensions are floored at [shortestSide] (matching the
  /// notebook's `tf.maximum(new_dim, RESIZE_TO)`).
  ///
  /// Sampling uses half-pixel centers — `src = (out + 0.5) / scale - 0.5` —
  /// to match `tf.image.resize(..., method=BILINEAR)` (whose default is
  /// `half_pixel_centers=True`). Interpolation is computed entirely in float
  /// from the source pixels, so there is no intermediate uint8 rounding.
  static _FloatImage _resizeAspectPreserveFloat(
    img.Image src,
    int shortestSide,
  ) {
    final int srcW = src.width;
    final int srcH = src.height;

    final double scale = shortestSide / (srcW < srcH ? srcW : srcH);

    int newW = (srcW * scale).round();
    int newH = (srcH * scale).round();
    if (newW < shortestSide) newW = shortestSide;
    if (newH < shortestSide) newH = shortestSide;

    // Per-axis scale factors (output / input).
    final double scaleX = newW / srcW;
    final double scaleY = newH / srcH;

    final Float32List out = Float32List(newW * newH * 3);
    final int maxX = srcW - 1;
    final int maxY = srcH - 1;

    int idx = 0;
    for (int y = 0; y < newH; y++) {
      // Half-pixel-center mapping back to source space.
      double srcY = (y + 0.5) / scaleY - 0.5;
      if (srcY < 0) srcY = 0;
      if (srcY > maxY) srcY = maxY.toDouble();
      final int y0 = srcY.floor();
      final int y1 = y0 < maxY ? y0 + 1 : y0;
      final double wy = srcY - y0;

      for (int x = 0; x < newW; x++) {
        double srcX = (x + 0.5) / scaleX - 0.5;
        if (srcX < 0) srcX = 0;
        if (srcX > maxX) srcX = maxX.toDouble();
        final int x0 = srcX.floor();
        final int x1 = x0 < maxX ? x0 + 1 : x0;
        final double wx = srcX - x0;

        final p00 = src.getPixel(x0, y0);
        final p10 = src.getPixel(x1, y0);
        final p01 = src.getPixel(x0, y1);
        final p11 = src.getPixel(x1, y1);

        // Bilinear interpolation per channel, computed in float.
        out[idx++] = _lerp2(
          p00.r.toDouble(), p10.r.toDouble(),
          p01.r.toDouble(), p11.r.toDouble(),
          wx, wy,
        );
        out[idx++] = _lerp2(
          p00.g.toDouble(), p10.g.toDouble(),
          p01.g.toDouble(), p11.g.toDouble(),
          wx, wy,
        );
        out[idx++] = _lerp2(
          p00.b.toDouble(), p10.b.toDouble(),
          p01.b.toDouble(), p11.b.toDouble(),
          wx, wy,
        );
      }
    }

    return _FloatImage(out, newW, newH);
  }

  /// Bilinear blend of the four neighbor samples.
  /// [wx]/[wy] are the fractional offsets toward the +1 neighbor.
  static double _lerp2(
    double v00,
    double v10,
    double v01,
    double v11,
    double wx,
    double wy,
  ) {
    final double top = v00 + (v10 - v00) * wx;
    final double bottom = v01 + (v11 - v01) * wx;
    return top + (bottom - top) * wy;
  }

  /// Center-crops the float image to [cropWidth] x [cropHeight] and normalizes
  /// to [0.0, 1.0] in RGB order.
  ///
  /// Used for Model A (BYOL) and Model B (Baseline).
  static Float32List _cropAndNormalizeStandard(
    _FloatImage src, {
    required int cropWidth,
    required int cropHeight,
  }) {
    final int offsetX = (src.width - cropWidth) ~/ 2;
    final int offsetY = (src.height - cropHeight) ~/ 2;
    final int rowStride = src.width * 3;

    final Float32List buffer = Float32List(cropWidth * cropHeight * 3);
    int index = 0;

    for (int y = 0; y < cropHeight; y++) {
      int srcIdx = (offsetY + y) * rowStride + offsetX * 3;
      for (int x = 0; x < cropWidth; x++) {
        buffer[index++] = src.data[srcIdx++] / 255.0; // R
        buffer[index++] = src.data[srcIdx++] / 255.0; // G
        buffer[index++] = src.data[srcIdx++] / 255.0; // B
      }
    }

    return buffer;
  }

  /// Center-crops the float image to [cropWidth] x [cropHeight] and applies
  /// ResNet50 preprocessing: BGR channel order with ImageNet mean subtracted.
  ///
  /// Matches `tf.keras.applications.resnet.preprocess_input` (mode='caffe'):
  /// 1. Pixel values kept as [0, 255] floats (NOT normalized to [0,1])
  /// 2. Channel order swapped from RGB → BGR
  /// 3. ImageNet mean subtracted per channel: B=103.939, G=116.779, R=123.68
  ///
  /// Used for Model C (ResNet50).
  static Float32List _cropAndNormalizeResNet50(
    _FloatImage src, {
    required int cropWidth,
    required int cropHeight,
  }) {
    final int offsetX = (src.width - cropWidth) ~/ 2;
    final int offsetY = (src.height - cropHeight) ~/ 2;
    final int rowStride = src.width * 3;

    final Float32List buffer = Float32List(cropWidth * cropHeight * 3);
    int index = 0;

    for (int y = 0; y < cropHeight; y++) {
      int srcIdx = (offsetY + y) * rowStride + offsetX * 3;
      for (int x = 0; x < cropWidth; x++) {
        final double r = src.data[srcIdx++];
        final double g = src.data[srcIdx++];
        final double b = src.data[srcIdx++];

        // BGR order with ImageNet mean subtraction.
        buffer[index++] = b - _imagenetMeanB;
        buffer[index++] = g - _imagenetMeanG;
        buffer[index++] = r - _imagenetMeanR;
      }
    }

    return buffer;
  }

  /// Full preprocessing pipeline matching the training notebook:
  /// decode → float aspect-preserving resize (shortest side → [resizeShortestSide])
  /// → center-crop to [inputWidth] x [inputHeight] → mode-specific normalization.
  ///
  /// Returns null if decoding fails.
  ///
  /// [mode] determines the normalization strategy:
  /// - [PreprocessMode.standard]: normalize to [0,1] in RGB (Model A & B)
  /// - [PreprocessMode.resnet50]: BGR mean subtraction (Model C)
  ///
  /// [resizeShortestSide] defaults to 256 to match the notebook's
  /// `RESIZE_TO = 256`; the center crop size equals the input dimensions.
  static Float32List? preprocessForModel(
    Uint8List imageBytes, {
    required int inputWidth,
    required int inputHeight,
    PreprocessMode mode = PreprocessMode.standard,
    int resizeShortestSide = defaultResizeShortestSide,
  }) {
    // Step 1: Decode image (equivalent to tf.image.decode_image + cast float32).
    final decoded = decodeImage(imageBytes);
    if (decoded == null) return null;

    // Step 2: Aspect-preserving float bilinear resize (shortest side -> target).
    final resized = _resizeAspectPreserveFloat(decoded, resizeShortestSide);

    // Step 3: Center-crop to the model input size + mode-specific normalization.
    switch (mode) {
      case PreprocessMode.resnet50:
        return _cropAndNormalizeResNet50(
          resized,
          cropWidth: inputWidth,
          cropHeight: inputHeight,
        );
      case PreprocessMode.standard:
        return _cropAndNormalizeStandard(
          resized,
          cropWidth: inputWidth,
          cropHeight: inputHeight,
        );
    }
  }
}
