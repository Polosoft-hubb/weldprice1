import urllib.request
import re
import json
import time

CATEGORIES = [
    ("Арматура", "https://100met.ru/catalog/armatura.html"),
    ("Катанка", "https://100met.ru/catalog/katanka.html"),
    ("Труба", "https://100met.ru/catalog/truba.html"),
    ("Уголок", "https://100met.ru/catalog/ugolok/"),
    ("Швеллер", "https://100met.ru/catalog/shveller.html"),
    ("Полоса", "https://100met.ru/catalog/polosa.html"),
    ("Квадрат", "https://100met.ru/catalog/kvadrat-stalnoy.html"),
    ("Листовой прокат", "https://100met.ru/catalog/listovoy-prokat.html"),
    ("Сетка", "https://100met.ru/catalog/setka.html"),
    ("Балка двутавровая", "https://100met.ru/catalog/balka-dvutavrovaya.html"),
    ("Проволока вязальная", "https://100met.ru/catalog/provoloka-vyazalnaya.html"),
    ("Профнастил", "https://100met.ru/catalog/profnastil.html"),
    ("Винтовые сваи", "https://100met.ru/catalog/vintovyie-svai.html"),
    ("Отводы стальные", "https://100met.ru/catalog/otvodyi-stalnyie.html"),
]

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
}

def fetch_and_parse():
    all_materials = []
    seen_ids = set()

    for idx, (cat_name, url) in enumerate(CATEGORIES, 1):
        print(f"[{idx}/{len(CATEGORIES)}] Fetching {cat_name} from {url}...")
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=15) as response:
                html = response.read().decode('utf-8')
            
            # Find all data-product='...'
            # HTML format is: data-product='{"id":"96",...}'
            pattern = re.compile(r"data-product='([^']+)'")
            matches = pattern.findall(html)
            
            cat_count = 0
            for match in matches:
                try:
                    product_data = json.loads(match)
                    prod_id = str(product_data.get("id"))
                    
                    if prod_id in seen_ids:
                        continue
                        
                    title = product_data.get("title", "").strip()
                    prod_url = product_data.get("url", "").strip()
                    if prod_url and not prod_url.startswith("http"):
                        prod_url = f"https://100met.ru{prod_url}"
                        
                    unit = product_data.get("unit", "").strip()
                    
                    # Get price, prefer discountedPrice if valid and non-zero
                    price_val = 0.0
                    try:
                        disc_price = product_data.get("discountedPrice", 0)
                        reg_price = product_data.get("price", 0)
                        
                        if disc_price and float(disc_price) > 0:
                            price_val = float(disc_price)
                        elif reg_price:
                            price_val = float(reg_price)
                    except ValueError:
                        pass
                    
                    if title:
                        material = {
                            "id": prod_id,
                            "name": title,
                            "url": prod_url,
                            "unit": unit,
                            "price": price_val,
                            "category": cat_name
                        }
                        all_materials.append(material)
                        seen_ids.add(prod_id)
                        cat_count += 1
                except Exception as e:
                    print(f"Error parsing product item: {e}")
                    
            print(f"Found {cat_count} materials in {cat_name}.")
            time.sleep(1) # Be polite
        except Exception as e:
            print(f"Error fetching {cat_name}: {e}")

    # Output to JSON file
    output_file = "materials_db.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(all_materials, f, ensure_ascii=False, indent=2)
        
    print(f"\nSuccessfully scraped {len(all_materials)} materials.")
    print(f"Saved to {output_file}")

if __name__ == "__main__":
    fetch_and_parse()
