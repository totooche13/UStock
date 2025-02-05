#!/bin/bash

# Vérifier si un code-barres est passé en argument
if [ -z "$1" ]; then
    echo "Usage: $0 <GTIN/EAN>"
    exit 1
fi

# Code-barres fourni en argument
GTIN="$1"

# API Open Food Facts
API_URL="https://world.openfoodfacts.org/api/v0/product/$GTIN.json"

# Dossier pour enregistrer les images
IMAGE_DIR="./photo_produit"
mkdir -p "$IMAGE_DIR"  # Créer le dossier s'il n'existe pas

# Récupération des données JSON
DATA=$(curl -s "$API_URL")

# Extraction des informations
PRODUCT_NAME=$(echo "$DATA" | jq -r '.product.product_name')
BRAND=$(echo "$DATA" | jq -r '.product.brands')
QUANTITY=$(echo "$DATA" | jq -r '.product.quantity')
IMAGE_URL=$(echo "$DATA" | jq -r '.product.image_front_url')

# Vérifier si les données sont disponibles
if [ "$PRODUCT_NAME" == "null" ]; then
    PRODUCT_NAME="Non trouvé"
fi

if [ "$BRAND" == "null" ]; then
    BRAND="Non spécifiée"
fi

if [ "$QUANTITY" == "null" ] || [ -z "$QUANTITY" ]; then
    QUANTITY="Non spécifié"
fi

if [ "$IMAGE_URL" == "null" ]; then
    IMAGE_URL="Aucune image disponible"
else
    # Télécharger l'image si une URL est disponible
    IMAGE_PATH="$IMAGE_DIR/$GTIN.jpg"
    curl -s "$IMAGE_URL" -o "$IMAGE_PATH"
    echo "📸 Image téléchargée : $IMAGE_PATH"
fi

# Affichage des résultats
echo "🔹 Code-barres : $GTIN"
echo "🔹 Nom du produit : $PRODUCT_NAME"
echo "🔹 Marque : $BRAND"
echo "🔹 Poids/Quantité : $QUANTITY"
echo "🔹 URL de la photo : $IMAGE_URL"
