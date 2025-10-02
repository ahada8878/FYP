from ultralytics import YOLO
import os
import requests
import sys
import json
import time

class RecipeFinder:
    def __init__(self, model_path, api_key, confidence_threshold=0.25):
        self.model_path = model_path
        self.api_key = api_key
        self.confidence_threshold = confidence_threshold
        self.model = None
        self.class_names = None
        self.spoonacular_base_url = "https://api.spoonacular.com"
        
    def load_model(self):
        """Load the YOLOv8 model"""
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"Model file not found: {self.model_path}")
        
        print("⏳ Loading ingredient detection model...")
        self.model = YOLO(self.model_path)
        self.class_names = self.model.names
        print(f"✅ Model loaded with {len(self.class_names)} ingredient classes")
        return True
    
    def detect_ingredients(self, image_path):
        """Detect ingredients in an image"""
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image file not found: {image_path}")
        
        print(f"🔍 Analyzing image for ingredients: {os.path.basename(image_path)}")
        
        # Perform detection
        results = self.model(image_path, conf=self.confidence_threshold, verbose=False)
        
        if not results or len(results) == 0:
            print("❌ No ingredients detected")
            return []
        
        result = results[0]
        boxes = result.boxes
        
        if len(boxes) == 0:
            print("❌ No ingredients detected above confidence threshold")
            return []
        
        # Extract unique ingredients
        detected_ingredients = set()
        ingredient_confidence = {}
        
        for box in boxes:
            class_id = int(box.cls[0].cpu().numpy())
            confidence = float(box.conf[0].cpu().numpy())
            ingredient_name = self.class_names[class_id].lower().strip()
            
            # Add to set of unique ingredients
            detected_ingredients.add(ingredient_name)
            
            # Track highest confidence for each ingredient
            if ingredient_name not in ingredient_confidence or confidence > ingredient_confidence[ingredient_name]:
                ingredient_confidence[ingredient_name] = confidence
        
        return list(detected_ingredients), ingredient_confidence
    
    def find_recipes_by_ingredients(self, ingredients, number=5, ranking=1):
        """Find recipes using Spoonacular API based on detected ingredients"""
        if not ingredients:
            print("❌ No ingredients provided for recipe search")
            return []
        
        print(f"🍳 Searching recipes for ingredients: {', '.join(ingredients)}")
        
        # Prepare API request
        url = f"{self.spoonacular_base_url}/recipes/findByIngredients"
        params = {
            'ingredients': ','.join(ingredients),
            'number': number,
            'ranking': ranking,
            'apiKey': self.api_key
        }
        
        try:
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            recipes = response.json()
            return recipes
            
        except requests.exceptions.RequestException as e:
            print(f"❌ API request failed: {e}")
            return []
        except json.JSONDecodeError as e:
            print(f"❌ Failed to parse API response: {e}")
            return []
    
    def get_recipe_nutrition(self, recipe_id):
        """Get nutritional information for a recipe"""
        url = f"{self.spoonacular_base_url}/recipes/{recipe_id}/nutritionWidget.json"
        params = {
            'apiKey': self.api_key
        }
        
        try:
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Failed to get nutrition data for recipe {recipe_id}: {e}")
            return None
    
    def extract_nutrition_values(self, nutrition_data):
        """Extract key nutritional values from nutrition data"""
        if not nutrition_data:
            return None
        
        nutrition = {
            'calories': 0,
            'protein': 0,
            'fat': 0,
            'carbs': 0
        }
        
        # Extract values from nutrition data
        for item in nutrition_data.get('bad', []):
            name = item.get('title', '').lower()
            amount = item.get('amount', '0')
            
            if 'calories' in name:
                nutrition['calories'] = self._parse_nutrition_value(amount)
            elif 'protein' in name:
                nutrition['protein'] = self._parse_nutrition_value(amount)
            elif 'fat' in name:
                nutrition['fat'] = self._parse_nutrition_value(amount)
            elif 'carb' in name:
                nutrition['carbs'] = self._parse_nutrition_value(amount)
        
        return nutrition
    
    def _parse_nutrition_value(self, value_str):
        """Parse nutrition value string to float"""
        try:
            # Remove units and convert to float
            if isinstance(value_str, str):
                # Remove common units and non-numeric characters
                value_str = value_str.replace('g', '').replace('kcal', '').strip()
                return float(value_str)
            elif isinstance(value_str, (int, float)):
                return float(value_str)
            else:
                return 0.0
        except (ValueError, TypeError):
            return 0.0
    
    def get_recipe_details(self, recipe_id):
        """Get detailed information for a specific recipe"""
        url = f"{self.spoonacular_base_url}/recipes/{recipe_id}/information"
        params = {
            'apiKey': self.api_key,
            'includeNutrition': False
        }
        
        try:
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ Failed to get recipe details: {e}")
            return None
    
    def print_detection_results(self, ingredients, confidence_scores):
        """Print formatted ingredient detection results"""
        print("\n" + "═" * 80)
        print("INGREDIENT DETECTION RESULTS")
        print("═" * 80)
        
        if not ingredients:
            print("❌ No ingredients detected")
            return
        
        print(f"📦 Detected {len(ingredients)} unique ingredients:")
        print("─" * 80)
        
        for i, ingredient in enumerate(ingredients, 1):
            conf_score = confidence_scores.get(ingredient, 0)
            print(f"{i:2d}. {ingredient.capitalize():<20} (confidence: {conf_score:.3f})")
        
        print("═" * 80)
    
    def print_recipe_results(self, recipes, ingredients):
        """Print formatted recipe results with nutrition information"""
        print("\n" + "═" * 80)
        print("RECIPE RECOMMENDATIONS WITH NUTRITION")
        print("═" * 80)
        print(f"🍽️  Found {len(recipes)} recipes using: {', '.join(ingredients)}")
        print("─" * 80)
        
        if not recipes:
            print("❌ No recipes found for these ingredients")
            return
        
        for i, recipe in enumerate(recipes, 1):
            # Get nutrition information
            nutrition_data = self.get_recipe_nutrition(recipe['id'])
            nutrition = self.extract_nutrition_values(nutrition_data)
            
            print(f"\n{i}. {recipe['title']}")
            print(f"   📝 ID: {recipe['id']}")
            print(f"   👍 Likes: {recipe.get('likes', 'N/A')}")
            print(f"   ⭐ Rating: {recipe.get('spoonacularScore', 'N/A')}")
            
            # Display nutrition information
            if nutrition:
                print(f"   📊 Nutrition per serving:")
                print(f"      🔥 Calories: {nutrition['calories']} kcal")
                print(f"      💪 Protein: {nutrition['protein']}g")
                print(f"      🥑 Fat: {nutrition['fat']}g")
                print(f"      🍞 Carbs: {nutrition['carbs']}g")
            else:
                print(f"   📊 Nutrition: Data not available")
            
            # Show used ingredients
            used_ingredients = [ing['name'] for ing in recipe.get('usedIngredients', [])]
            if used_ingredients:
                print(f"   ✅ Used: {', '.join(used_ingredients[:3])}{'...' if len(used_ingredients) > 3 else ''}")
            
            # Show missing ingredients
            missed_ingredients = [ing['name'] for ing in recipe.get('missedIngredients', [])]
            if missed_ingredients:
                print(f"   ❌ Missing: {', '.join(missed_ingredients[:2])}{'...' if len(missed_ingredients) > 2 else ''}")
        
        print("═" * 80)
    
    def get_detailed_recipe_info(self, recipe_id):
        """Get and display detailed recipe information with nutrition"""
        print(f"\n📋 Getting detailed information for recipe ID: {recipe_id}")
        details = self.get_recipe_details(recipe_id)
        
        if not details:
            print("❌ Could not retrieve recipe details")
            return
        
        # Get detailed nutrition information
        nutrition_data = self.get_recipe_nutrition(recipe_id)
        nutrition = self.extract_nutrition_values(nutrition_data)
        
        print("\n" + "═" * 80)
        print(f"RECIPE DETAILS: {details['title']}")
        print("═" * 80)
        print(f"⏰ Ready in: {details.get('readyInMinutes', 'N/A')} minutes")
        print(f"👥 Servings: {details.get('servings', 'N/A')}")
        print(f"⭐ Health Score: {details.get('healthScore', 'N/A')}")
        print(f"💰 Price per serving: ${details.get('pricePerServing', 0) / 100:.2f}")
        
        # Display detailed nutrition
        if nutrition:
            print(f"\n📊 NUTRITIONAL INFORMATION (per serving):")
            print(f"   🔥 Calories: {nutrition['calories']} kcal")
            print(f"   💪 Protein: {nutrition['protein']}g")
            print(f"   🥑 Fat: {nutrition['fat']}g")
            print(f"   🍞 Carbohydrates: {nutrition['carbs']}g")
        else:
            print(f"\n📊 Nutrition information not available")
        
        # Print summary
        if 'summary' in details:
            print(f"\n📝 Summary: {details['summary'][:200]}...")
        
        # Print ingredients
        if 'extendedIngredients' in details:
            print(f"\n🛒 Ingredients ({len(details['extendedIngredients'])}):")
            for ing in details['extendedIngredients'][:5]:  # Show first 5 ingredients
                print(f"   • {ing['original']}")
            if len(details['extendedIngredients']) > 5:
                print(f"   • ... and {len(details['extendedIngredients']) - 5} more")
        
        # Print instructions link
        if 'sourceUrl' in details:
            print(f"\n📖 Full instructions: {details['sourceUrl']}")
        
        print("═" * 80)

def main():
    # Configuration - arguments are passed from the command line
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No image path provided."}))
        sys.exit(1)
        
    model_path = "yolo_fruits_and_vegetables_v3.pt"
    image_path = sys.argv[1] # Get image path from server call
    api_key = "3ae6af7175864f2b96f71cf261f1e16a"  # Your API key

    # Initialize recipe finder without printing logs
    finder = RecipeFinder(model_path, api_key, confidence_threshold=0.25)
    
    try:
        # Load model silently
        if not os.path.exists(finder.model_path):
            raise FileNotFoundError(f"Model file not found: {finder.model_path}")
        finder.model = YOLO(finder.model_path)
        finder.class_names = finder.model.names
        
        # Detect ingredients silently
        ingredients, _ = finder.detect_ingredients(image_path)
        
        if not ingredients:
            print(json.dumps([])) # Return empty list if no ingredients
            return
        
        # Find recipes and return as JSON
        recipes = finder.find_recipes_by_ingredients(ingredients, number=5, ranking=1)
        
        # Print the raw JSON to be captured by the Node.js server
        print(json.dumps(recipes))
            
    except Exception as e:
        # Print errors as JSON so the app can handle them
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()