# optimized_extract_product.py

import sys
import json
import asyncio
import aiohttp
import os
from typing import Dict, List, Any, Optional

from PIL import Image
from pyzbar.pyzbar import decode
import pytesseract

# --- CONFIGURATION ---
CONFIG = {
    "OFF_API_BASE_URL": "https://world.openfoodfacts.org",
    "REQUEST_TIMEOUT": 25, 
    "MAX_ALTERNATIVES_TO_RETURN": 15, # Increased to ensure UI is filled
    "FETCH_LIMIT_PER_CATEGORY": 40, 
    "MAX_CATEGORIES_TO_SEARCH": 2, 
}

# ----------------------------------------------------------------------
# ASYNCHRONOUS API CLIENT
# ----------------------------------------------------------------------

class AsyncOpenFoodFactsClient:
    def __init__(self, base_url: str, timeout: int):
        self._base_url = base_url
        self._timeout = aiohttp.ClientTimeout(total=timeout)
        self._session: Optional[aiohttp.ClientSession] = None
        # We need categories_tags to find alternatives
        self._fields = "code,product_name,brands,image_url,nutriments,ingredients_text,categories_tags"

    async def __aenter__(self):
        self._session = aiohttp.ClientSession(timeout=self._timeout)
        return self

    async def __aexit__(self, exc_type, exc, tb):
        if self._session:
            await self._session.close()

    async def _get(self, url: str, params: Dict) -> Optional[Dict]:
        if not self._session: raise RuntimeError("Session not started.")
        try:
            params['fields'] = self._fields
            headers = {'User-Agent': 'NutriwiseScanner/3.0 (Fix)'}
            
            async with self._session.get(url, params=params, headers=headers) as response:
                if response.status == 200:
                    return await response.json()
                return None
        except Exception:
            return None

    async def fetch_by_barcode(self, barcode: str) -> Optional[Dict]:
        url = f"{self._base_url}/api/v2/product/{barcode}"
        data = await self._get(url, {})
        return data.get("product") if data else None

    async def search_by_name(self, name: str, page_size: int = 20) -> Optional[List[Dict]]:
        url = f"{self._base_url}/cgi/search.pl"
        params = {
            "search_terms": name, "search_simple": 1, "action": "process",
            "json": 1, "page_size": page_size, "sort_by": "popularity"
        }
        data = await self._get(url, params)
        return data.get("products", []) if data else []

    async def fetch_by_category(self, category_tag: str, page_size: int) -> List[Dict]:
        url = f"{self._base_url}/cgi/search.pl"
        params = {
            "tagtype_0": "categories", 
            "tag_contains_0": "contains", 
            "tag_0": category_tag,
            "action": "process", 
            "json": 1, 
            "page_size": page_size,
            "sort_by": "popularity" 
        }
        data = await self._get(url, params)
        return data.get("products", []) if data else []
    
    async def fetch_alternatives_concurrently(self, categories: List[str], page_size: int) -> List[Dict]:
        tasks = [self.fetch_by_category(cat, page_size) for cat in categories]
        results_lists = await asyncio.gather(*tasks)
        return [p for sublist in results_lists for p in sublist]


# ----------------------------------------------------------------------
# HELPER FUNCTIONS
# ----------------------------------------------------------------------

def optimize_image(image_path: str) -> Optional[Image.Image]:
    try:
        if not os.path.exists(image_path): return None
        img = Image.open(image_path)
        img.thumbnail((1000, 1000)) 
        return img
    except:
        return None

def decode_barcode(img: Image.Image) -> Optional[str]:
    try:
        barcodes = decode(img)
        if barcodes: return barcodes[0].data.decode("utf-8")
        return None
    except:
        return None

def extract_text(img: Image.Image) -> str:
    try:
        return pytesseract.image_to_string(img, lang='eng').strip()
    except:
        return ""

