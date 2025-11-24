import tensorflow as tf
import numpy as np
import sys
import json
from PIL import Image
import os
import warnings
import logging
import cv2
import torch
from ultralytics import YOLO
import google.generativeai as genai

# --- LINKING TO NEW DATA FILE ---
# We only import DISH_RECIPES for now. We will use INGREDIENT_DB later.
from ingredients_data import DISH_RECIPES 

# Configure silent operation
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
tf.get_logger().setLevel('ERROR')
warnings.filterwarnings('ignore')
logging.getLogger('PIL').setLevel(logging.WARNING)

# --- EXISTING CLASS LABELS ---
CLASS_LABELS = [
    "Apple Pie: calories: 1325, protein: 10g, fat: 65g, carbohydrates: 185g",
    "Baby Back Ribs: calories: 1460, protein: 102.5g, fat: 111.5g, carbohydrates: 0g",
    "Baklava: calories: 2140, protein: 33.2g, fat: 145.7g, carbohydrates: 187.7g",
    "Beef Carpaccio: calories: 1450, protein: 114g, fat: 110g, carbohydrates: 0g",
    "Beef Tartare: calories: 900, protein: 100g, fat: 60g, carbohydrates: 0g",
    "Beet Salad: calories: 145, protein: 10g, fat: 1g, carbohydrates: 30g",
    "Beignets: calories: 2255, protein: 35g, fat: 145g, carbohydrates: 200g",
    "Bibimbap: calories: 750, protein: 30g, fat: 20g, carbohydrates: 115g",
    "Bread Pudding: calories: 1035, protein: 25g, fat: 35g, carbohydrates: 160g",
    "Breakfast Burrito: calories: 1385, protein: 55g, fat: 80g, carbohydrates: 115g",
    "Bruschetta: calories: 750, protein: 25g, fat: 30g, carbohydrates: 100g",
    "Caesar Salad: calories: 850, protein: 25g, fat: 75g, carbohydrates: 25g",
    "Cannoli: calories: 1250, protein: 27.5g, fat: 67.5g, carbohydrates: 150g",
    "Caprese Salad: calories: 1100, protein: 60g, fat: 95g, carbohydrates: 10g",
    "Carrot Cake: calories: 2000, protein: 20g, fat: 115g, carbohydrates: 225g",
    "Ceviche: calories: 400, protein: 70g, fat: 8g, carbohydrates: 15g",
    "Cheese Plate: calories: 2000, protein: 125g, fat: 165g, carbohydrates: 7g",
    "Cheesecake: calories: 1600, protein: 30g, fat: 110g, carbohydrates: 125g",
    "Chicken Curry: calories: 950, protein: 75g, fat: 60g, carbohydrates: 35g",
    "Chicken Quesadilla: calories: 1350, protein: 90g, fat: 70g, carbohydrates: 95g",
    "Chicken Wings: calories: 1450, protein: 90g, fat: 100g, carbohydrates: 40g",
    "Chocolate Cake: calories: 2100, protein: 25g, fat: 100g, carbohydrates: 290g",
    "Chocolate Mousse: calories: 1750, protein: 30g, fat: 145g, carbohydrates: 100g",
    "Churros: calories: 2200, protein: 25g, fat: 120g, carbohydrates: 250g",
    "Clam Chowder: calories: 450, protein: 20g, fat: 25g, carbohydrates: 35g",
    "Club Sandwich: calories: 1050, protein: 68g, fat: 53g, carbohydrates: 75g",
    "Crab Cakes: calories: 1000, protein: 70g, fat: 60g, carbohydrates: 45g",
    "Creme Brulee: calories: 1650, protein: 25g, fat: 150g, carbohydrates: 50g",
    "Croque Madame: calories: 875, protein: 44g, fat: 50g, carbohydrates: 63g",
    "Cup Cakes: calories: 2000, protein: 20g, fat: 100g, carbohydrates: 275g",
    "Deviled Eggs: calories: 1500, protein: 60g, fat: 135g, carbohydrates: 10g",
    "Donuts: calories: 2100, protein: 25g, fat: 110g, carbohydrates: 250g",
    "Dumplings: calories: 850, protein: 40g, fat: 35g, carbohydrates: 95g",
    "Edamame: calories: 600, protein: 55g, fat: 25g, carbohydrates: 45g",
    "Eggs Benedict: calories: 1500, protein: 60g, fat: 110g, carbohydrates: 65g",
    "Escargots: calories: 700, protein: 80g, fat: 40g, carbohydrates: 10g",
    "Falafel: calories: 1650, protein: 65g, fat: 90g, carbohydrates: 150g",
    "Filet Mignon: calories: 1350, protein: 150g, fat: 80g, carbohydrates: 0g",
    "Fish And Chips: calories: 1000, protein: 50g, fat: 55g, carbohydrates: 80g",
    "Foie Gras: calories: 2250, protein: 60g, fat: 225g, carbohydrates: 20g",
    "French Fries: calories: 1550, protein: 17g, fat: 75g, carbohydrates: 205g",
    "French Onion Soup: calories: 400, protein: 15g, fat: 20g, carbohydrates: 40g",
    "French Toast: calories: 1150, protein: 35g, fat: 50g, carbohydrates: 140g",
    "Fried Calamari: calories: 1100, protein: 85g, fat: 60g, carbohydrates: 55g",
    "Fried Rice: calories: 850, protein: 30g, fat: 30g, carbohydrates: 115g",
    "Frozen Yogurt: calories: 1100, protein: 20g, fat: 20g, carbohydrates: 215g",
    "Garlic Bread: calories: 1750, protein: 40g, fat: 105g, carbohydrates: 160g",
    "Gnocchi: calories: 1000, protein: 30g, fat: 45g, carbohydrates: 120g",
    "Greek Salad: calories: 600, protein: 25g, fat: 45g, carbohydrates: 30g",
    "Grilled Cheese Sandwich: calories: 1500, protein: 60g, fat: 90g, carbohydrates: 110g",
    "Grilled Salmon: calories: 1050, protein: 100g, fat: 70g, carbohydrates: 0g",
    "Guacamole: calories: 800, protein: 10g, fat: 75g, carbohydrates: 40g",
    "Gyoza: calories: 1100, protein: 45g, fat: 55g, carbohydrates: 110g",
    "Hamburger: calories: 1300, protein: 65g, fat: 70g, carbohydrates: 100g",
    "Hot And Sour Soup: calories: 350, protein: 20g, fat: 15g, carbohydrates: 35g",
    "Hot Dog: calories: 1400, protein: 50g, fat: 90g, carbohydrates: 95g",
    "Huevos Rancheros: calories: 800, protein: 40g, fat: 50g, carbohydrates: 50g",
    "Hummus: calories: 850, protein: 40g, fat: 45g, carbohydrates: 70g",
    "Ice Cream: calories: 1000, protein: 17g, fat: 55g, carbohydrates: 115g",
    "Lasagna: calories: 750, protein: 45g, fat: 30g, carbohydrates: 75g",
    "Lobster Bisque: calories: 700, protein: 20g, fat: 60g, carbohydrates: 20g",
    "Lobster Roll Sandwich: calories: 800, protein: 45g, fat: 40g, carbohydrates: 65g",
    "Macaroni And Cheese: calories: 950, protein: 40g, fat: 45g, carbohydrates: 95g",
    "Macarons: calories: 2000, protein: 45g, fat: 100g, carbohydrates: 230g",
    "Miso Soup: calories: 150, protein: 10g, fat: 5g, carbohydrates: 15g",
    "Mussels: calories: 700, protein: 100g, fat: 20g, carbohydrates: 30g",
    "Nachos: calories: 1900, protein: 70g, fat: 120g, carbohydrates: 140g",
    "Omelette: calories: 1000, protein: 60g, fat: 80g, carbohydrates: 10g",
    "Onion Rings: calories: 1750, protein: 20g, fat: 100g, carbohydrates: 190g",
    "Oysters: calories: 400, protein: 45g, fat: 12g, carbohydrates: 25g",
    "Pad Thai: calories: 850, protein: 35g, fat: 25g, carbohydrates: 120g",
    "Paella: calories: 800, protein: 50g, fat: 25g, carbohydrates: 95g",
    "Pancakes: calories: 1100, protein: 25g, fat: 20g, carbohydrates: 205g",
    "Panna Cotta: calories: 1550, protein: 25g, fat: 120g, carbohydrates: 90g",
    "Peking Duck: calories: 1700, protein: 95g, fat: 140g, carbohydrates: 10g",
    "Pho: calories: 600, protein: 40g, fat: 20g, carbohydrates: 65g",
    "Pizza: calories: 1350, protein: 60g, fat: 50g, carbohydrates: 165g",
    "Pork Chop: calories: 1150, protein: 130g, fat: 70g, carbohydrates: 0g",
    "Poutine: calories: 1850, protein: 40g, fat: 125g, carbohydrates: 140g",
    "Prime Rib: calories: 1850, protein: 110g, fat: 160g, carbohydrates: 0g",
    "Pulled Pork Sandwich: calories: 1150, protein: 75g, fat: 50g, carbohydrates: 100g",
    "Ramen: calories: 700, protein: 30g, fat: 25g, carbohydrates: 90g",
    "Ravioli: calories: 800, protein: 35g, fat: 30g, carbohydrates: 100g",
    "Red Velvet Cake: calories: 1950, protein: 25g, fat: 95g, carbohydrates: 250g",
    "Risotto: calories: 900, protein: 25g, fat: 40g, carbohydrates: 110g",
    "Samosa: calories: 1300, protein: 25g, fat: 70g, carbohydrates: 145g",
    "Sashimi: calories: 700, protein: 115g, fat: 20g, carbohydrates: 5g",
    "Scallops: calories: 750, protein: 75g, fat: 40g, carbohydrates: 20g",
    "Seaweed Salad: calories: 350, protein: 10g, fat: 20g, carbohydrates: 35g",
    "Shrimp And Grits: calories: 700, protein: 40g, fat: 35g, carbohydrates: 55g",
    "Spaghetti Bolognese: calories: 750, protein: 40g, fat: 30g, carbohydrates: 80g",
    "Spaghetti Carbonara: calories: 1100, protein: 40g, fat: 65g, carbohydrates: 85g",
    "Spring Rolls: calories: 1000, protein: 30g, fat: 60g, carbohydrates: 90g",
    "Steak: calories: 1350, protein: 150g, fat: 80g, carbohydrates: 0g",
    "Strawberry Shortcake: calories: 1150, protein: 10g, fat: 55g, carbohydrates: 160g",
    "Sushi: calories: 700, protein: 35g, fat: 15g, carbohydrates: 105g",
    "Tacos: calories: 1100, protein: 60g, fat: 60g, carbohydrates: 80g",
    "Takoyaki: calories: 1000, protein: 35g, fat: 50g, carbohydrates: 100g",
    "Tiramisu: calories: 1400, protein: 30g, fat: 105g, carbohydrates: 85g",
    "Tuna Tartare: calories: 850, protein: 120g, fat: 40g, carbohydrates: 5g",
    "Waffles: calories: 1250, protein: 30g, fat: 60g, carbohydrates: 150g"
]

