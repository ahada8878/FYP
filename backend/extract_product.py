import sys
import json
import requests
from PIL import Image
from pyzbar.pyzbar import decode
import pytesseract

# --- IMPORTANT SETUP NOTE ---
# 1. You must install the required Python libraries:
#    pip install requests Pillow pyzbar pytesseract
# 2. You must install the Tesseract OCR engine on your system.
# ----------------------------


# ------------------------------------
# -------- DATABASE FETCH (REAL) -----
# ------------------------------------

def fetch_patient_data_from_db(user_id):
    """
    REAL IMPLEMENTATION: Fetches personalized health data from the 
    Node.js server using the authenticated user_id via an HTTP request.
    """
    # CRITICAL: This MUST match the host/port of your running Node.js server.
    BASE_URL = "http://localhost:5000" 
    fetch_url = f"{BASE_URL}/api/user-details/conditions/{user_id}"

    sys.stderr.write(f"--- INFO: Attempting to fetch user data from Node.js at: {fetch_url} ---\n")

    try:
        response = requests.get(fetch_url, timeout=5)
        response.raise_for_status() # Raises an HTTPError for 4xx or 5xx responses
        
        data = response.json()
        
        if not data or not data.get("success"):
             raise Exception(data.get("message") or "Node.js returned failure for user data.")
             
        sys.stderr.write(f"--- INFO: Successfully fetched user data. ---\n")

        # Returns the conditions and preferences object received from the database
        return {
            "conditions": data["conditions"],
            "preferences": data["preferences"],
        }
    
    except requests.exceptions.Timeout:
        sys.stderr.write("--- ERROR: Node.js user data endpoint timed out. Using DUMMY data. ---\n")
    except requests.exceptions.RequestException as e:
        sys.stderr.write(f"--- ERROR: Network or API failure fetching user data: {e}. Using DUMMY data. ---\n")
    except Exception as e:
        sys.stderr.write(f"--- ERROR: General error fetching user data: {e}. Using DUMMY data. ---\n")

    # FALLBACK: If API fetch fails, return mock data.
    return {
        "conditions": {
            "Hypertension": True, "Diabetes": True, "High Cholesterol": True,
            "Obesity": True, "Heart Disease": False, "Arthritis": False,
            "Asthma": False,
        },
        "preferences": {
            "Lactose Free": True, "Sugar Free": False, "Gluten Free": False,
            "Nut Free": False,
        },
    }

# ------------------------------------
# -------- CORE HELPER FUNCTIONS -----
# ------------------------------------

# -------- Barcode Detection --------
def decode_barcode(image_path):
    """Decodes a barcode from an image file using pyzbar."""
    try:
        image = Image.open(image_path)
        barcodes = decode(image)
        if not barcodes:
            return None
        return barcodes[0].data.decode("utf-8")
    except Exception as e:
        sys.stderr.write(f"Barcode decoding failed: {e}\n")
        return None

# -------- OCR --------
def extract_text(image_path):
    """Extracts text from an image file using pytesseract."""
    try:
        image = Image.open(image_path)
        text = pytesseract.image_to_string(image, lang='eng') 
        return text.strip()
    except Exception as e:
        sys.stderr.write(f"OCR extraction failed (Check Tesseract install): {e}\n")
        return ""

# -------- OpenFoodFacts API --------
def query_openfoodfacts_by_barcode(barcode):
    """Fetches product data from OpenFoodFacts using a barcode."""
    url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        data = response.json()
        if data.get("status") != 1:
            return None
        return data.get("product", {})
    except (requests.exceptions.RequestException, json.JSONDecodeError) as e:
        sys.stderr.write(f"OpenFoodFacts barcode query failed: {e}\n")
        return None


def search_openfoodfacts_by_name(name):
    """Searches for a single product on OpenFoodFacts by name."""
    url = "https://world.openfoodfacts.org/cgi/search.pl"
    params = {
        "search_terms": name,
        "search_simple": 1,
        "action": "process",
        "json": 1,
        "page_size": 1
    }
    try:
        response = requests.get(url, params=params, timeout=5)
        response.raise_for_status()
        products = response.json().get("products", [])
        return products[0] if products else None
    except (requests.exceptions.RequestException, json.JSONDecodeError) as e:
        sys.stderr.write(f"OpenFoodFacts name query failed: {e}\n")
        return None


