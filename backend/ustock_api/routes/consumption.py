from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from ustock_api.auth import get_current_user
from ustock_api.database import get_db
from ustock_api.schemas import ProductConsumptionCreate, ProductConsumptionResponse
from ustock_api import models
from datetime import datetime

router = APIRouter(prefix="/consumption", tags=["Consumption"])

@router.post("/", response_model=ProductConsumptionResponse)
def add_consumption(
    consumption_data: ProductConsumptionCreate, 
    db: Session = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    # Vérifier que le stock existe et appartient à l'utilisateur
    stock = db.query(models.Stock).filter(
        models.Stock.id == consumption_data.stock_id,
        models.Stock.user_id == current_user.id
    ).first()
    
    if not stock:
        raise HTTPException(status_code=404, detail="Stock non trouvé ou n'appartient pas à l'utilisateur")
    
    # Vérifier que la quantité est valide
    if consumption_data.quantity > stock.quantity:
        raise HTTPException(status_code=400, detail="Quantité demandée supérieure à la quantité en stock")
    
    # Stocker les informations importantes avant de modifier le stock
    product_id = stock.product_id
    expiration_date = stock.expiration_date
    
    # Créer l'entrée dans l'historique
    new_consumption = models.ProductConsumption(
        product_id=product_id,
        user_id=current_user.id,
        quantity=consumption_data.quantity,
        status=consumption_data.status,
        expiration_date=expiration_date,
        consumption_date=datetime.now()
    )
    
    db.add(new_consumption)
    db.flush()  # S'assurer que l'insertion est réalisée avant de potentiellement supprimer le stock
    
    # Mettre à jour la quantité en stock
    stock.quantity -= consumption_data.quantity
    
    # Si la quantité devient 0, supprimer l'entrée du stock
    if stock.quantity <= 0:
        db.delete(stock)
    
    db.commit()
    db.refresh(new_consumption)
    
    return new_consumption

@router.get("/", response_model=list[ProductConsumptionResponse])
def get_consumption_history(
    status: str = None,
    db: Session = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    query = db.query(models.ProductConsumption).filter(
        models.ProductConsumption.user_id == current_user.id
    )
    
    if status:
        query = query.filter(models.ProductConsumption.status == status)
    
    return query.order_by(models.ProductConsumption.consumption_date.desc()).all()

@router.get("/stats")
def get_consumption_stats(
    db: Session = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    # Statistiques globales
    consumed_count = db.query(func.sum(models.ProductConsumption.quantity)).filter(
        models.ProductConsumption.user_id == current_user.id,
        models.ProductConsumption.status == "consumed"
    ).scalar() or 0
    
    wasted_count = db.query(func.sum(models.ProductConsumption.quantity)).filter(
        models.ProductConsumption.user_id == current_user.id,
        models.ProductConsumption.status == "wasted"
    ).scalar() or 0
    
    total_count = consumed_count + wasted_count
    waste_rate = (wasted_count / total_count * 100) if total_count > 0 else 0
    
    # Statistiques mensuelles
    current_month = datetime.now().month
    current_year = datetime.now().year
    
    monthly_consumed = db.query(func.sum(models.ProductConsumption.quantity)).filter(
        models.ProductConsumption.user_id == current_user.id,
        models.ProductConsumption.status == "consumed",
        func.month(models.ProductConsumption.consumption_date) == current_month,
        func.year(models.ProductConsumption.consumption_date) == current_year
    ).scalar() or 0
    
    monthly_wasted = db.query(func.sum(models.ProductConsumption.quantity)).filter(
        models.ProductConsumption.user_id == current_user.id,
        models.ProductConsumption.status == "wasted",
        func.month(models.ProductConsumption.consumption_date) == current_month,
        func.year(models.ProductConsumption.consumption_date) == current_year
    ).scalar() or 0
    
    monthly_total = monthly_consumed + monthly_wasted
    monthly_waste_rate = (monthly_wasted / monthly_total * 100) if monthly_total > 0 else 0
    
    return {
        "total": {
            "consumed_count": int(consumed_count),
            "wasted_count": int(wasted_count),
            "total_count": int(total_count),
            "waste_rate": round(waste_rate, 2)
        },
        "current_month": {
            "consumed_count": int(monthly_consumed),
            "wasted_count": int(monthly_wasted),
            "total_count": int(monthly_total),
            "waste_rate": round(monthly_waste_rate, 2)
        }
    }