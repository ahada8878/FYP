# optimized_extract_product.py

import sys
import json
import asyncio
import aiohttp
import os # Added for file path checks
from typing import Dict, List, Any, Optional

from PIL import Image
from pyzbar.pyzbar import decode
import pytesseract

# --- IMPORTANT SETUP NOTE ---
# 1. You must install the required Python libraries:
#    pip install requests Pillow pyzbar pytesseract aiohttp
# 2. You must install the Tesseract OCR engine on your system.
# ----------------------------

# --- Centralized Configuration ---
CONFIG = {
    "NODE_API_BASE_URL": "https://nutriwisebckend-production.up.railway.app:8080",  # Deployment URL (No longer used, but kept for context)
    "OFF_API_BASE_URL": "https://world.openfoodfacts.org",
    "REQUEST_TIMEOUT": 90,  # Timeout in seconds for individual API calls
    "MAX_ALTERNATIVES": 15,
    "MAX_SEARCH_RESULTS_PER_CATEGORY": 10,
    "MAX_CATEGORIES_TO_SEARCH": 4,
}


# ----------------------------------------------------------------------
# ASYNCHRONOUS API CLIENT for OpenFoodFacts (for performance)
# ----------------------------------------------------------------------

class AsyncOpenFoodFactsClient:
    """An asynchronous client to interact with the OpenFoodFacts API concurrently."""

    def __init__(self, base_url: str, timeout: int):
        self._base_url = base_url
        self._timeout = aiohttp.ClientTimeout(total=timeout)
        self._session: Optional[aiohttp.ClientSession] = None

    async def __aenter__(self):
        self._session = aiohttp.ClientSession(timeout=self._timeout)
        return self

    async def __aexit__(self, exc_type, exc, tb):
        if self._session:
            await self._session.close()

    async def _get(self, url: str, params: Optional[Dict] = None) -> Optional[Dict]:
        """Helper for making GET requests."""
        if not self._session:
            raise RuntimeError("Session not started. Use 'async with' context.")
        try:
            # Set User-Agent for better API citizenship
            headers = {'User-Agent': 'NutriwiseScanner - PythonScript - v1.0'}
            async with self._session.get(url, params=params, headers=headers) as response:
                response.raise_for_status()
                return await response.json()
        except (aiohttp.ClientError, asyncio.TimeoutError, json.JSONDecodeError) as e:
            sys.stderr.write(f"OFF API Error for URL {url}: {e}\n")
            return None

    async def fetch_by_barcode(self, barcode: str) -> Optional[Dict]:
        url = f"{self._base_url}/api/v0/product/{barcode}.json"
        data = await self._get(url)
        return data.get("product") if data and data.get("status") == 1 else None

    async def search_by_name(self, name: str, page_size: int = 1) -> Optional[List[Dict]]:
        url = f"{self._base_url}/cgi/search.pl"
        params = {
            "search_terms": name, "search_simple": 1, "action": "process",
            "json": 1, "page_size": page_size
        }
        data = await self._get(url, params=params)
        return data.get("products", []) if data else None

    async def fetch_by_category(self, category: str, page_size: int) -> List[Dict]:
        url = f"{self._base_url}/cgi/search.pl"
        params = {
            "tagtype_0": "categories", "tag_contains_0": "contains", "tag_0": category,
            "action": "process", "json": 1, "page_size": page_size
        }
        data = await self._get(url, params=params)
        return data.get("products", []) if data else []
    
    async def fetch_alternatives_concurrently(self, categories: List[str], page_size: int) -> List[Dict]:
        """
        Core optimization: Fetches products for multiple categories in parallel.
        """
        tasks = [self.fetch_by_category(cat, page_size) for cat in categories]
        results_lists = await asyncio.gather(*tasks)
        
        # Flatten the list of lists into a single list of products
        all_products = [product for sublist in results_lists for product in sublist]
        return all_products


# ----------------------------------------------------------------------
# SYNCHRONOUS HELPER FUNCTIONS (No I/O)
# ----------------------------------------------------------------------

# ❗ DELETED: fetch_patient_data_from_db is removed as data is now passed via JSON file.

def decode_barcode(image_path: str) -> Optional[str]:
    try:
        if not os.path.exists(image_path):
             sys.stderr.write(f"Barcode decoding failed: Image file not found at {image_path}\n")
             return None
        barcodes = decode(Image.open(image_path))
        return barcodes[0].data.decode("utf-8") if barcodes else None
    except Exception as e:
        sys.stderr.write(f"Barcode decoding failed: {e}\n")
        return None

def extract_text(image_path: str) -> str:
    try:
        if not os.path.exists(image_path):
             sys.stderr.write(f"OCR failed: Image file not found at {image_path}\n")
             return ""
        # Adding a try-except block for Tesseract itself can be helpful
        return pytesseract.image_to_string(Image.open(image_path), lang='eng').strip()
    except Exception as e:
        sys.stderr.write(f"OCR extraction failed (Check Tesseract install): {e}\n")
        return ""