def load_classification_model():
    """Load and configure the trained classification model"""
    try:
        model = tf.keras.models.load_model('mobilenetv2_food101.h5')
        model.compile(optimizer='adam', 
                     loss='sparse_categorical_crossentropy',
                     metrics=['accuracy'],
                     run_eagerly=True)
        return model
    except Exception as e:
        sys.stderr.write(f"Model loading failed: {str(e)}\n")
        return None

def load_depth_models():
    """Load YOLO and MiDaS models for depth estimation"""
    try:
        yolo_model = YOLO('yolov8n-seg.pt')
        midas = torch.hub.load("intel-isl/MiDaS", "DPT_Hybrid")
        device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
        midas.to(device)
        midas.eval()
        midas_transforms = torch.hub.load("intel-isl/MiDaS", "transforms").dpt_transform
        return yolo_model, midas, midas_transforms, device
    except Exception as e:
        sys.stderr.write(f"Depth models loading failed: {str(e)}\n")
        return None, None, None, None

# Load models globally
model = load_classification_model()
yolo_model, midas, midas_transforms, device = load_depth_models()

def preprocess_image(image_path):
    """Preprocess image for model prediction"""
    try:
        img = Image.open(image_path).convert('RGB').resize((224, 224))
        img_array = np.array(img) / 127.5 - 1.0  # MobileNetV2 preprocessing
        return np.expand_dims(img_array, axis=0)
    except Exception as e:
        raise ValueError(f"Image processing failed: {str(e)}")

