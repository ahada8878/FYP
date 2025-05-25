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
    "apple_pie", "baby_back_ribs", "baklava", "beef_carpaccio", "beef_tartare", "beet_salad", 
    "beignets", "bibimbap", "bread_pudding", "breakfast_burrito", "bruschetta", "caesar_salad", 
    "cannoli", "caprese_salad", "carrot_cake", "ceviche", "cheese_plate", "cheesecake", 
    "chicken_curry", "chicken_quesadilla", "chicken_wings", "chocolate_cake", "chocolate_mousse", 
    "churros", "clam_chowder", "club_sandwich", "crab_cakes", "creme_brulee", "croque_madame", 
    "cup_cakes", "deviled_eggs", "donuts", "dumplings", "edamame", "eggs_benedict", "escargots", 
    "falafel", "filet_mignon", "fish_and_chips", "foie_gras", "french_fries", "french_onion_soup", 
    "french_toast", "fried_calamari", "fried_rice", "frozen_yogurt", "garlic_bread", "gnocchi", 
    "greek_salad", "grilled_cheese_sandwich", "grilled_salmon", "guacamole", "gyoza", "hamburger", 
    "hot_and_sour_soup", "hot_dog", "huevos_rancheros", "hummus", "ice_cream", "lasagna", "lobster_bisque", 
    "lobster_roll_sandwich", "macaroni_and_cheese", "macarons", "miso_soup", "mussels", "nachos", "omelette", 
    "onion_rings", "oysters", "pad_thai", "paella", "pancakes", "panna_cotta", "peking_duck", "pho", "pizza", 
    "pork_chop", "poutine", "prime_rib", "pulled_pork_sandwich", "ramen", "ravioli", "red_velvet_cake", 
    "risotto", "samosa", "sashimi", "scallops", "seaweed_salad", "shrimp_and_grits", "spaghetti_bolognese", 
    "spaghetti_carbonara", "spring_rolls", "steak", "strawberry_shortcake", "sushi", "tacos", "takoyaki", 
    "tiramisu", "tuna_tartare", "waffles"
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
        
        return {
            # 'success': True,
            'predicted_class': CLASS_LABELS[class_idx],
            # 'class_index': class_idx,
            # 'confidence': confidence,
            # 'confidence_percentage': f"{confidence * 100:.2f}%",
            # 'all_predictions': {
            #     CLASS_LABELS[i]: float(pred[0][i]) for i in range(len(CLASS_LABELS))
            # }
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
        print(json.dumps(result, indent=2))
        
    except Exception as e:
        print(json.dumps({
            'success': False,
            'error': f"System error: {str(e)}",
            'type': type(e).__name__
        }, indent=2))