def get_best_category_tags(categories_tags: List[str]) -> List[str]:
    if not categories_tags: return []
    IGNORED = ["en:plant-based", "en:foods", "en:beverages", "en:groceries", "en:non-alcoholic-beverages"]
    filtered = [c for c in categories_tags if c not in IGNORED and "plant" not in c]
    return filtered[-CONFIG['MAX_CATEGORIES_TO_SEARCH']:] if filtered else categories_tags[-1:]

def extract_main_nutrients(nutriments: Dict) -> Dict:
    if not nutriments: return {}
    def f(val):
        if val is None: return None
        try: return float(val)
        except: return None

    energy = f(nutriments.get("energy-kcal_100g")) or f(nutriments.get("energy-kcal"))
    if energy is None:
        kj = f(nutriments.get("energy-kj_100g"))
        if kj: energy = round(kj / 4.184)

    return {
        "energy_kcal": energy, 
        "fat_100g": f(nutriments.get("fat_100g")),
        "saturated_fat_100g": f(nutriments.get("saturated-fat_100g")),
        "carbohydrates_100g": f(nutriments.get("carbohydrates_100g")),
        "sugars_100g": f(nutriments.get("sugars_100g")),
        "salt_100g": f(nutriments.get("salt_100g")),
        "proteins_100g": f(nutriments.get("proteins_100g"))
    }

def analyze_risk(product: Dict, conditions: Dict, preferences: Dict) -> tuple[List[Dict], int]:
    nutrients = extract_main_nutrients(product.get("nutriments", {}))
    statuses = []
    failed_count = 0
    
    checks = [
        ("salt_100g", 1.5, "Hypertension", "High Salt"),
        ("sugars_100g", 22.5, "Diabetes", "High Sugar"),
        ("saturated_fat_100g", 5.0, "High Cholesterol", "High Sat. Fat"),
        ("energy_kcal", 450, "Obesity", "High Calorie"),
    ]

    for n_key, limit, cond_key, msg in checks:
        if conditions.get(cond_key):
            val = nutrients.get(n_key)
            is_safe = val is None or val <= limit
            if not is_safe: failed_count += 1
            statuses.append({"name": cond_key, "is_safe": is_safe, "status_detail": msg if not is_safe else "Safe levels"})

    ingredients = str(product.get("ingredients_text", "")).lower()
    pref_checks = [
        ("Lactose Free", ["milk", "lactose", "cheese", "cream", "butter", "whey"], "Contains Dairy"),
        ("Vegan", ["milk", "egg", "meat", "fish", "gelatin", "honey"], "Animal Content"),
        ("Gluten Free", ["wheat", "barley", "rye", "gluten", "malt"], "Contains Gluten"),
        ("Nut Free", ["nut", "almond", "cashew", "hazelnut", "pecan"], "Contains Nuts"),
    ]

    for pref_key, keywords, msg in pref_checks:
        if preferences.get(pref_key):
            is_safe = not any(k in ingredients for k in keywords)
            if not is_safe: failed_count += 1
            statuses.append({"name": pref_key, "is_safe": is_safe, "status_detail": msg if not is_safe else "Safe"})

    if not statuses:
        statuses.append({"name": "General", "is_safe": True, "status_detail": "No specific risks"})

    return statuses, failed_count

# ----------------------------------------------------------------------
# MAIN LOGIC
# ----------------------------------------------------------------------

