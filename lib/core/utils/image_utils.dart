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

/// Utility class for preprocessing images before TFLite inference.
///
/// Replicates the notebook's TFLite inference pipeline (Cell 24,
/// `tflite_predict_with_tta`):
/// ```python
/// img = tf.image.decode_image(raw, channels=3)
/// img = tf.cast(img, tf.float32)
/// img = tf.image.resize(img, (224, 224))         # SIMPLE resize, NO crop
/// # Test-Time Augmentation: 4 orientation variants
/// variants = [img,
///             tf.image.flip_left_right(img),
///             tf.image.flip_up_down(img),
///             tf.image.rot90(img, k=1)]
/// # each variant -> resnet.preprocess_input -> inference; outputs averaged
/// ```
///
/// IMPORTANT: the notebook deliberately uses a *simple resize* to 224×224 for
/// inference. An aspect-preserving resize + center-crop was found to bias every
/// prediction toward a single class ("all Vertikal" bug) and was removed.
class ImageUtils {
  ImageUtils._();

  // ImageNet channel means used by ResNet50 preprocessing.
  // These values match tf.keras.applications.resnet.preprocess_input exactly.
  // Applied in BGR order after channel swap.
  static const double _imagenetMeanB = 103.939;
  static const double _imagenetMeanG = 116.779;
  static const double _imagenetMeanR = 123.68;

  /// Decodes raw image bytes (JPEG/PNG) into an [img.Image].
  static img.Image? decodeImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  /// Simple bilinear resize to [outW] x [outH], performed in float32 with
  /// half-pixel-center sampling to match `tf.image.resize(img, (H, W))`
  /// (whose default is `half_pixel_centers=True`, `antialias=False`).
  ///
  /// Returns interleaved RGB floats in [0, 255], length == outW * outH * 3.
  /// Casting to float happens before interpolation (no uint8 rounding), matching
  /// the notebook which casts to float32 prior to resizing.
  static Float32List _resizeBilinearFloat(
    img.Image src,
    int outW,
    int outH,
  ) {
    final int srcW = src.width;
    final int srcH = src.height;
    final double scaleX = outW / srcW;
    final double scaleY = outH / srcH;
    final int maxX = srcW - 1;
    final int maxY = srcH - 1;

    final Float32List out = Float32List(outW * outH * 3);
    int idx = 0;

    for (int y = 0; y < outH; y++) {
      double srcY = (y + 0.5) / scaleY - 0.5;
      if (srcY < 0) srcY = 0;
      if (srcY > maxY) srcY = maxY.toDouble();
      final int y0 = srcY.floor();
      final int y1 = y0 < maxY ? y0 + 1 : y0;
      final double wy = srcY - y0;

      for (int x = 0; x < outW; x++) {
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

        out[idx++] = _lerp2(p00.r.toDouble(), p10.r.toDouble(),
            p01.r.toDouble(), p11.r.toDouble(), wx, wy);
        out[idx++] = _lerp2(p00.g.toDouble(), p10.g.toDouble(),
            p01.g.toDouble(), p11.g.toDouble(), wx, wy);
        out[idx++] = _lerp2(p00.b.toDouble(), p10.b.toDouble(),
            p01.b.toDouble(), p11.b.toDouble(), wx, wy);
      }
    }

    return out;
  }

  /// Bilinear blend of the four neighbor samples.
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

  /// Test-Time Augmentation variant. Order matches the notebook's `variants`
  /// list so per-variant outputs can be averaged identically.
  ///
  /// - [original]: no transform
  /// - [flipLeftRight]: `tf.image.flip_left_right` (mirror columns)
  /// - [flipUpDown]: `tf.image.flip_up_down` (mirror rows)
  /// - [rot90]: `tf.image.rot90(k=1)` (90° counter-clockwise)
  static const List<int> ttaVariants = <int>[0, 1, 2, 3];

  /// Applies one geometric TTA transform to a square interleaved-RGB float
  /// buffer of size [size] x [size]. Returns a new buffer of the same length.
  static Float32List _applyVariant(Float32List src, int size, int variant) {
    if (variant == 0) {
      return Float32List.fromList(src); // identity
    }
    final Float32List out = Float32List(src.length);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        int sx;
        int sy;
        switch (variant) {
          case 1: // flip_left_right: mirror columns
            sx = size - 1 - x;
            sy = y;
            break;
          case 2: // flip_up_down: mirror rows
            sx = x;
            sy = size - 1 - y;
            break;
          case 3: // rot90 k=1 (CCW), square: out[i][j] = src[j][size-1-i]
            sx = size - 1 - y;
            sy = x;
            break;
          default:
            sx = x;
            sy = y;
        }
        final int dst = (y * size + x) * 3;
        final int s = (sy * size + sx) * 3;
        out[dst] = src[s];
        out[dst + 1] = src[s + 1];
        out[dst + 2] = src[s + 2];
      }
    }
    return out;
  }

  /// Normalizes an interleaved-RGB float buffer ([0,255]) into the model's input
  /// tensor layout according to [mode]. Returns a new Float32List of equal length.
  static Float32List _normalize(Float32List rgb, PreprocessMode mode) {
    final Float32List buffer = Float32List(rgb.length);
    switch (mode) {
      case PreprocessMode.standard:
        for (int i = 0; i < rgb.length; i++) {
          buffer[i] = rgb[i] / 255.0; // RGB order, [0,1]
        }
        break;
      case PreprocessMode.resnet50:
        for (int p = 0; p < rgb.length; p += 3) {
          final double r = rgb[p];
          final double g = rgb[p + 1];
          final double b = rgb[p + 2];
          // BGR order with ImageNet mean subtraction.
          buffer[p] = b - _imagenetMeanB;
          buffer[p + 1] = g - _imagenetMeanG;
          buffer[p + 2] = r - _imagenetMeanR;
        }
        break;
    }
    return buffer;
  }

  /// Single-inference preprocessing: decode → simple resize → normalize.
  /// Returns null if decoding fails. (Kept for callers that don't use TTA.)
  static Float32List? preprocessForModel(
    Uint8List imageBytes, {
    required int inputWidth,
    required int inputHeight,
    PreprocessMode mode = PreprocessMode.standard,
  }) {
    final decoded = decodeImage(imageBytes);
    if (decoded == null) return null;
    final rgb = _resizeBilinearFloat(decoded, inputWidth, inputHeight);
    return _normalize(rgb, mode);
  }

  /// Produces the 4 Test-Time Augmentation tensors used by the notebook:
  /// decode → simple resize to [inputWidth]x[inputHeight] → {identity,
  /// flipLR, flipUD, rot90} → mode normalization.
  ///
  /// Returns a list of 4 Float32List tensors (in `ttaVariants` order), or null
  /// if decoding fails. Requires a square input ([inputWidth] == [inputHeight]).
  static List<Float32List>? preprocessVariantsForTTA(
    Uint8List imageBytes, {
    required int inputWidth,
    required int inputHeight,
    PreprocessMode mode = PreprocessMode.standard,
  }) {
    assert(inputWidth == inputHeight,
        'TTA rot90 requires a square input ($inputWidth x $inputHeight).');
    final decoded = decodeImage(imageBytes);
    if (decoded == null) return null;

    final Float32List baseRgb =
        _resizeBilinearFloat(decoded, inputWidth, inputHeight);

    return ttaVariants
        .map((v) => _normalize(_applyVariant(baseRgb, inputWidth, v), mode))
        .toList();
  }
}