def search_openfoodfacts_by_name_multiple(name, limit=10):
    """Searches for multiple products on OpenFoodFacts by name."""
    url = "https://world.openfoodfacts.org/cgi/search.pl"
    params = {
        "search_terms": name, "search_simple": 1, "action": "process",
        "json": 1, "page_size": limit
    }
    try:
        response = requests.get(url, params=params, timeout=5)
        response.raise_for_status()
        return response.json().get("products", [])
    except (requests.exceptions.RequestException, json.JSONDecodeError):
        return []


def get_products_by_category(category, limit=10):
    """Fetch products from OpenFoodFacts by category."""
    url = "https://world.openfoodfacts.org/cgi/search.pl"
    params = {
        "tagtype_0": "categories", "tag_contains_0": "contains", "tag_0": category,
        "action": "process", "json": 1, "page_size": limit
    }
    try:
        response = requests.get(url, params=params, timeout=5)
        response.raise_for_status()
        return response.json().get("products", [])
    except (requests.exceptions.RequestException, json.JSONDecodeError):
        return []


def get_best_category(product_categories_string):
    """Returns the most relevant categories for alternative searching."""
    if not product_categories_string:
        return []

    categories = [c.strip() for c in product_categories_string.split(",")]
    categories.reverse()

    EXCLUDED_CATEGORIES = {
        "groceries", "food", "beverages", "meals", "sauces", "dairies",
        "desserts", "snacks", "prepared meals", "sweet snacks"
    }

    filtered_categories = []
    for cat in categories:
        if cat.lower() not in EXCLUDED_CATEGORIES and not any(
            ex in cat.lower() for ex in EXCLUDED_CATEGORIES
        ):
            filtered_categories.append(cat)

    return filtered_categories if filtered_categories else categories[:3]


# -------- Nutrients extraction and Safety Check --------
def extract_main_nutrients(nutriments):
    """Return main nutrients (values per 100g when coming from OpenFoodFacts)."""
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


def get_product_safety_statuses(nutrients, product, conditions, preferences):
    """Checks product safety against health conditions & dietary preferences."""
    
    # Helper to safely convert nutrient string/None to float
    def n(key):
        v = nutrients.get(key)
        try:
            return float(v) if v is not None else None
        except (ValueError, TypeError):
            return None

    statuses = []
    sugar = n("sugars_100g")
    salt = n("salt_100g")
    sat = n("saturated_fat_100g")
    calories = n("calories_kcal_100g")

    failed_conditions = 0

    # --- Health Conditions Check (High Thresholds per 100g) ---
    for condition in conditions:
        is_safe = True
        
        if condition == "Hypertension" and salt and salt > 1.5:
            is_safe = False
        elif condition == "Diabetes" and sugar and sugar > 22.5:
            is_safe = False
        elif condition in ("High Cholesterol", "Heart Disease") and sat and sat > 5.0:
            is_safe = False
        elif condition == "Obesity" and ((calories and calories > 300) or (sugar and sugar > 22.5)):
            is_safe = False
        
        if not is_safe:
            failed_conditions += 1

        statuses.append({"type": "Condition", "name": condition, "is_safe": is_safe})

    # --- Preferences Check ---
    for preference, required in preferences.items():
        if not required:
            continue
        is_safe = True
        labels_tags = product.get("labels_tags", [])
        ingredients_text = product.get("ingredients_text", "").lower()

        if preference == "Lactose Free":
            if "en:lactose-free" not in labels_tags and any(
                i in ingredients_text for i in ["lactose", "milk", "whey", "butter"]
            ):
                is_safe = False
        elif preference == "Sugar Free":
            if (sugar is None or sugar > 0.5) and "en:sugar-free" not in labels_tags:
                is_safe = False
        elif preference == "Gluten Free":
            if "en:gluten-free" not in labels_tags and any(
                g in ingredients_text for g in ["wheat", "barley", "rye"]
            ):
                is_safe = False
        
        statuses.append({"type": "Preference", "name": preference, "is_safe": is_safe})

    return statuses, failed_conditions


# ------------------------------------
# -------- MAIN EXECUTION ----------
# ------------------------------------

