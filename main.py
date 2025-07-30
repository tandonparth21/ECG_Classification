from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import numpy as np
import io

app = FastAPI()

# Load model once at startup
model = load_model("2d_cnn.h5")
classes_to_include = ['M', 'N', 'Q', 'S', 'V']

@app.get("/")
async def root():
    return {"message": "ECG Model API is running!"}


@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    contents = await file.read()
    img = image.load_img(io.BytesIO(contents), target_size=(224, 224))
    x = image.img_to_array(img) / 255.0
    x = np.expand_dims(x, axis=0)
    pred = model.predict(x)[0]
    predicted_idx = int(np.argmax(pred))
    predicted_class = classes_to_include[predicted_idx]
    probs = {cls: float(f"{prob:.4f}") for cls, prob in zip(classes_to_include, pred)}
    return JSONResponse(content={
        "predicted_class": predicted_class,
        "probabilities": probs
    })