def generate_depth_map(image_path):
    """Generate and store depth map image in backend folder"""
    if yolo_model is None or midas is None:
        return

    try:
        pil_image = Image.open(image_path).convert("RGB")
        w, h = pil_image.size
        img_np = np.array(pil_image)

        results = yolo_model(pil_image, verbose=False)
        target_mask = np.zeros((h, w), dtype=np.uint8)
        
        if results[0].masks is not None:
            boxes = results[0].boxes.data.cpu().numpy()
            masks = results[0].masks.data.cpu().numpy()
            
            for i, box in enumerate(boxes):
                class_id = int(box[5])
                mask_resized = cv2.resize(masks[i], (w, h))
                if class_id not in [0, 60, 61]:
                    target_mask = np.maximum(target_mask, mask_resized)

        if np.sum(target_mask) == 0:
            center_x, center_y = w // 2, h // 2
            radius = min(w, h) // 3
            Y, X = np.ogrid[:h, :w]
            dist_from_center = np.sqrt((X - center_x)**2 + (Y - center_y)**2)
            target_mask[dist_from_center <= radius] = 1

        input_batch = midas_transforms(img_np).to(device)
        with torch.no_grad():
            prediction = midas(input_batch)
            prediction = torch.nn.functional.interpolate(
                prediction.unsqueeze(1), size=(h, w), mode="bicubic", align_corners=False
            ).squeeze()
        
        depth_map = prediction.cpu().numpy()
        d_min, d_max = depth_map.min(), depth_map.max()
        depth_norm = (depth_map - d_min) / (d_max - d_min) if (d_max - d_min) > 0 else depth_map
        
        masked_depth = depth_norm * target_mask
        dilated = cv2.dilate(target_mask, np.ones((10,10), np.uint8), iterations=1)
        ring = dilated - target_mask
        floor = np.median(depth_norm[ring == 1]) if np.sum(ring) > 0 else 0
        
        height_map = masked_depth - floor
        height_map[height_map < 0] = 0
        peak = np.max(height_map) if np.max(height_map) > 0 else 1

        res_image = (height_map / peak * 255).astype(np.uint8)
        res_image_colored = cv2.applyColorMap(res_image, cv2.COLORMAP_JET)
        
        output_dir = "depth_maps"
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        filename = os.path.basename(image_path)
        save_path = os.path.join(output_dir, f"depth_{filename}")
        cv2.imwrite(save_path, res_image_colored)
        
    except Exception as e:
        sys.stderr.write(f"Error generating depth map: {str(e)}\n")

