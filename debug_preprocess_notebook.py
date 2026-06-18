"""
=== JALANKAN SCRIPT INI DI NOTEBOOK ENVIRONMENT (YANG ADA TENSORFLOW) ===

Script ini akan mendump nilai preprocessing yang sama persis 
dengan yang di-print oleh Flutter app.

Bandingkan output script ini dengan log [TFLite DEBUG] di Flutter 
untuk menemukan perbedaan.

Cara pakai:
1. Ganti TEST_IMAGE_PATH dengan path gambar yang sama yang kamu test di HP
2. Jalankan script ini di environment yang sama dengan notebook
3. Bandingkan output dengan log debug Flutter
"""
import numpy as np
import tensorflow as tf
from PIL import Image

# ============================================================
# GANTI PATH INI dengan gambar yang kamu test di HP
# ============================================================
TEST_IMAGE_PATH = './dataset/test/horizontal_1.png'

TFLITE_PATH = 'cracksense_ResNet50.tflite'
RESIZE_TO = 256   # resize shortest side ke 256 (sama dgn training)
CROP_SIZE = 224   # final center crop ke 224x224

print(f'TensorFlow version: {tf.__version__}')
print()


def resize_preserve_aspect(img):
    """Resize agar sisi terpendek = RESIZE_TO, pertahankan aspek rasio.
    Sama persis dengan pipeline training/val/test di notebook."""
    shape = tf.shape(img)
    h = tf.cast(shape[0], tf.float32)
    w = tf.cast(shape[1], tf.float32)

    scale = tf.cast(RESIZE_TO, tf.float32) / tf.minimum(h, w)

    new_h = tf.cast(tf.round(h * scale), tf.int32)
    new_w = tf.cast(tf.round(w * scale), tf.int32)

    new_h = tf.maximum(new_h, RESIZE_TO)
    new_w = tf.maximum(new_w, RESIZE_TO)

    img = tf.image.resize(img, [new_h, new_w],
                          method=tf.image.ResizeMethod.BILINEAR)
    return img


def center_crop(img):
    shape = tf.shape(img)
    h, w = shape[0], shape[1]
    offset_h = (h - CROP_SIZE) // 2
    offset_w = (w - CROP_SIZE) // 2
    img = tf.image.crop_to_bounding_box(img, offset_h, offset_w,
                                        CROP_SIZE, CROP_SIZE)
    return img


# Load and preprocess (exact same as notebook val/test pipeline)
img_raw = tf.io.read_file(TEST_IMAGE_PATH)
img = tf.image.decode_image(img_raw, channels=3, expand_animations=False)
img = tf.cast(img, tf.float32)
print(f'Original shape: {img.shape}')
print(f'Original [0,0] RGB: {img.numpy()[0,0]}')
print()

# Aspect-preserving resize (shortest side -> 256), then center-crop to 224.
img_resized = resize_preserve_aspect(img)
print(f'After aspect resize shape: {img_resized.shape}')

img_cropped = center_crop(img_resized)
print(f'After center crop [0,0] RGB: {img_cropped.numpy()[0,0]}')

# Center pixel
ch, cw = CROP_SIZE // 2, CROP_SIZE // 2
print(f'After center crop [center] RGB: {img_cropped.numpy()[ch, cw]}')
print()

# ResNet preprocess
img_preprocessed = tf.keras.applications.resnet.preprocess_input(img_cropped)
print('=== BANDINGKAN DENGAN FLUTTER DEBUG LOG ===')
print(f'Pixel[0,0] = [{img_preprocessed.numpy()[0,0,0]:.4f}, {img_preprocessed.numpy()[0,0,1]:.4f}, {img_preprocessed.numpy()[0,0,2]:.4f}]')
print(f'Pixel[center] = [{img_preprocessed.numpy()[ch,cw,0]:.4f}, {img_preprocessed.numpy()[ch,cw,1]:.4f}, {img_preprocessed.numpy()[ch,cw,2]:.4f}]')
print()

# Run inference
interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

img_batch = tf.expand_dims(img_preprocessed, axis=0).numpy().astype(np.float32)
interpreter.set_tensor(input_details[0]['index'], img_batch)
interpreter.invoke()
output = interpreter.get_tensor(output_details[0]['index'])

print(f'Raw output: {output[0]}')
print(f'Prediction: {["Diagonal", "Horizontal", "Vertikal"][np.argmax(output[0])]}')
print(f'Confidence: {output[0][np.argmax(output[0])]*100:.2f}%')
