from pydantic import BaseModel
from typing import Optional
from datetime import date

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
    birth_date: date
    gender: str
    password: str
    family_id: Optional[int] = None  # Rend le champ optionnel


class UserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: str
    username: str
    birth_date: date
    gender: str
    family_id: Optional[int]

    class Config:
        orm_mode = True

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
    product: ProductResponse  # On inclut ici les détails du produit

    class Config:
        from_attributes = True