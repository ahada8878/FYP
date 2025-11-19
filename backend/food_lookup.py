import sys
import json
import requests
import re 
import os
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Define risk thresholds (per 100g)
RISK_THRESHOLDS = {
    "salt_100g": 1.5,            # High risk for Hypertension
    "sugars_100g": 22.5,         # High risk for Diabetes
    "saturated_fat_100g": 5.0,   # High risk for High Cholesterol
}

# -------- Similarity Scoring Function (Enhanced) --------
def calculate_similarity_score(input_name, product_name):
    """
    Calculates an enhanced score based on Jaccard similarity and prefix matching.
    Higher score means better match. Score ranges from 0.0 to 1.1.
    """
    if not product_name:
        return 0.0
    
    # Tokenize and normalize names (remove non-alphanumeric, convert to lower)
    input_lower = input_name.lower()
    product_lower = product_name.lower()

    # Tokenization
    input_words = set(re.findall(r'\w+', input_lower))
    product_words = set(re.findall(r'\w+', product_lower))
    
    # Define generic stop words to ignore in scoring
    stop_words = {"the", "a", "an", "of", "in", "with", "product", "food", "brand", "pack", "item"}
    
    # Filter out stop words from input
    filtered_input_words = input_words - stop_words
    
    if not filtered_input_words:
        return 0.0
        
    # Calculate Intersection and Union
    common_words = filtered_input_words.intersection(product_words)
    union_words = filtered_input_words.union(product_words)
    
    # Jaccard Similarity
    if len(union_words) == 0:
        jaccard_score = 0.0
    else:
        jaccard_score = len(common_words) / len(union_words)
        
    # Add a small bonus for direct prefix matching
    prefix_bonus = 0.0
    if product_lower.startswith(input_lower):
        prefix_bonus = 0.1
        
    return jaccard_score + prefix_bonus


# -------- OpenFoodFacts API (search by name) --------
def search_openfoodfacts_by_name(name, limit=20): 
    url = "https://world.openfoodfacts.org/cgi/search.pl"
    
    # --- OPTIMIZATION: Request Specific Fields Only ---
    # This reduces the download size by ~95%, making it much faster.
    fields_to_fetch = "code,product_name,brands,image_url,nutriments,labels_tags,ingredients_text,allergens_tags"
    
    params = {
        "search_terms": name,
        "search_simple": 1,
        "action": "process",
        "json": 1,
        "page_size": limit,
        "fields": fields_to_fetch # <--- CRITICAL PERFORMANCE FIX
    }
    
    # --- RETRY STRATEGY ---
    retry_strategy = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["HEAD", "GET", "OPTIONS"]
    )
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session = requests.Session()
    session.mount("https://", adapter)
    session.mount("http://", adapter)

    try:
        response = session.get(
            url, 
            params=params, 
            headers={'User-Agent': 'CravingsSearchApp - PythonScript - v1.0'}, 
            timeout=20, # Lower timeout is fine now because payload is small
            verify=False 
        )
        response.raise_for_status()
        return response.json().get("products", [])
    except Exception as e:
        raise e

# -------- Nutrients extraction --------
def extract_main_nutrients(nutriments):
    if not nutriments:
        return {}
    return {
        "calories_kcal_100g": nutriments.get("energy-kcal_100g") or nutriments.get("energy-kcal"),
        "proteins_100g": nutriments.get("proteins_100g"),
        "fat_100g": nutriments.get("fat_100g"),
        "saturated_fat_100g": nutriments.get("saturated-fat_100g") or nutriments.get("saturated_fat_100g"),
        "carbohydrates_100g": nutriments.get("carbohydrates_100g"),
        "fiber_100g": nutriments.get("fiber_100g"),
        "sugars_100g": nutriments.get("sugars_100g"),
        "salt_100g": nutriments.get("salt_100g")
    }