def main():
    """
    Main function to run the product scan and personalized safety check.
    It expects the image file path and the user ID from the command line.
    """
    try:
        # 💡 CRITICAL CHECK: Ensure both arguments are present
        if len(sys.argv) < 3:
            print(json.dumps({"error": "Missing image path or user ID argument"}))
            return

        image_path = sys.argv[1]
        user_id = sys.argv[2] 

        # 1. Fetch Personalized Patient Data
        patient_data = fetch_patient_data_from_db(user_id) 

        # Filter the conditions/preferences to only include those marked as True
        TARGET_CONDITIONS = [k for k, v in patient_data["conditions"].items() if v]
        TARGET_PREFERENCES = {k: v for k, v in patient_data["preferences"].items() if v}

        MAX_ALTERNATIVES = 15
        MAX_SEARCH_RESULTS_PER_QUERY = 25

        # 2. Product Identification (Barcode -> OCR)
        product = None
        method = None
        text = None
        
        # --- Barcode Lookup ---
        barcode = decode_barcode(image_path)
        if barcode:
            product = query_openfoodfacts_by_barcode(barcode)
            method = "barcode"

        # --- OCR Fallback ---
        if not product:
            text = extract_text(image_path)
            if text:
                product = search_openfoodfacts_by_name(text)
                method = "ocr"
        
        # --- Product Not Found Error (Returns JSON error) ---
        if not product:
            print(json.dumps({
                "error": "Product not found in database via barcode or OCR.", 
                "extracted_text": text or "N/A"
            }))
            return

        # 3. Process Scanned Product
        prod_nutrients = extract_main_nutrients(product.get("nutriments", {}))
        main_safety_statuses, main_failure_count = get_product_safety_statuses(
            prod_nutrients, product, TARGET_CONDITIONS, TARGET_PREFERENCES
        )

        # 4. Find, Score, and Sort Alternatives
        relevant_categories = get_best_category(product.get("categories", ""))
        seen_barcodes = {product.get("code")} if product.get("code") else set()
        raw_alternatives_list = []

        # Search by Category (Prioritized Search)
        for category in relevant_categories:
            if len(raw_alternatives_list) >= MAX_SEARCH_RESULTS_PER_QUERY:
                break
            limit_for_cat = MAX_SEARCH_RESULTS_PER_QUERY - len(raw_alternatives_list)
            products_in_cat = get_products_by_category(category, limit=limit_for_cat)
            
            for p in products_in_cat:
                code = p.get("code")
                if not code or code in seen_barcodes:
                    continue
                seen_barcodes.add(code)
                raw_alternatives_list.append(p)
        
        # Score Alternatives
        scored_alternatives = []
        for p in raw_alternatives_list:
            nutrients = extract_main_nutrients(p.get("nutriments", {}))
            alt_safety_statuses, alt_failure_count = get_product_safety_statuses(
                nutrients, p, TARGET_CONDITIONS, TARGET_PREFERENCES
            )
            score = alt_failure_count
            is_better = score < main_failure_count
            scored_alternatives.append({
                "score": score,
                "is_better_than_scanned": is_better,
                "data": {
                    "name": p.get("product_name"), "barcode": p.get("code"),
                    "brand": p.get("brands"), "image_url": p.get("image_url"),
                    "nutrients": nutrients, "safety_statuses": alt_safety_statuses
                }
            })

        # Sort by score (best alternatives first) and limit results
        scored_alternatives.sort(key=lambda x: (x['score'], not x['is_better_than_scanned']))
        alternatives = [alt["data"] for alt in scored_alternatives][:MAX_ALTERNATIVES]

        # 5. Final Output (Returns JSON success object)
        output = {
            "success": True, "method": method, "user_id": user_id, 
            "extracted_text": text if method == "ocr" else None,
            "product": {
                "barcode": product.get("code"), "name": product.get("product_name"),
                "brand": product.get("brands"), "image_url": product.get("image_url"),
                "nutrients": prod_nutrients, "safety_statuses": main_safety_statuses,
                "failure_count": main_failure_count
            },
            "alternatives": alternatives
        }

        # Print the final JSON for Node.js to capture on stdout
        print(json.dumps(output, indent=2))
        return

    except Exception as e:
        # Print a structured error message for any unexpected crash
        sys.stderr.write(f"FATAL PYTHON CRASH: {e}\n")
        print(json.dumps({"error": "Python runtime exception occurred during processing", "details": str(e)}))


if __name__ == "__main__":
    main()