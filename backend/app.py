from flask import Flask, render_template, request, redirect, url_for, session, flash
import mysql.connector
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from werkzeug.security import check_password_hash

app = Flask(__name__)
app.secret_key = "supersecretkey"  # Change cette clé pour plus de sécurité

# ⚙️ Configuration de Flask-Login
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

# ⚙️ Configuration de la connexion MySQL
db_config = {
    "host": "localhost",
    "user": "ustock",
    "password": "UStock",
    "database": "UStock"
}

# 📌 Classe utilisateur pour Flask-Login
class User(UserMixin):
    def __init__(self, id, username, email):
        self.id = id
        self.username = username
        self.email = email

# 📥 Récupérer un utilisateur via l'ID
@login_manager.user_loader
def load_user(user_id):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        cursor.close()
        conn.close()
        if user:
            return User(id=user["id"], username=user["username"], email=user["email"])
    except mysql.connector.Error as err:
        print(f"Erreur MySQL : {err}")
    return None

# 🌍 Route de connexion
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()
        cursor.close()
        conn.close()

        if user and check_password_hash(user["password_hash"], password):
            user_obj = User(id=user["id"], username=user["username"], email=user["email"])
            login_user(user_obj)
            flash("Connexion réussie !", "success")
            return redirect(url_for('index'))
        else:
            flash("Email ou mot de passe incorrect.", "danger")

    return render_template('login.html')

# 🔓 Route de déconnexion
@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash("Déconnexion réussie.", "success")
    return redirect(url_for('login'))

# 🌍 Page principale protégée (seulement si connecté)
@app.route('/')
@login_required
def index():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM products ORDER BY created_at DESC")
    products = cursor.fetchall()
    cursor.close()
    conn.close()

    return render_template('index.html', products=products, username=current_user.username)

# 🚀 Lancer l'application Flask
if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)
