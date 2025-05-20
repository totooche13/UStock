import requests
import logging
from decimal import Decimal

logger = logging.getLogger(__name__)

class PriceEstimator:
    @staticmethod
    async def estimate_price(product_name, brand=None, content_size=None, category=None):
        """
        Estime le prix d'un produit en utilisant l'API d'IA
        """
        try:
            # URL de l'API d'estimation (à ajuster selon votre configuration)
            api_url = "http://localhost:5050/api/estimate_price"
            
            # Préparer les données
            data = {
                "name": product_name,
                "brand": brand or "",
                "content_size": content_size or "",
                "category": category or ""
            }
            
            # Appeler l'API avec un timeout de 15 secondes
            response = requests.post(api_url, json=data, timeout=45)
            
            if response.status_code == 200:
                print(f"Réponse de l'API: {response.text}")
                result = response.json()
                price = result.get("price")
                if price is not None:
                    logger.info(f"Prix estimé pour {product_name}: {price}€")
                    return Decimal(str(price))
            
            logger.warning(f"Impossible d'estimer le prix pour {product_name}, utilisation du prix par défaut")
            print(f"Réponse de l'API: {response.text}")
            return Decimal("3.00")  # Prix par défaut
            
        except Exception as e:
            logger.error(f"Erreur lors de l'estimation du prix: {str(e)}")
            return Decimal("3.00")  # Prix par défaut en cas d'erreur