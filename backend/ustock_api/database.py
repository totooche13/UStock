from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os

# ⚙️ Configuration de la connexion
DATABASE_URL = "mysql+mysqlconnector://ustock:UStock@localhost/UStock"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 🏗️ Fonction pour récupérer une session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
