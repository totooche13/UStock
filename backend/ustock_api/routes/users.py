from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from datetime import timedelta, datetime
from ustock_api.auth import authenticate_user, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES, get_current_user, pwd_context
from ustock_api.database import get_db
from ustock_api.schemas import UserCreate, UserResponse, UserLogin, TokenResponse
import ustock_api.models as models
from ustock_api.models import User
import os
import uuid

router = APIRouter(prefix="/users", tags=["Utilisateurs"])

# 🔹 Route pour s'inscrire (création d'un utilisateur)
@router.post("/register", response_model=UserResponse)
def register_user(user_data: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(models.User).filter(models.User.username == user_data.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Nom d'utilisateur déjà pris.")

    hashed_password = pwd_context.hash(user_data.password)

    new_user = models.User(
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        email=user_data.email,
        username=user_data.username,
        gender=user_data.gender,
        password_hash=hashed_password,
        family_id=user_data.family_id if user_data.family_id is not None else None,
        created_at=datetime.now(),
        updated_at=datetime.now()
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

# 🔹 MODIFICATION : Route pour récupérer les infos avec format de date correct
@router.get("/me")
def read_users_me(current_user: models.User = Depends(get_current_user)):
    """
    Récupère les informations de l'utilisateur connecté avec format de date ISO8601
    """
    # 🔹 SOLUTION : Convertir manuellement la réponse avec le bon format de date
    user_data = {
        "id": current_user.id,
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "email": current_user.email,
        "username": current_user.username,
        "gender": current_user.gender,
        "family_id": current_user.family_id,
        "profile_image_url": current_user.profile_image_url,
        # 🔹 FORMATAGE CORRECT DE LA DATE EN ISO8601
        "created_at": current_user.created_at.isoformat() if current_user.created_at else None
    }
    
    print(f"📅 Date formatée pour iOS: {user_data['created_at']}")
    return user_data

# 🔹 Route pour supprimer le compte utilisateur
@router.delete("/me")
def delete_user_account(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Supprime complètement le compte utilisateur et toutes ses données associées
    """
    try:
        user_id = current_user.id
        
        # 1. Supprimer tous les stocks de l'utilisateur
        user_stocks = db.query(models.Stock).filter(models.Stock.user_id == user_id).all()
        for stock in user_stocks:
            db.delete(stock)
        
        # 2. Supprimer l'historique de consommation de l'utilisateur
        user_consumptions = db.query(models.ProductConsumption).filter(models.ProductConsumption.user_id == user_id).all()
        for consumption in user_consumptions:
            db.delete(consumption)
        
        # 3. Supprimer la photo de profil si elle existe
        if current_user.profile_image_url:
            try:
                # Extraire le nom du fichier de l'URL
                filename = current_user.profile_image_url.split("/")[-1]
                file_path = f"static/profile_images/{filename}"
                if os.path.exists(file_path):
                    os.remove(file_path)
                    print(f"✅ Photo de profil supprimée : {file_path}")
            except Exception as e:
                print(f"⚠️ Erreur lors de la suppression de la photo de profil : {e}")
        
        # 4. Supprimer l'utilisateur lui-même
        db.delete(current_user)
        
        # 5. Confirmer toutes les suppressions
        db.commit()
        
        print(f"✅ Compte utilisateur {user_id} ({current_user.username}) supprimé avec succès")
        
        return {
            "message": "Votre compte a été supprimé définitivement",
            "deleted_user_id": user_id,
            "deleted_stocks": len(user_stocks),
            "deleted_consumptions": len(user_consumptions)
        }
        
    except Exception as e:
        db.rollback()
        print(f"❌ Erreur lors de la suppression du compte : {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la suppression du compte"
        )

@router.post("/me/profile-image")
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Générer un nom de fichier unique
    filename = f"profile_{current_user.id}_{uuid.uuid4()}.jpg"
    file_location = f"static/profile_images/{filename}"
    
    # Créer le dossier s'il n'existe pas
    os.makedirs(os.path.dirname(file_location), exist_ok=True)
    
    # Enregistrer le fichier
    with open(file_location, "wb+") as file_object:
        file_object.write(await file.read())
    
    # Construire l'URL
    image_url = f"https://api.ustock.pro:8443/static/profile_images/{filename}"
    
    # Mettre à jour l'utilisateur en base de données
    current_user.profile_image_url = image_url
    db.commit()
    
    return {"filename": filename, "profile_image_url": image_url}