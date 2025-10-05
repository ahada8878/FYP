# In recipe_gernate.py
from ultralytics import YOLO
import os
import sys
import json

class IngredientDetector:
    def __init__(self, model_path, confidence_threshold=0.25):
        self.model_path = model_path
        self.confidence_threshold = confidence_threshold
        self.model = None
        self.class_names = None
        self.load_model()

    def load_model(self):
        """Load the YOLOv8 model"""
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"Model file not found: {self.model_path}")
        self.model = YOLO(self.model_path)
        self.class_names = self.model.names

    def detect(self, image_path):
        """Detect ingredients and return their names, confidence, and bounding boxes."""
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image file not found: {image_path}")
        
        results = self.model(image_path, conf=self.confidence_threshold, verbose=False)
        
        if not results or len(results) == 0:
            return []
        
        result = results[0]
        boxes = result.boxes
        
        detected_items = []
        for box in boxes:
            class_id = int(box.cls[0])
            confidence = float(box.conf[0])
            ingredient_name = self.class_names[class_id].strip()
            # Get bounding box coordinates [x1, y1, x2, y2]
            coords = box.xyxy[0].tolist()
            
            detected_items.append({
                "name": ingredient_name,
                "confidence": confidence,
                "box": [round(c, 2) for c in coords] 
            })
            
        return detected_items

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No image path provided."}))
        sys.exit(1)
        
    model_path = "yolo_fruits_and_vegetables_v3.pt"
    image_path = sys.argv[1]
    
    try:
        detector = IngredientDetector(model_path)
        detections = detector.detect(image_path)
        # Also include original image dimensions for scaling in Flutter
        results = detector.model(image_path, conf=detector.confidence_threshold, verbose=False)
        orig_img = results[0].orig_img
        original_height, original_width = orig_img.shape[:2]
        
        response = {
            "detections": detections,
            "image_dimensions": {
                "width": original_width,
                "height": original_height
            }
        }
        print(json.dumps(response))
            
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()