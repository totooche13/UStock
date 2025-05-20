from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ustock_api import schemas, models
from ustock_api.database import get_db
import requests
import sys
import os

# Récupère le chemin du dossier parent
chemin_parent = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))

# Ajoute ce chemin à sys.path
sys.path.append(chemin_parent)

from openfoodfact import fetch_product_from_api, check_product_exists, insert_product_into_db

router = APIRouter(prefix="/products", tags=["Produits"])

# 🔍 Récupérer tous les produits
@router.get("/", response_model=list[schemas.ProductResponse])
def get_products(db: Session = Depends(get_db)):
    return db.query(models.Product).all()

# ➕ Ajouter un produit via son code-barres
@router.post("/")
def add_product_by_barcode(barcode: str, db: Session = Depends(get_db)):
    # Vérifier si le produit est déjà en base
    if check_product_exists(barcode):
        raise HTTPException(status_code=409, detail="Le produit existe déjà en base.")

    # Récupérer les infos depuis Open Food Facts
    product = fetch_product_from_api(barcode)
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé sur Open Food Facts.")

    # Ajouter le produit en base
    insert_product_into_db(product)

    return {"message": "Produit ajouté avec succès", "product": product}

# 🔍 Rechercher un produit par code-barres
@router.get("/{barcode}", response_model=schemas.ProductResponse)
def get_product(barcode: str, db: Session = Depends(get_db)):
    product = db.query(models.Product).filter(models.Product.barcode == barcode).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé")
    return product


# Dans ustock_api/routes/products.py
@router.get("/search/{query}")
def search_products(query: str, db: Session = Depends(get_db)):
    """Recherche de produits par nom via OpenFoodFacts"""
    url = f"https://world.openfoodfacts.org/cgi/search.pl?search_terms={query}&search_simple=1&action=process&json=1"
    
    try:
        response = requests.get(url)
        data = response.json()
        
        if "products" not in data or len(data["products"]) == 0:
            return {"results": []}
        
        # Formater les résultats
        results = []
        for product in data["products"][:10]:  # Limiter à 10 résultats
            result = {
                "product_name": product.get("product_name", ""),
                "brand": product.get("brands", ""),
                "image_url": product.get("image_url", ""),
                "barcode": product.get("code", ""),
                "nutriscore": product.get("nutriscore_grade", ""),
                "content_size": product.get("quantity", "")
            }
            results.append(result)
        
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la recherche: {str(e)}")
    
