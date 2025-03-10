from fastapi import APIRouter, Depends, HTTPException, status   
from sqlalchemy.orm import Session
from auth import get_current_user
from database import get_db
from schemas import StockCreate, StockResponse
import models

router = APIRouter(prefix="/stocks", tags=["Stocks"])

# 🔹 Ajouter un produit à l'inventaire d'un utilisateur
@router.post("/", response_model=StockResponse)
def add_product_to_user(stock_data: StockCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    product = db.query(models.Product).filter(models.Product.id == stock_data.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé")

    # Vérifier si ce produit est déjà dans le stock de l'utilisateur
    existing_stock = db.query(models.Stock).filter(
        models.Stock.user_id == current_user.id,
        models.Stock.product_id == stock_data.product_id
    ).first()

    if existing_stock:
        existing_stock.quantity += stock_data.quantity  # Ajouter à la quantité existante
    else:
        new_stock = models.Stock(
            product_id=stock_data.product_id,
            user_id=current_user.id,
            quantity=stock_data.quantity,
            expiration_date=stock_data.expiration_date
        )
        db.add(new_stock)

    db.commit()
    return db.query(models.Stock).filter(models.Stock.user_id == current_user.id, models.Stock.product_id == stock_data.product_id).first()

# 🔹 Récupérer tous les produits d'un utilisateur
@router.get("/", response_model=list[StockResponse])
def get_user_stocks(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    stocks = db.query(models.Stock).filter(models.Stock.user_id == current_user.id).all()

    # Charger les détails des produits
    stocks_with_products = []
    for stock in stocks:
        product = db.query(models.Product).filter(models.Product.id == stock.product_id).first()
        if product:
            stock_data = StockResponse(
                id=stock.id,
                quantity=stock.quantity,
                expiration_date=stock.expiration_date,
                product=product  # On ajoute les détails du produit
            )
            stocks_with_products.append(stock_data)

    return stocks_with_products



# 🔹 Supprimer un produit du stock d'un utilisateur
@router.delete("/{stock_id}")
def remove_product_from_user(stock_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    stock = db.query(models.Stock).filter(models.Stock.id == stock_id, models.Stock.user_id == current_user.id).first()
    
    if not stock:
        raise HTTPException(status_code=404, detail="Stock non trouvé")

    db.delete(stock)
    db.commit()
    return {"message": "Produit retiré du stock"}