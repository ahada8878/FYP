import tensorflow as tf
import numpy as np
import sys
import json
from PIL import Image
import os
import warnings
import logging

# Configure silent operation
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
tf.get_logger().setLevel('ERROR')
warnings.filterwarnings('ignore')
logging.getLogger('PIL').setLevel(logging.WARNING)

# Load class labels (replace with your actual class labels)
CLASS_LABELS = [
    "Apple Pie", "Baby Back Ribs", "Baklava", "Beef Carpaccio", "Beef Tartare", "Beet Salad",
    "Beignets", "Bibimbap", "Bread Pudding", "Breakfast Burrito", "Bruschetta", "Caesar Salad",
    "Cannoli", "Caprese Salad", "Carrot Cake", "Ceviche", "Cheese Plate", "Cheesecake",
    "Chicken Curry", "Chicken Quesadilla", "Chicken Wings", "Chocolate Cake", "Chocolate Mousse",
    "Churros", "Clam Chowder", "Club Sandwich", "Crab Cakes", "Creme Brulee", "Croque Madame",
    "Cup Cakes", "Deviled Eggs", "Donuts", "Dumplings", "Edamame", "Eggs Benedict", "Escargots",
    "Falafel", "Filet Mignon", "Fish And Chips", "Foie Gras", "French Fries", "French Onion Soup",
    "French Toast", "Fried Calamari", "Fried Rice", "Frozen Yogurt", "Garlic Bread", "Gnocchi",
    "Greek Salad", "Grilled Cheese Sandwich", "Grilled Salmon", "Guacamole", "Gyoza", "Hamburger",
    "Hot And Sour Soup", "Hot Dog", "Huevos Rancheros", "Hummus", "Ice Cream", "Lasagna", "Lobster Bisque",
    "Lobster Roll Sandwich", "Macaroni And Cheese", "Macarons", "Miso Soup", "Mussels", "Nachos", "Omelette",
    "Onion Rings", "Oysters", "Pad Thai", "Paella", "Pancakes", "Panna Cotta", "Peking Duck", "Pho", "Pizza",
    "Pork Chop", "Poutine", "Prime Rib", "Pulled Pork Sandwich", "Ramen", "Ravioli", "Red Velvet Cake",
    "Risotto", "Samosa", "Sashimi", "Scallops", "Seaweed Salad", "Shrimp And Grits", "Spaghetti Bolognese",
    "Spaghetti Carbonara", "Spring Rolls", "Steak", "Strawberry Shortcake", "Sushi", "Tacos", "Takoyaki",
    "Tiramisu", "Tuna Tartare", "Waffles"
]

def load_model():
    """Load and configure the trained model"""
    try:
        model = tf.keras.models.load_model('mobilenetv2_food101.h5')
        model.compile(optimizer='adam', 
                     loss='sparse_categorical_crossentropy',
                     metrics=['accuracy'],
                     run_eagerly=True)
        return model
    except Exception as e:
        raise RuntimeError(f"Model loading failed: {str(e)}")

# Load model once at startup
model = load_model()

def preprocess_image(image_path):
    """Preprocess image for model prediction"""
    try:
        img = Image.open(image_path).convert('RGB').resize((224, 224))
        img_array = np.array(img) / 127.5 - 1.0  # MobileNetV2 preprocessing
        return np.expand_dims(img_array, axis=0)
    except Exception as e:
        raise ValueError(f"Image processing failed: {str(e)}")

def predict(image_path):
    """Make prediction on the input image"""
    try:
        # Preprocess image
        img_array = preprocess_image(image_path)
        
        # Make silent prediction
        with tf.device('/CPU:0'):  # Ensures no GPU progress messages
            pred = model.predict(img_array, verbose=0)
        
        # Get top prediction
        class_idx = int(np.argmax(pred))
        confidence = float(np.max(pred))
        
        # If confidence < 40%, return "Unclear Picture"
        if confidence < 0.4:
            return {
                'success': True,
                'predicted_class': "Couldn't predict food",
                'confidence': confidence,
                'confidence_percentage': f"{confidence * 100:.2f}%"
            }

        return {
            'success': True,
            'predicted_class': CLASS_LABELS[class_idx],
            'class_index': class_idx,
            'confidence': confidence,
            'confidence_percentage': f"{confidence * 100:.2f}%",
            'all_predictions': {
                CLASS_LABELS[i]: float(pred[0][i]) for i in range(len(CLASS_LABELS))
            }
        }
    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'type': type(e).__name__
        }

if __name__ == '__main__':
    try:
        if len(sys.argv) != 2:
            raise ValueError("Usage: python predict.py <image_path>")
            
        image_path = sys.argv[1]
        result = predict(image_path)
        # print(result)
        trimmed_result = result['predicted_class']
        print(json.dumps(trimmed_result, indent=2))
        
    except Exception as e:
        print(json.dumps({
            'success': False,
            'error': f"System error: {str(e)}",
            'type': type(e).__name__
        }, indent=2))