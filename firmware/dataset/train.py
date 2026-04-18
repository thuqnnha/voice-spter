import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import tensorflow as tf
import joblib

# ===== Load dataset =====
df = pd.read_csv("dataset.csv")

print("Shape:", df.shape)
print(df.head())

# ===== Feature / Label =====
X = df[['piezo_rms','piezo_peak','mic_rms','mic_zcr','mic_energy','ratio']].values
y = df['label'].values

# ===== Normalize =====
scaler = StandardScaler()
X = scaler.fit_transform(X)

joblib.dump(scaler, "scaler.save")

# ===== Train/Test =====
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# ===== Model =====
model = tf.keras.Sequential([
    tf.keras.layers.Dense(16, activation='relu', input_shape=(6,)),
    tf.keras.layers.Dense(8, activation='relu'),
    tf.keras.layers.Dense(3, activation='softmax')
])

model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# ===== Train =====
model.fit(X_train, y_train, epochs=50, validation_data=(X_test, y_test))

# ===== Evaluate =====
loss, acc = model.evaluate(X_test, y_test)
print("✅ Accuracy:", acc)

# ===== Convert TFLite =====
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open("model.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ Xuất model.tflite xong")