def get_best_category(categories_string: Optional[str]) -> List[str]:
    if not categories_string: return []
    categories = [c.strip() for c in categories_string.split(",")]
    categories.reverse()
    EXCLUDED = {"groceries", "food", "beverages", "meals", "sauces", "dairies"}
    filtered = [cat for cat in categories if cat.lower() not in EXCLUDED]
    return filtered[:CONFIG['MAX_CATEGORIES_TO_SEARCH']] if filtered else categories[:1]

def extract_main_nutrients(nutriments: Dict) -> Dict:
    """Extracts and cleans up key nutritional data."""
    if not nutriments: return {}
    return {
        "calories_kcal_100g": nutriments.get("energy-kcal_100g"),
        "fat_100g": nutriments.get("fat_100g"),
        "saturated_fat_100g": nutriments.get("saturated-fat_100g"),
        "carbohydrates_100g": nutriments.get("carbohydrates_100g"),
        "sugars_100g": nutriments.get("sugars_100g"),
        "salt_100g": nutriments.get("salt_100g"),
    }

def get_product_safety_statuses(product: Dict, conditions: Dict, preferences: Dict) -> tuple[List[Dict], int]:
    """
    Checks product against user's health conditions and dietary preferences.
    
    Args:
        product: The product dictionary from OpenFoodFacts.
        conditions: A dictionary of active health conditions (e.g., {"Hypertension": True, "Diabetes": True}).
        preferences: A dictionary of active dietary preferences (e.g., {"Lactose Free": True}).
        
    Returns:
        A tuple: (list of detailed status objects, total count of failed checks)
    """
    
    def n(key: str) -> Optional[float]:
        v = nutrients.get(key)
        try: return float(v) if v is not None else None
        except (ValueError, TypeError): return None

    nutrients = extract_main_nutrients(product.get("nutriments", {}))
    statuses, failed_count = [], 0
    ingredients = product.get("ingredients_text", "").lower()
    
    # --- Health Condition Checks (Thresholds per 100g) ---
    # Simplified thresholds for demonstration
    
    # Check 1: Hypertension (High Salt)
    if conditions.get("Hypertension"):
        salt = n("salt_100g")
        if salt is not None and salt > 1.5: 
            failed_count += 1
            statuses.append({"condition": "Hypertension", "status": "FAIL (High Salt)", "value": f"{salt}g"})
    
    # Check 2: Diabetes (High Sugar)
    if conditions.get("Diabetes"):
        sugar = n("sugars_100g")
        if sugar is not None and sugar > 22.5: 
            failed_count += 1
            statuses.append({"condition": "Diabetes", "status": "FAIL (High Sugar)", "value": f"{sugar}g"})
            
    # Check 3: High Cholesterol/Heart Disease (Saturated Fat)
    if conditions.get("High Cholesterol") or conditions.get("Heart Disease"):
        sat_fat = n("saturated_fat_100g")
        if sat_fat is not None and sat_fat > 5:
            failed_count += 1
            statuses.append({"condition": "Heart Risk", "status": "FAIL (High Saturated Fat)", "value": f"{sat_fat}g"})
            
    # Check 4: Obesity/Weight Management (High Calories)
    # Using a high generic limit as a filter example
    if conditions.get("Obesity"):
        calories = n("calories_kcal_100g")
        if calories is not None and calories > 500:
            failed_count += 1
            statuses.append({"condition": "Obesity", "status": "FAIL (High Calories)", "value": f"{calories}kcal"})

    # --- Dietary Preference Checks ---
    
    # Check A: Lactose Free
    if preferences.get("Lactose Free") and any(term in ingredients for term in ["lactose", "milk", "whey", "casein"]):
        failed_count += 1
        statuses.append({"preference": "Lactose Free", "status": "FAIL (Contains Milk/Lactose)", "value": "N/A"})
        
    # Check B: Vegan/Vegetarian (Simplified)
    if preferences.get("Vegan") and any(term in ingredients for term in ["meat", "chicken", "beef", "pork", "fish", "gelatin"]):
        failed_count += 1
        statuses.append({"preference": "Vegan", "status": "FAIL (Contains Animal Products)", "value": "N/A"})
        
    
    # If no specific failures, mark as OK
    if not statuses:
        statuses.append({"status": "PASS", "message": "Product appears compatible with profile."})

    return statuses, failed_count


# ----------------------------------------------------------------------
# MAIN EXECUTION LOGIC
# ----------------------------------------------------------------------

