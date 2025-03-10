import requests
import mysql.connector
import sys

if len(sys.argv) < 2:
    print("Usage: python openfoodfact.py <GTIN/EAN>")
    sys.exit(1)

GTIN = sys.argv[1]



# ⚙️ Configuration de la connexion MySQL
db_config = {
    "host": "localhost",
    "user": "root",  # Change selon ton utilisateur MySQL
    "password": "root",
    "database": "UStock"
}


# 🔍 Fonction pour vérifier si un produit existe déjà
def check_product_exists(barcode):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM products WHERE barcode = %s", (barcode,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        return result is not None  # True si le produit existe
    except mysql.connector.Error as err:
        print(f"Erreur MySQL : {err}")
        return False

# 🌍 Fonction pour récupérer les données depuis Open Food Facts
def fetch_product_from_api(barcode):
    url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        if 'product' in data and data['product'].get('product_name'):
            return {
                "barcode": barcode,
                "product_name": data['product'].get('product_name', 'Inconnu'),
                "brand": data['product'].get('brands', 'Non spécifié'),
                "content_size": data['product'].get('quantity', 'Non spécifié'),
                "nutriscore": data['product'].get('nutriscore_grade', None),
                "image_url": data['product'].get('image_front_url', None)
            }
    return None

# 💾 Fonction pour insérer un produit dans la base MySQL
def insert_product_into_db(product):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        VALID_NUTRISCORE = {'a', 'b', 'c', 'd', 'e'}
        # Vérification que le Nutri-Score est valide, sinon mettre NULL
        nutriscore = product["nutriscore"].lower() if product["nutriscore"] in VALID_NUTRISCORE else None

        sql = """INSERT INTO products (barcode, product_name, brand, content_size, nutriscore, image_url, created_at)
                 VALUES (%s, %s, %s, %s, %s, %s, NOW())"""
        values = (product["barcode"], product["product_name"], product["brand"], product["content_size"], nutriscore, product["image_url"])

        cursor.execute(sql, values)
        conn.commit()

        print(f"✅ Produit ajouté : {product['product_name']} ({product['barcode']})")
        print(f"📊 Nutri-Score inséré : {nutriscore}")

        cursor.close()
        conn.close()
    except mysql.connector.Error as err:
        print(f"❌ Erreur MySQL : {err}")


# 🚀 Fonction principale : Vérifie et ajoute un produit
def add_product(barcode):
    if check_product_exists(barcode):
        print(f"🔎 Le produit {barcode} existe déjà dans la base.")
    else:
        product = fetch_product_from_api(barcode)
        if product:
            print(f"🔍 Produit trouvé : {product['product_name']} ({barcode}) ({product['nutriscore']})")
            insert_product_into_db(product)
        else:
            print(f"❌ Aucun produit trouvé pour {barcode}.")

# 🏁 Tester avec un code-barres (ex: Nutella)
if __name__ == "__main__":
    add_product(GTIN)
