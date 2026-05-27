import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import joblib
import tensorflow as tf

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import confusion_matrix, classification_report

# ===== LOAD =====
df = pd.read_csv("dataset_5.csv")

features = ['piezo_rms','piezo_peak','mic_rms','mic_zcr','mic_energy','ratio']
X = df[features].values
y = df['label'].values

# ===== NORMALIZE =====
scaler = StandardScaler()
X = scaler.fit_transform(X)
joblib.dump(scaler, "scaler5.save")

# ===== SPLIT =====
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# ===== MODEL =====
model = tf.keras.Sequential([
    tf.keras.layers.Dense(32, activation='relu', input_shape=(6,)),
    tf.keras.layers.Dense(16, activation='relu'),
    tf.keras.layers.Dense(3, activation='softmax')
])

model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

model.summary()

# ===== TRAIN =====
history = model.fit(
    X_train, y_train,
    epochs=50,
    batch_size=16,
    validation_data=(X_test, y_test)
)

# ===== EVAL =====
loss, acc = model.evaluate(X_test, y_test)
print("✅ Accuracy:", acc)

# ===== SAVE =====
model.save("model5.h5")

# ===== TFLITE =====
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open("model5.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ Export model.tflite done")

# ===== CONFUSION MATRIX =====
y_pred = model.predict(X_test)
y_pred = np.argmax(y_pred, axis=1)

cm = confusion_matrix(y_test, y_pred)

plt.figure()
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
plt.title("Confusion Matrix")
plt.xlabel("Predicted")
plt.ylabel("Actual")
plt.show()

print(classification_report(y_test, y_pred))
