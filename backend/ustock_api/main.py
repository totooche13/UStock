from fastapi import FastAPI
from ustock_api.routes import users, products, stocks, consumption
from fastapi.staticfiles import StaticFiles

app = FastAPI(title="UStock API", version="1.0")

app.mount("/static", StaticFiles(directory="/root/UStock/backend/static"), name="static")

# 📌 Inclure les routes
app.include_router(stocks.router)
app.include_router(users.router)
app.include_router(products.router)
app.include_router(consumption.router)

# 🌍 Tester l'API
@app.get("/")
def root():
    return {"message": "Bienvenue sur l'API UStock 🚀"}
