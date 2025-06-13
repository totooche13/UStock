from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime

class ProductCreate(BaseModel):
    barcode: str
    product_name: str
    brand: Optional[str]
    content_size: Optional[str]
    nutriscore: Optional[str]
    image_url: Optional[str]

class ProductResponse(BaseModel):
    id: int
    barcode: str
    product_name: str
    brand: Optional[str]
    content_size: Optional[str]
    nutriscore: Optional[str]
    image_url: Optional[str]

    class Config:
        from_attributes = True

class UserCreate(BaseModel):
    first_name: str
    last_name: str
    email: str
    username: str
    gender: str
    password: str
    family_id: Optional[int] = None

# 🔹 MODIFICATION : Ajout de created_at
class UserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: str
    username: str
    gender: str
    family_id: Optional[int]
    profile_image_url: Optional[str] = None
    created_at: Optional[datetime] = None  # 🔹 NOUVEAU

    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str

class StockCreate(BaseModel):
    product_id: int
    quantity: int = 1
    expiration_date: Optional[date] = None

# Modèle pour le stock incluant les détails du produit
class StockResponse(BaseModel):
    id: int
    quantity: int
    expiration_date: Optional[date]
    product: ProductResponse

    class Config:
        from_attributes = True

class ProductConsumptionCreate(BaseModel):
    stock_id: int
    quantity: int = 1
    status: str  # "consumed" ou "wasted"

class ProductConsumptionResponse(BaseModel):
    id: int
    product_id: int
    user_id: int
    stock_id: Optional[int]
    quantity: int
    status: str
    expiration_date: Optional[date]
    consumption_date: datetime
    product: ProductResponse

    class Config:
        from_attributes = True