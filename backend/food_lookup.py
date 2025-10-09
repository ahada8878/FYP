import sys
import json
import requests
import re 
import os # Need this if we ever use environment variables, but keep for robustness

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
    Higher score means better match. Score ranges from 0.0 to 1.1 (max 1.0 Jaccard + 0.1 bonus).
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
    
    # If filtered input is empty, return 0
    if not filtered_input_words:
        return 0.0
        
    # Calculate Intersection and Union
    common_words = filtered_input_words.intersection(product_words)
    union_words = filtered_input_words.union(product_words)
    
    # Jaccard Similarity: |Intersection| / |Union|
    if len(union_words) == 0:
        jaccard_score = 0.0
    else:
        jaccard_score = len(common_words) / len(union_words)
        
    # Add a small bonus for direct prefix matching
    prefix_bonus = 0.0
    if product_lower.startswith(input_lower):
        prefix_bonus = 0.1
        
    # Return the final score
    return jaccard_score + prefix_bonus


# -------- OpenFoodFacts API (search by name) --------
def search_openfoodfacts_by_name(name, limit=50):
    url = "https://world.openfoodfacts.org/cgi/search.pl"
    params = {
        "search_terms": name,
        "search_simple": 1,
        "action": "process",
        "json": 1,
        "page_size": limit  # fetch multiple products
    }
    # NOTE: No API Key needed for OpenFoodFacts
    response = requests.get(url, params=params, headers={'User-Agent': 'CravingsSearchApp - PythonScript - v1.0'})
    response.raise_for_status() # Raise exception for bad status codes (4xx or 5xx)
    return response.json().get("products", [])