async def main():
    if len(sys.argv) != 2:
        print(json.dumps({"error": "Missing input file argument"}))
        return

    try:
        with open(sys.argv[1], 'r') as f:
            input_data = json.load(f)
    except:
        print(json.dumps({"error": "Input Read Error"}))
        return

    image_path = input_data.get("image_path")
    conditions = input_data.get("conditions", {})
    preferences = input_data.get("restrictions", {})

    pil_image = optimize_image(image_path)
    if not pil_image:
        print(json.dumps({"success": False, "error": "Image file invalid"}))
        return

    async with AsyncOpenFoodFactsClient(CONFIG["OFF_API_BASE_URL"], CONFIG["REQUEST_TIMEOUT"]) as client:
        
        # 1. IDENTIFY PRODUCT
        product = None
        method = "none"
        
        barcode = decode_barcode(pil_image)
        if barcode:
            product = await client.fetch_by_barcode(barcode)
            method = "barcode"
        
        if not product:
            text = extract_text(pil_image)
            if len(text) > 2:
                search_query = text.split('\n')[0].strip()[:30]
                if search_query:
                    products = await client.search_by_name(search_query, page_size=1)
                    if products:
                        product = products[0]
                        method = "ocr"

        if not product:
            print(json.dumps({"success": False, "error": "Product not identified"}))
            return

        main_statuses, main_fails = analyze_risk(product, conditions, preferences)

        # 2. FIND ALTERNATIVES (Strategy: Category -> Fallback to Keyword)
        cat_tags = product.get("categories_tags", [])
        search_tags = get_best_category_tags(cat_tags)
        
        raw_candidates = []
        
        # Strategy A: Search by Category (Specific)
        if search_tags:
            raw_candidates = await client.fetch_alternatives_concurrently(
                search_tags, 
                CONFIG["FETCH_LIMIT_PER_CATEGORY"]
            )
        
        # Strategy B: Fallback to Keyword Search if categories returned nothing
        if not raw_candidates:
            # Use first 2 words of product name (e.g., "Lay's Classic" -> "Lay's Classic")
            product_name = product.get("product_name", "")
            keywords = " ".join(product_name.split()[:2]) 
            if keywords:
                 raw_candidates = await client.search_by_name(keywords, page_size=40)

        # 3. SCORE & FILTER
        valid_alts = []
        seen_codes = {product.get("code")}

        for alt in raw_candidates:
            code = alt.get("code")
            if not code or code in seen_codes: continue
            seen_codes.add(code)

            if not alt.get("product_name") or not alt.get("image_url"): continue

            alt_statuses, alt_fails = analyze_risk(alt, conditions, preferences)
            
            # --- LOGIC FIX: Allow Safer OR Equal items ---
            # 1. Is it Strictly Safer? (Fewer fails)
            is_better = alt_fails < main_fails
            # 2. Is it Equal? (Same fails, but maybe user wants variety)
            is_equal = alt_fails == main_fails
            
            no_conditions = (len(conditions) + len(preferences) == 0)

            if is_better or is_equal or no_conditions:
                valid_alts.append({
                    "score": alt_fails, # Lower score is better
                    "is_better": 1 if is_better else 0, # Priority flag
                    "has_nutrients": 1 if extract_main_nutrients(alt.get("nutriments")).get("energy_kcal") else 0,
                    "data": {
                        "name": alt.get("product_name"),
                        "brand": alt.get("brands", "Unknown Brand"),
                        "image_url": alt.get("image_url"),
                        "nutrients": extract_main_nutrients(alt.get("nutriments", {})),
                        "safety_statuses": alt_statuses,
                        "failure_count": alt_fails
                    }
                })

        # Sorting Strategy:
        # 1. Strictly Better Items first
        # 2. Then by Failure Score (Lowest first)
        # 3. Then by Data Completeness
        valid_alts.sort(key=lambda x: (-x['is_better'], x['score'], -x['has_nutrients']))
        
        final_alts = [x["data"] for x in valid_alts[:CONFIG["MAX_ALTERNATIVES_TO_RETURN"]]]

        output = {
            "success": True,
            "method": method,
            "product": {
                "name": product.get("product_name"),
                "brand": product.get("brands", "Unknown Brand"),
                "image_url": product.get("image_url"),
                "nutrients": extract_main_nutrients(product.get("nutriments", {})),
                "safety_statuses": main_statuses,
                "failure_count": main_fails
            },
            "alternatives": final_alts
        }
        
        print(json.dumps(output, indent=2))

if __name__ == "__main__":
    try:
        if sys.platform == 'win32':
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
        asyncio.run(main())
    except Exception as e:
        print(json.dumps({"success": False, "error": "Script Exception", "details": str(e)}))