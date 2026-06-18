import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:drone_crack_detection/core/utils/image_utils.dart';

void main() {
  group('ImageUtils Preprocessing Tests', () {
    test('Standard Preprocessing - [0.0, 1.0] Normalization & RGB Order', () {
      // Create a 2x2 test image in memory
      final image = img.Image(width: 2, height: 2);
      
      // Set pixel values using setPixelRgb
      image.setPixelRgb(0, 0, 255, 128, 64);
      image.setPixelRgb(1, 0, 0, 255, 0);
      image.setPixelRgb(0, 1, 128, 128, 128);
      image.setPixelRgb(1, 1, 0, 0, 255);

      final pngBytes = img.encodePng(image);

      // Standard preprocessing is RGB order divided by 255.0
      final preprocessed = ImageUtils.preprocessForModel(
        pngBytes,
        inputWidth: 2,
        inputHeight: 2,
        mode: PreprocessMode.standard,
      );

      expect(preprocessed, isNotNull);
      expect(preprocessed!.length, equals(2 * 2 * 3));

      // Assert Pixel (0,0) - RGB: 255, 128, 64 -> 1.0, 128/255, 64/255
      expect(preprocessed[0], closeTo(1.0, 1e-4));
      expect(preprocessed[1], closeTo(128.0 / 255.0, 1e-4));
      expect(preprocessed[2], closeTo(64.0 / 255.0, 1e-4));

      // Assert Pixel (1,0) - RGB: 0, 255, 0 -> 0.0, 1.0, 0.0
      expect(preprocessed[3], closeTo(0.0, 1e-4));
      expect(preprocessed[4], closeTo(1.0, 1e-4));
      expect(preprocessed[5], closeTo(0.0, 1e-4));
    });

    test('ResNet50 Preprocessing - BGR Swap & ImageNet Mean Subtraction', () {
      // Create a 2x2 test image in memory
      final image = img.Image(width: 2, height: 2);
      
      // Set pixel values
      image.setPixelRgb(0, 0, 255, 128, 64); // R=255, G=128, B=64
      image.setPixelRgb(1, 0, 0, 255, 0);    // R=0, G=255, B=0
      image.setPixelRgb(0, 1, 128, 128, 128);
      image.setPixelRgb(1, 1, 0, 0, 255);

      final pngBytes = img.encodePng(image);

      // ResNet50 preprocessing uses BGR order with ImageNet mean subtracted:
      // Channel 0 (B): B - 103.939
      // Channel 1 (G): G - 116.779
      // Channel 2 (R): R - 123.68
      final preprocessed = ImageUtils.preprocessForModel(
        pngBytes,
        inputWidth: 2,
        inputHeight: 2,
        mode: PreprocessMode.resnet50,
      );

      expect(preprocessed, isNotNull);
      expect(preprocessed!.length, equals(2 * 2 * 3));

      // Assert Pixel (0,0) - BGR order and subtracted mean
      // B = 64 -> 64 - 103.939 = -39.939
      // G = 128 -> 128 - 116.779 = 11.221
      // R = 255 -> 255 - 123.68 = 131.32
      expect(preprocessed[0], closeTo(64.0 - 103.939, 1e-4));
      expect(preprocessed[1], closeTo(128.0 - 116.779, 1e-4));
      expect(preprocessed[2], closeTo(255.0 - 123.68, 1e-4));

      // Assert Pixel (1,0) - BGR order and subtracted mean
      // B = 0 -> 0 - 103.939 = -103.939
      // G = 255 -> 255 - 116.779 = 138.221
      // R = 0 -> 0 - 123.68 = -123.68
      expect(preprocessed[3], closeTo(0.0 - 103.939, 1e-4));
      expect(preprocessed[4], closeTo(255.0 - 116.779, 1e-4));
      expect(preprocessed[5], closeTo(0.0 - 123.68, 1e-4));
    });

    test('Preprocess existing file test_known_4x4.png', () {
      final file = File('test_known_4x4.png');
      expect(file.existsSync(), isTrue);
      
      final bytes = file.readAsBytesSync();
      final preprocessed = ImageUtils.preprocessForModel(
        bytes,
        inputWidth: 4,
        inputHeight: 4,
        mode: PreprocessMode.resnet50,
      );
      
      expect(preprocessed, isNotNull);
      expect(preprocessed!.length, equals(4 * 4 * 3));

      // Let's assert that the dimensions and preprocessing works on files correctly
      // (BGR order and ImageNet mean subtraction)
      final firstPixelB = preprocessed[0];
      final firstPixelG = preprocessed[1];
      final firstPixelR = preprocessed[2];

      expect(firstPixelB, greaterThanOrEqualTo(-103.939 - 1e-4));
      expect(firstPixelB, lessThanOrEqualTo(255.0 - 103.939 + 1e-4));

      expect(firstPixelG, greaterThanOrEqualTo(-116.779 - 1e-4));
      expect(firstPixelG, lessThanOrEqualTo(255.0 - 116.779 + 1e-4));

      expect(firstPixelR, greaterThanOrEqualTo(-123.68 - 1e-4));
      expect(firstPixelR, lessThanOrEqualTo(255.0 - 123.68 + 1e-4));
    });
  });
}