# -------- Nutrients extraction --------
def extract_main_nutrients(nutriments):
    """Extracts and standardizes main nutrient values from OpenFoodFacts data."""
    if not nutriments:
        return {}
    return {
        # Using specific keys and fallback keys for common variations
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
    """Checks if a product is risky based on user conditions and restrictions, including calorie limit."""

    # Helper function to safely get float value
    def n(key):
        v = nutrients.get(key)
        try:
            # Handle possible null or non-numeric values
            return float(v) if v is not None and str(v).strip() != '' else None
        except (ValueError, TypeError):
            return None

    # --- 1. Calorie Limit Check ---
    # The Node.js side passes the key as 'calorie_limit_kcal_100g'
    calorie_limit = user_profile.get("calorie_limit_kcal_100g") 
    calories = n("calories_kcal_100g")
    
    if calorie_limit and calories and calories > calorie_limit:
        return True, f"Exceeds Calorie Limit ({calories:.0f} kcal/100g)"

    # --- 2. Health Condition Check (High Nutrients) ---
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

    # --- 3. Dietary Restriction Check (Allergens/Intolerance) ---
    # The Node.js side passes the key as 'restrictions', so we use that key.
    restrictions = user_profile.get("restrictions", {})
    
    # Required fields for preference checks
    labels_tags = product.get("labels_tags", [])
    ingredients_text = product.get("ingredients_text", "").lower()
    allergens_tags = product.get("allergens_tags", [])

    if restrictions.get("Lactose Free"):
        # If the product isn't explicitly labeled as lactose-free AND ingredients suggest milk/lactose
        if "en:lactose-free" not in labels_tags and any(
            t in ingredients_text for t in ["lactose", "milk", "cheese", "butter"]
        ):
            return True, "Contains Milk/Lactose (Non-Lactose Free)"

    if restrictions.get("Nut Free"):
        nut_allergens = ["en:nuts", "en:almonds", "en:hazelnut", "en:walnuts", "en:cashew"]
        # Check if any nut allergen tags are present
        if any(tag in allergens_tags for tag in nut_allergens):
            return True, "Contains Nut Allergens"
    
    if restrictions.get("Gluten Free"):
        # If the product isn't explicitly labeled as gluten-free AND ingredients suggest gluten
        if "en:gluten-free" not in labels_tags and any(
            g in ingredients_text for g in ["wheat", "barley", "rye", "malt"]
        ):
            return True, "Contains Gluten (Non-Gluten Free)"

    return False, "Safe"


# -------- Main Execution --------
def main():
    try:
        # DEBUG: Immediately show script is running
        print("=== PYTHON SCRIPT STARTED ===", file=sys.stderr)
        print(f"=== Python version: {sys.version} ===", file=sys.stderr)
        print(f"=== Command line args: {sys.argv} ===", file=sys.stderr)
        
        # Read input from file OR stdin
        if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
            # Read from file (new method)
            input_file = sys.argv[1]
            print(f"=== Reading from file: {input_file} ===", file=sys.stderr)
            with open(input_file, 'r') as f:
                data = json.load(f)
        else:
            # Read from stdin (old method)
            print("=== Reading from stdin ===", file=sys.stderr)
            raw_data = sys.stdin.read()
            print(f"=== Raw stdin data: {raw_data} ===", file=sys.stderr)
            if not raw_data:
                raise ValueError("No input data received from Node.js.")
            data = json.loads(raw_data)

        product_name = data.get("input_name")
        if not product_name:
            raise ValueError("Product name ('input_name') is missing from the input payload.")

        user_profile = data 
        print(f"=== Searching for: {product_name} ===", file=sys.stderr)
        print(f"=== User conditions: {list(user_profile.get('conditions', {}).keys())} ===", file=sys.stderr)
        
    except Exception as e:
        # Print error in JSON format so Node.js can catch and handle it
        error_result = {"error": f"Input processing error: {str(e)}"}
        print(f"=== ERROR: {str(e)} ===", file=sys.stderr)
        print(json.dumps(error_result))
        sys.exit(1)

    # Search for products (increased limit to fetch more candidates before filtering)
    try:
        print("=== Calling OpenFoodFacts API ===", file=sys.stderr)
        products = search_openfoodfacts_by_name(product_name, limit=50)
        print(f"=== Found {len(products)} raw products from API ===", file=sys.stderr)
    except requests.HTTPError as e:
        # Handle API errors specifically
        error_result = {"error": f"OpenFoodFacts API error: {e.response.status_code} - {e.response.reason}"}
        print(f"=== API ERROR: {e.response.status_code} ===", file=sys.stderr)
        print(json.dumps(error_result))
        return
    except requests.RequestException as e:
        # Handle connection errors
        error_result = {"error": f"Network error during OpenFoodFacts search: {str(e)}"}
        print(f"=== NETWORK ERROR: {str(e)} ===", file=sys.stderr)
        print(json.dumps(error_result))
        return

    if not products:
        # Return an empty list if no products are found
        result = {
            "user_profile": user_profile,
            "input_name": product_name,
            "count_filtered": 0,
            "products": [],
            "skipped_products_for_debugging": [{"reason": f"No products found for name {product_name}."}]
        }
        print("=== No products found from API ===", file=sys.stderr)
        print(json.dumps(result, indent=2))
        return

    scored_products = []
    skipped_products = [] 
    
    print("=== Processing products ===", file=sys.stderr)
    
    for i, product in enumerate(products):
        product_name_full = product.get("product_name")
        image_url = product.get("image_url")
        
        # --- Mandatory checks ---
        if not product_name_full or not image_url:
            skipped_products.append({"name": product_name_full or "N/A", "reason": "Missing Name or Image URL"})
            continue
        
        nutriments_raw = product.get("nutriments", {})
        if not nutriments_raw:
             # Skip products without nutrient data
             skipped_products.append({"name": product_name_full, "reason": "Missing Nutriments"})
             continue
             
        nutrients = extract_main_nutrients(nutriments_raw)
        
        # --- Risk Check and Exclusion ---
        is_risky, reason = is_product_risky(product, nutrients, user_profile)
        
        if is_risky:
            # Store risky products and the reason they were skipped
            skipped_products.append({"name": product_name_full, "reason": reason})
            continue 
        # --------------------------------------

        # --- Calculate Similarity Score (Enhanced) ---
        similarity_score = calculate_similarity_score(product_name, product_name_full)
        
        scored_products.append({
            "score": similarity_score, # Store the score for sorting
            "barcode": product.get("code"),
            "name": product_name_full,
            "brand": product.get("brands"),
            "image_url": image_url,
            "nutrients": nutrients,
            "safety_status": reason 
        })
        
    # --- Sort and Finalize ---
    scored_products.sort(key=lambda x: x['score'], reverse=True)
    
    # Final filtering and cleaning
    filtered_products = []
    for p in scored_products:
        # Only include products that have a non-zero similarity score
        if p['score'] > 0:
            del p['score']
            filtered_products.append(p)
        else:
            # Track products skipped due to poor similarity match
            skipped_products.append({"name": p['name'], "reason": "Similarity Score Too Low (<= 0)"})

    print(f"=== Final results: {len(filtered_products)} products after filtering ===", file=sys.stderr)
    
    output = {
        "user_profile": user_profile,
        "input_name": product_name,
        "count_filtered": len(filtered_products),
        "products": filtered_products,
        "skipped_products_for_debugging": skipped_products # Added for debugging
    }

    print(json.dumps(output, indent=2))
    print("=== PYTHON SCRIPT COMPLETED SUCCESSFULLY ===", file=sys.stderr)


if __name__ == "__main__":
    main()