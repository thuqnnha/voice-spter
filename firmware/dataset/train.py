import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import joblib

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import confusion_matrix, classification_report

import tensorflow as tf

# ===== 1. Load dataset =====
df = pd.read_csv("dataset.csv")

print("Shape:", df.shape)
print(df.head())

# ===== 2. Feature / Label =====
features = ['piezo_rms','piezo_peak','mic_rms','mic_zcr','mic_energy','ratio']
X = df[features].values
y = df['label'].values

# ===== 3. Normalize =====
scaler = StandardScaler()
X = scaler.fit_transform(X)

joblib.dump(scaler, "scaler.save")

# ===== 4. Train/Test split =====
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# ===== 5. Model =====
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

model.summary()

# ===== 6. Train =====
history = model.fit(
    X_train, y_train,
    epochs=50,
    batch_size=16,
    validation_data=(X_test, y_test)
)

# ===== 7. Evaluate =====
loss, acc = model.evaluate(X_test, y_test)
print("✅ Accuracy:", acc)

# ===== 8. Save model =====
model.save("model.h5")

# ===== 9. Convert to TFLite =====
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open("model.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ Xuất model.tflite xong")

# ===== 10. Plot Accuracy (H.8) =====
plt.figure()
plt.plot(history.history['accuracy'], label='Train')
plt.plot(history.history['val_accuracy'], label='Validation')
plt.title('Accuracy theo Epoch')
plt.xlabel('Epoch')
plt.ylabel('Accuracy')
plt.legend()
plt.grid()
plt.show()

# ===== 11. Plot Loss (H.9) =====
plt.figure()
plt.plot(history.history['loss'], label='Train')
plt.plot(history.history['val_loss'], label='Validation')
plt.title('Loss theo Epoch')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.legend()
plt.grid()
plt.show()

# ===== 12. Confusion Matrix =====
y_pred = model.predict(X_test)
y_pred = np.argmax(y_pred, axis=1)

cm = confusion_matrix(y_test, y_pred)

plt.figure()
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
plt.title("Confusion Matrix")
plt.xlabel("Predicted")
plt.ylabel("Actual")
plt.show()

print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# ===== 13. Feature Visualization (H.11) =====
plt.figure()
sns.boxplot(data=df[features])
plt.title("Phân bố đặc trưng đầu vào")
plt.xticks(rotation=30)
plt.show()