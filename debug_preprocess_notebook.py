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
IMG_SIZE = (224, 224)

print(f'TensorFlow version: {tf.__version__}')
print()

# Load and preprocess (exact same as notebook Cell 24)
img_raw = tf.io.read_file(TEST_IMAGE_PATH)
img = tf.image.decode_image(img_raw, channels=3, expand_animations=False)
img = tf.cast(img, tf.float32)
print(f'Original shape: {img.shape}')
print(f'Original [0,0] RGB: {img.numpy()[0,0]}')
print()

# Simple resize
img_resized = tf.image.resize(img, IMG_SIZE)
print(f'After resize [0,0] RGB: {img_resized.numpy()[0,0]}')

# Center pixel
ch, cw = IMG_SIZE[0]//2, IMG_SIZE[1]//2
print(f'After resize [center] RGB: {img_resized.numpy()[ch, cw]}')
print()

# ResNet preprocess
img_preprocessed = tf.keras.applications.resnet.preprocess_input(img_resized)
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
