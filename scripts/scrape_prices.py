import urllib.request
import re
import json
import os
import datetime

CATEGORIES = [
    {"name": "Арматура", "url": "https://100met.ru/catalog/armatura.html"},
    {"name": "Катанка", "url": "https://100met.ru/catalog/katanka.html"},
    {"name": "Труба", "url": "https://100met.ru/catalog/truba.html"},
    {"name": "Уголок", "url": "https://100met.ru/catalog/ugolok/"},
    {"name": "Швеллер", "url": "https://100met.ru/catalog/shveller.html"},
    {"name": "Полоса", "url": "https://100met.ru/catalog/polosa.html"},
    {"name": "Квадрат", "url": "https://100met.ru/catalog/kvadrat-stalnoy.html"},
    {"name": "Листовой прокат", "url": "https://100met.ru/catalog/listovoy-prokat.html"},
    {"name": "Сетка", "url": "https://100met.ru/catalog/setka.html"},
    {"name": "Балка двутавровая", "url": "https://100met.ru/catalog/balka-dvutavrovaya.html"},
    {"name": "Проволока вязальная", "url": "https://100met.ru/catalog/provoloka-vyazalnaya.html"},
    {"name": "Профнастил", "url": "https://100met.ru/catalog/profnastil.html"},
    {"name": "Винтовые сваи", "url": "https://100met.ru/catalog/vintovyie-svai.html"},
    {"name": "Отводы стальные", "url": "https://100met.ru/catalog/otvodyi-stalnyie.html"}
]

def scrape_all():
    materials = []
    seen_ids = set()

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
    }

    for cat in CATEGORIES:
        cat_name = cat["name"]
        url = cat["url"]
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=15) as resp:
                html = resp.read().decode("utf-8", errors="ignore")

            matches = re.findall(r"data-product='([^']+)'", html)
            cat_count = 0
            for json_str in matches:
                try:
                    product_data = json.loads(json_str)
                    pid = str(product_data.get("id", "")).strip()
                    if not pid or pid in seen_ids:
                        continue

                    title = product_data.get("title", "").strip()
                    if not title:
                        continue

                    prod_url = product_data.get("url", "").strip()
                    if prod_url and not prod_url.startswith("http"):
                        prod_url = f"https://100met.ru{prod_url}"

                    unit = product_data.get("unit", "пог. м")
                    disc_price = product_data.get("discountedPrice")
                    reg_price = product_data.get("price")

                    price_val = 0.0
                    if isinstance(disc_price, (int, float)) and disc_price > 0:
                        price_val = float(disc_price)
                    elif reg_price is not None:
                        try:
                            price_val = float(reg_price)
                        except ValueError:
                            price_val = 0.0

                    weight_val = 0.0
                    try:
                        weight_val = float(product_data.get("weight", 0) or 0)
                    except ValueError:
                        weight_val = 0.0

                    materials.append({
                        "id": pid,
                        "name": title,
                        "url": prod_url,
                        "unit": unit,
                        "price": price_val,
                        "category": cat_name,
                        "weight": weight_val
                    })
                    seen_ids.add(pid)
                    cat_count += 1
                except Exception:
                    pass
            print(f"[{cat_name}] Scraped {cat_count} items")
        except Exception as e:
            print(f"[{cat_name}] Error: {e}")

    result = {
        "updatedAt": datetime.datetime.utcnow().isoformat() + "Z",
        "count": len(materials),
        "materials": materials
    }

    # Ensure output directories exist
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    web_data_dir = os.path.join(base_dir, "web", "data")
    assets_data_dir = os.path.join(base_dir, "assets", "data")
    os.makedirs(web_data_dir, exist_ok=True)
    os.makedirs(assets_data_dir, exist_ok=True)

    web_file = os.path.join(web_data_dir, "prices.json")
    assets_file = os.path.join(assets_data_dir, "prices.json")

    with open(web_file, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    with open(assets_file, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"\nSUCCESS! Saved {len(materials)} materials to {web_file} and {assets_file}")

if __name__ == "__main__":
    scrape_all()
