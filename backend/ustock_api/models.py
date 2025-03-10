from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey, Date, Enum
from sqlalchemy.orm import relationship
from database import Base

class Family(Base):  # Ajout de la table families
    __tablename__ = "families"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    created_at = Column(TIMESTAMP)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    username = Column(String(50), unique=True, nullable=False)
    birth_date = Column(Date, nullable=False)
    gender = Column(Enum("homme", "femme"), nullable=False)
    family_id = Column(Integer, ForeignKey("families.id", ondelete="SET NULL"), nullable=True)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(TIMESTAMP)
    updated_at = Column(TIMESTAMP)

    family = relationship("Family", backref="users")  # Relation SQLAlchemy


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    barcode = Column(String(50), unique=True, nullable=False)
    product_name = Column(String(255), nullable=False)
    brand = Column(String(100))
    content_size = Column(String(50))
    nutriscore = Column(Enum("a", "b", "c", "d", "e"))
    image_url = Column(String(255))
    created_at = Column(TIMESTAMP)


class Stock(Base):
    __tablename__ = "stocks"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    family_id = Column(Integer, ForeignKey("families.id", ondelete="SET NULL"), nullable=True)
    quantity = Column(Integer, nullable=False, default=1)
    expiration_date = Column(Date, nullable=True)
    added_at = Column(TIMESTAMP, nullable=False)

    product = relationship("Product")
    user = relationship("User")

