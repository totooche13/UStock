from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta
from auth import authenticate_user, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES, get_current_user, pwd_context
from database import get_db
from schemas import UserCreate, UserResponse, UserLogin, TokenResponse
import models

router = APIRouter(prefix="/users", tags=["Utilisateurs"])

# 🔹 Route pour s'inscrire (création d'un utilisateur)
@router.post("/register", response_model=UserResponse)
def register_user(user_data: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(models.User).filter(models.User.username == user_data.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Nom d'utilisateur déjà pris.")

    hashed_password = pwd_context.hash(user_data.password)

    # Créer un nouvel utilisateur avec family_id=None s'il n'est pas fourni
    new_user = models.User(
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        email=user_data.email,
        username=user_data.username,
        birth_date=user_data.birth_date,
        gender=user_data.gender,
        password_hash=hashed_password,
        family_id=user_data.family_id if user_data.family_id is not None else None
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user

# 🔹 Route pour se connecter et obtenir un token JWT
@router.post("/login", response_model=TokenResponse)
def login_for_access_token(form_data: UserLogin, db: Session = Depends(get_db)):
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Nom d'utilisateur ou mot de passe invalide")

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(data={"sub": user.username, "id": user.id, "email": user.email}, expires_delta=access_token_expires)

    return {"access_token": access_token, "token_type": "bearer"}

# 🔹 Route pour récupérer les infos de l'utilisateur connecté
@router.get("/me", response_model=UserResponse)
def read_users_me(current_user: UserResponse = Depends(get_current_user)):
    return current_user