def estimate_weight_with_gemini(image_path):
    """Estimate food weight using Gemini API and return the value"""
    try:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            sys.stderr.write("Skipping Gemini: GEMINI_API_KEY environment variable not set.\n")
            return None

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.5-flash')
        
        image = Image.open(image_path)
        
        # Modified prompt to get just the number for easier parsing
        prompt = (
            "Analyze this image of food. "
            "Estimate the approximate weight of the food visible in grams. "
            "Return ONLY the numeric value (e.g. 150). Do not include units or text."
        )
        
        response = model.generate_content([prompt, image])
        weight_text = response.text.strip()
        
        # Print to stderr for debugging
        sys.stderr.write(f"\n--- Gemini Weight Estimation ---\n{weight_text}\n-------------------------------\n")
        
        # Clean up the response to ensure it's a number
        return ''.join(filter(str.isdigit, weight_text))
        
    except Exception as e:
        sys.stderr.write(f"Gemini API Error: {str(e)}\n")
        return None

def predict_and_stream(image_path):
    try:
        # --- STEP 1: CLASSIFICATION (FAST) ---
        if model is None:
             raise RuntimeError("Classification model not loaded")

        img_array = preprocess_image(image_path)
        
        with tf.device('/CPU:0'):
            pred = model.predict(img_array, verbose=0)
        
        class_idx = int(np.argmax(pred))
        confidence = float(np.max(pred))
        
        # Prepare Classification Result
        classification_result = {}
        
        if confidence < 0.4:
            classification_result = {
                'type': 'classification',
                'success': False,
                'message': "Couldn't predict food"
            }
        else:
            label_str = CLASS_LABELS[class_idx]
            # Simple parse just for the name to send immediately
            food_name = label_str.split(':')[0].strip()
            
            # --- NEW: Retrieve Ingredients FROM LINKED FILE ---
            # Replaces the hardcoded lookup: FOOD_INGREDIENTS.get(...)
            # Logic stays the same: Get data, format as list of strings ["Name: Xg"]
            
            raw_recipe = DISH_RECIPES.get(food_name, {})
            if raw_recipe:
                # Convert the dictionary format {"Item": 250} back into 
                # the list string format ["Item: 250g"] your app expects
                ingredients_list = [f"{ing}: {qty}g" for ing, qty in raw_recipe.items()]
            else:
                ingredients_list = ["Ingredients info unavailable"]
            
            classification_result = {
                'type': 'classification',
                'success': True,
                'name': food_name,
                'ingredients': ingredients_list, # <--- POPULATED FROM NEW FILE
                'full_label': label_str,
                'confidence': f"{confidence * 100:.2f}%"
            }

        # PRINT CLASSIFICATION IMMEDIATELY & FLUSH
        print(json.dumps(classification_result))
        sys.stdout.flush() # <--- Critical: Sends data to Node.js immediately

        if not classification_result.get('success', False):
            return # Stop if classification failed

        # --- STEP 2: DEPTH & WEIGHT (SLOW) ---
        generate_depth_map(image_path)
        estimated_weight = estimate_weight_with_gemini(image_path)
        
        weight_value = estimated_weight if estimated_weight else 500.0

        # Prepare Weight Result
        weight_result = {
            'type': 'weight',
            'success': True,
            'weight': weight_value,
            'source': 'Gemini' if estimated_weight else 'Default'
        }

        # PRINT WEIGHT RESULT
        print(json.dumps(weight_result))
        sys.stdout.flush()

    except Exception as e:
        error_msg = {
            'type': 'error',
            'success': False,
            'error': str(e)
        }
        print(json.dumps(error_msg))
        sys.stdout.flush()

if __name__ == '__main__':
    try:
        if len(sys.argv) != 2:
            raise ValueError("Usage: python predict.py <image_path>")
            
        image_path = sys.argv[1]
        predict_and_stream(image_path)
        
    except Exception as e:
        print(json.dumps({
            'type': 'error',
            'success': False,
            'error': f"System error: {str(e)}"
        }))