async def main():
    if len(sys.argv) != 2:
        print(json.dumps({"error": "Missing input JSON file path argument."}))
        return

    input_json_path = sys.argv[1]
    
    # 1. Read input data from the JSON file
    try:
        with open(input_json_path, 'r') as f:
            input_data = json.load(f)
            image_path = input_data.get("image_path")
            user_id = input_data.get("user_id")
            # The conditions and preferences dictionaries are now directly available
            target_conditions = input_data.get("conditions", {}) 
            target_preferences = input_data.get("restrictions", {}) # Renamed from preferences in old file
            
            if not image_path:
                raise ValueError("Missing 'image_path' in input JSON.")
    
    except Exception as e:
        sys.stderr.write(f"ERROR: Failed to read or parse input JSON file: {e}\n")
        print(json.dumps({"error": "Invalid input data received from server.", "details": str(e)}))
        return
    
    # Filter conditions/preferences to only include active ones (True)
    active_conditions = {k: v for k, v in target_conditions.items() if v}
    active_preferences = {k: v for k, v in target_preferences.items() if v}
    
    sys.stderr.write(f"--- INFO: Scan starting for User {user_id}. Conditions: {list(active_conditions.keys())}. ---\n")


    async with AsyncOpenFoodFactsClient(CONFIG["OFF_API_BASE_URL"], CONFIG["REQUEST_TIMEOUT"]) as client:
        # 2. Identify Product (Barcode -> OCR)
        product, method, text = None, None, None
        
        barcode = decode_barcode(image_path)
        if barcode:
            sys.stderr.write(f"--- INFO: Barcode detected: {barcode} ---\n")
            product = await client.fetch_by_barcode(barcode)
            method = "barcode"

        if not product:
            text = extract_text(image_path)
            sys.stderr.write(f"--- INFO: OCR text extracted: {text[:50]}... ---\n")
            if text:
                products = await client.search_by_name(text)
                product = products[0] if products else None
                method = "ocr"
        
        if not product:
            print(json.dumps({"success": False, "error": "Product not found on OpenFoodFacts.", "extracted_text": text or "N/A"}))
            return

        # 3. Process Scanned Product
        main_statuses, main_failure_count = get_product_safety_statuses(product, active_conditions, active_preferences)

        # 4. Find Alternatives Concurrently
        relevant_categories = get_best_category(product.get("categories"))
        raw_alternatives = []
        if relevant_categories:
            raw_alternatives = await client.fetch_alternatives_concurrently(
                relevant_categories, 
                CONFIG["MAX_SEARCH_RESULTS_PER_CATEGORY"]
            )
        sys.stderr.write(f"--- INFO: Found {len(raw_alternatives)} raw alternatives from {len(relevant_categories)} categories. ---\n")


        # 5. Score and Sort Alternatives
        seen_barcodes = {product.get("code")}
        scored_alternatives = []
        for p in raw_alternatives:
            code = p.get("code")
            # Skip if no code or if it's the same as the scanned product
            if not code or code in seen_barcodes: continue 
            seen_barcodes.add(code)
            
            # Score against user's health profile
            alt_statuses, alt_failure_count = get_product_safety_statuses(p, active_conditions, active_preferences)
            
            # Filter criteria: Alternatives must be *better* or *equal* to the main product,
            # but ideally, we only want those with a low/zero failure count.
            if alt_failure_count > main_failure_count and main_failure_count > 0:
                continue # Skip if alternative is strictly worse than the scanned product (and the scanned product failed)

            # Store only products that meet the criteria
            scored_alternatives.append({
                "score": alt_failure_count, # Lower score is better
                "data": {
                    "name": p.get("product_name"), "brand": p.get("brands"),
                    "image_url": p.get("image_url"), 
                    "nutrients": extract_main_nutrients(p.get("nutriments", {})),
                    # Include the status so the client knows why it's a good alternative
                    "safety_statuses": alt_statuses 
                }
            })

        # Sort: Primary key is the score (lowest failure count first), secondary can be name or another factor
        scored_alternatives.sort(key=lambda x: x['score'])
        alternatives = [alt["data"] for alt in scored_alternatives][:CONFIG['MAX_ALTERNATIVES']]

        sys.stderr.write(f"--- INFO: Final number of alternatives sent: {len(alternatives)} ---\n")

        # 6. Final JSON Output
        output = {
            "success": True, "method": method,
            "product": {
                "name": product.get("product_name"), "brand": product.get("brands"),
                "image_url": product.get("image_url"), "failure_count": main_failure_count,
                "nutrients": extract_main_nutrients(product.get("nutriments", {})),
                # Include the detailed statuses for the main product
                "safety_statuses": main_statuses 
            },
            "alternatives": alternatives
        }
        print(json.dumps(output, indent=2))

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as e:
        sys.stderr.write(f"FATAL PYTHON CRASH: {e}\n")
        print(json.dumps({"error": "A critical runtime error occurred.", "details": str(e)}))