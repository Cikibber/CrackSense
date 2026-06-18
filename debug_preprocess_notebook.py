"""
=== JALANKAN SCRIPT INI DI NOTEBOOK ENVIRONMENT (YANG ADA TENSORFLOW) ===

Script ini meniru PERSIS pipeline inferensi notebook (Cell 24,
`tflite_predict_with_tta`): simple resize ke 224x224 + Test-Time Augmentation
(4 varian orientasi) yang outputnya dirata-ratakan.

Tujuannya: membandingkan hasil dengan log [TFLite DEBUG] di Flutter app
agar prediksi & probabilitas keduanya sama.

PENTING: gunakan SIMPLE RESIZE ke (224,224). JANGAN pakai
resize_preserve_aspect + center_crop (menyebabkan bug "semua Vertikal").

Cara pakai:
1. Ganti TEST_IMAGE_PATH dengan gambar yang sama yang kamu test di HP
2. Jalankan script ini di environment notebook (ada TensorFlow)
3. Bandingkan output dengan log debug Flutter
"""
import numpy as np
import tensorflow as tf

# ============================================================
# GANTI PATH INI dengan gambar yang kamu test di HP
# ============================================================
TEST_IMAGE_PATH = './dataset/test/horizontal_1.png'

TFLITE_PATH = 'cracksense_ResNet50.tflite'
IMG_SIZE = (224, 224)
CLASS_NAMES = ['Diagonal', 'Horizontal', 'Vertikal']

print(f'TensorFlow version: {tf.__version__}')
print()

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()


def tflite_predict_single(img_np):
    """Satu prediksi TFLite pada input numpy [1,224,224,3] float32."""
    interpreter.set_tensor(input_details[0]['index'], img_np)
    interpreter.invoke()
    return interpreter.get_tensor(output_details[0]['index'])[0]  # (3,)


# ── Preprocessing: SIMPLE resize ke 224x224 (tanpa crop) ──────────
img_raw = tf.io.read_file(TEST_IMAGE_PATH)
img = tf.image.decode_image(img_raw, channels=3, expand_animations=False)
img = tf.cast(img, tf.float32)
print(f'Original shape: {img.shape}')
print(f'Original [0,0] RGB: {img.numpy()[0,0]}')

img_resized = tf.image.resize(img, IMG_SIZE)  # simple resize, no crop
ch, cw = IMG_SIZE[0] // 2, IMG_SIZE[1] // 2

# ── Test-Time Augmentation: 4 varian orientasi ────────────────────
variants = [
    img_resized,                               # original
    tf.image.flip_left_right(img_resized),     # flip horizontal
    tf.image.flip_up_down(img_resized),        # flip vertikal
    tf.image.rot90(img_resized, k=1),          # rotasi 90 derajat
]

# Debug: nilai preprocessed varian original (bandingkan dgn Flutter)
v0 = tf.keras.applications.resnet.preprocess_input(variants[0])
print()
print('=== VARIAN 0 (original) — BANDINGKAN DENGAN FLUTTER DEBUG LOG ===')
print(f'Pixel[0,0]   = [{v0.numpy()[0,0,0]:.4f}, {v0.numpy()[0,0,1]:.4f}, {v0.numpy()[0,0,2]:.4f}]')
print(f'Pixel[center]= [{v0.numpy()[ch,cw,0]:.4f}, {v0.numpy()[ch,cw,1]:.4f}, {v0.numpy()[ch,cw,2]:.4f}]')
print()

# ── Inferensi tiap varian + rata-rata ─────────────────────────────
preds_all = []
for i, v in enumerate(variants):
    v_norm = tf.keras.applications.resnet.preprocess_input(v)
    v_np = tf.expand_dims(v_norm, 0).numpy().astype(np.float32)
    p = tflite_predict_single(v_np)
    preds_all.append(p)
    print(f'  Varian {i} output: {p}')

preds = np.mean(preds_all, axis=0)
print()
print('=== HASIL TTA (rata-rata 4 varian) ===')
print(f'Averaged probabilities: {preds}')
print(f'Prediction: {CLASS_NAMES[int(np.argmax(preds))]}')
print(f'Confidence: {preds[int(np.argmax(preds))]*100:.2f}%')
for i, cls in enumerate(CLASS_NAMES):
    print(f'    {cls:12s}: {preds[i]*100:6.2f}%')
