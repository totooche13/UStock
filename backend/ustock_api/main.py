from fastapi import FastAPI
from ustock_api.routes import users, products, stocks

app = FastAPI(title="UStock API", version="1.0")

# 📌 Inclure les routes
app.include_router(stocks.router)
app.include_router(users.router)
app.include_router(products.router)

# 🌍 Tester l'API
@app.get("/")
def root():
    return {"message": "Bienvenue sur l'API UStock 🚀"}
