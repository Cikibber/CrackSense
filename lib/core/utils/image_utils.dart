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
/// Implements preprocessing pipelines that match the exact TensorFlow/Keras
/// preprocessing used during model training, ensuring consistent inference
/// results between the Python notebook and mobile device.
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

  /// Resizes the image to the target dimensions using bilinear interpolation.
  static img.Image resizeImage(
    img.Image source, {
    required int width,
    required int height,
  }) {
    return img.copyResize(
      source,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Converts an [img.Image] to a normalized Float32 buffer for TFLite input.
  /// Output shape: [height, width, 3] with values normalized to [0.0, 1.0].
  ///
  /// Used for Model A (BYOL) and Model B (Baseline).
  static Float32List _imageToFloat32Standard(
    img.Image image, {
    required int width,
    required int height,
  }) {
    final Float32List buffer = Float32List(height * width * 3);
    int index = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        buffer[index++] = pixel.r / 255.0;
        buffer[index++] = pixel.g / 255.0;
        buffer[index++] = pixel.b / 255.0;
      }
    }

    return buffer;
  }

  /// Converts an [img.Image] to a Float32 buffer using ResNet50 preprocessing.
  /// Output shape: [height, width, 3] in BGR order with ImageNet mean subtracted.
  ///
  /// This matches `tf.keras.applications.resnet.preprocess_input` (mode='caffe'):
  /// 1. Pixel values kept as [0, 255] floats (NOT normalized to [0,1])
  /// 2. Channel order swapped from RGB → BGR
  /// 3. ImageNet mean subtracted per channel: B=103.939, G=116.779, R=123.68
  ///
  /// Used for Model C (ResNet50).
  static Float32List _imageToFloat32ResNet50(
    img.Image image, {
    required int width,
    required int height,
  }) {
    final Float32List buffer = Float32List(height * width * 3);
    int index = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        // pixel.r, .g, .b return num (int for uint8 images, range 0-255)
        final double r = pixel.r.toDouble();
        final double g = pixel.g.toDouble();
        final double b = pixel.b.toDouble();

        // BGR order with ImageNet mean subtraction
        // Channel 0: B - 103.939
        // Channel 1: G - 116.779
        // Channel 2: R - 123.68
        buffer[index++] = b - _imagenetMeanB;
        buffer[index++] = g - _imagenetMeanG;
        buffer[index++] = r - _imagenetMeanR;
      }
    }

    return buffer;
  }

  /// Full preprocessing pipeline: decode → resize → normalize.
  /// Returns null if decoding fails.
  ///
  /// Replicates the notebook's preprocessing pipeline:
  /// ```python
  /// img = tf.image.decode_image(img_raw, channels=3)
  /// img = tf.cast(img, tf.float32)
  /// img = tf.image.resize(img, (224, 224))    # bilinear resize
  /// img = tf.keras.applications.resnet.preprocess_input(img)  # BGR mean sub
  /// ```
  ///
  /// [mode] determines the normalization strategy:
  /// - [PreprocessMode.standard]: normalize to [0,1] (Model A & B)
  /// - [PreprocessMode.resnet50]: BGR mean subtraction (Model C)
  static Float32List? preprocessForModel(
    Uint8List imageBytes, {
    required int inputWidth,
    required int inputHeight,
    PreprocessMode mode = PreprocessMode.standard,
  }) {
    // Step 1: Decode image (equivalent to tf.image.decode_image)
    final decoded = decodeImage(imageBytes);
    if (decoded == null) return null;

    // Step 2: Bilinear resize to target size (equivalent to tf.image.resize)
    final resized = resizeImage(
      decoded,
      width: inputWidth,
      height: inputHeight,
    );

    // Step 3: Apply model-specific normalization
    switch (mode) {
      case PreprocessMode.resnet50:
        return _imageToFloat32ResNet50(
          resized,
          width: inputWidth,
          height: inputHeight,
        );
      case PreprocessMode.standard:
        return _imageToFloat32Standard(
          resized,
          width: inputWidth,
          height: inputHeight,
        );
    }
  }
}