# -------- Risk Analysis --------
def is_product_risky(product, nutrients, user_profile):
    def n(key):
        v = nutrients.get(key)
        try:
            return float(v) if v is not None and str(v).strip() != '' else None
        except (ValueError, TypeError):
            return None

    # 1. Calorie Limit Check
    calorie_limit = user_profile.get("calorie_limit_kcal_100g") 
    calories = n("calories_kcal_100g")
    
    if calorie_limit and calories and calories > calorie_limit:
        return True, f"Exceeds Calorie Limit ({calories:.0f} kcal/100g)"

    # 2. Health Condition Check
    salt = n("salt_100g")
    sugar = n("sugars_100g")
    sat_fat = n("saturated_fat_100g")

    conditions = user_profile.get("conditions", {})
    if conditions.get("Hypertension") and salt and salt > RISK_THRESHOLDS["salt_100g"]:
        return True, "High Salt for Hypertension"
    if conditions.get("Diabetes") and sugar and sugar > RISK_THRESHOLDS["sugars_100g"]:
        return True, "High Sugar for Diabetes"
    if conditions.get("High Cholesterol") and sat_fat and sat_fat > RISK_THRESHOLDS["saturated_fat_100g"]:
        return True, "High Saturated Fat for High Cholesterol"

    # 3. Dietary Restriction Check
    restrictions = user_profile.get("restrictions", {})
    labels_tags = product.get("labels_tags", [])
    ingredients_text = product.get("ingredients_text", "").lower()
    allergens_tags = product.get("allergens_tags", [])

    if restrictions.get("Lactose Free"):
        if "en:lactose-free" not in labels_tags and any(
            t in ingredients_text for t in ["lactose", "milk", "cheese", "butter"]
        ):
            return True, "Contains Milk/Lactose (Non-Lactose Free)"

    if restrictions.get("Nut Free"):
        nut_allergens = ["en:nuts", "en:almonds", "en:hazelnut", "en:walnuts", "en:cashew"]
        if any(tag in allergens_tags for tag in nut_allergens):
            return True, "Contains Nut Allergens"
    
    if restrictions.get("Gluten Free"):
        if "en:gluten-free" not in labels_tags and any(
            g in ingredients_text for g in ["wheat", "barley", "rye", "malt"]
        ):
            return True, "Contains Gluten (Non-Gluten Free)"

    return False, "Safe"


# -------- Main Execution --------
def main():
    try:
        print("=== PYTHON SCRIPT STARTED ===", file=sys.stderr)
        
        if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
            input_file = sys.argv[1]
            with open(input_file, 'r') as f:
                data = json.load(f)
        else:
            raw_data = sys.stdin.read()
            if not raw_data:
                raise ValueError("No input data received from Node.js.")
            data = json.loads(raw_data)

        product_name = data.get("input_name")
        if not product_name:
            raise ValueError("Product name ('input_name') is missing.")

        user_profile = data 
        print(f"=== Searching for: {product_name} ===", file=sys.stderr)
        
    except Exception as e:
        error_result = {"error": f"Input processing error: {str(e)}"}
        print(json.dumps(error_result))
        sys.exit(1)

    try:
        print("=== Calling OpenFoodFacts API ===", file=sys.stderr)
        # 20 is a good limit now that we are fetching small objects
        products = search_openfoodfacts_by_name(product_name, limit=20) 
        print(f"=== Found {len(products)} raw products from API ===", file=sys.stderr)
    except Exception as e:
        error_result = {"error": f"API/Network error: {str(e)}"}
        print(json.dumps(error_result))
        return

    if not products:
        result = {
            "user_profile": user_profile,
            "input_name": product_name,
            "count_filtered": 0,
            "products": [],
            "skipped_products_for_debugging": [{"reason": "No products found in API."}]
        }
        print(json.dumps(result, indent=2))
        return

    scored_products = []
    skipped_products = [] 
    
    print("=== Processing products ===", file=sys.stderr)
    
    for i, product in enumerate(products):
        product_name_full = product.get("product_name")
        image_url = product.get("image_url")
        
        if not product_name_full or not image_url:
            skipped_products.append({"name": product_name_full or "N/A", "reason": "Missing Name or Image URL"})
            continue
        
        nutriments_raw = product.get("nutriments", {})
        if not nutriments_raw:
             skipped_products.append({"name": product_name_full, "reason": "Missing Nutriments"})
             continue
             
        nutrients = extract_main_nutrients(nutriments_raw)
        is_risky, reason = is_product_risky(product, nutrients, user_profile)
        similarity_score = calculate_similarity_score(product_name, product_name_full)
        
        scored_products.append({
            "score": similarity_score,
            "barcode": product.get("code"),
            "name": product_name_full,
            "brand": product.get("brands"),
            "image_url": image_url,
            "nutrients": nutrients,
            "is_safe": not is_risky, 
            "safety_status": reason if is_risky else "Safe"
        })
        
    scored_products.sort(key=lambda x: (x['score'], x['is_safe']), reverse=True)
    filtered_products = [p for p in scored_products if p['score'] > 0]
    
    print(f"=== Final results: {len(filtered_products)} products ===", file=sys.stderr)
    
    output = {
        "user_profile": user_profile,
        "input_name": product_name,
        "count_filtered": len(filtered_products),
        "products": filtered_products,
        "skipped_products_for_debugging": skipped_products
    }

    print(json.dumps(output, indent=2))
    print("=== PYTHON SCRIPT COMPLETED SUCCESSFULLY ===", file=sys.stderr)

if __name__ == "__main__":
    main()