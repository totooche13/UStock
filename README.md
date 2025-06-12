# UStock – Gestion de Stock à Domicile

**UStock** est une application destinée aux particuliers pour gérer efficacement leurs stocks alimentaires à la maison. Grâce à un système de scan des produits, de suivi des dates de péremption et de génération de listes de courses, elle aide à réduire le gaspillage et à simplifier l'organisation des courses.

---

## Fonctionnalités

### Application fonctionnelle et complète

- Scan de produits via code-barres (haute compatibilité)
- Alertes et notifications de péremption
- Inventaire intégré avec suivi des stocks
- Création automatique de listes de courses

### Simplicité d’utilisation

- Interface utilisateur intuitive et rapide à prendre en main

### Fonctionnalités supplémentaires

- Statistiques sur les produits jetés et consommés
- Mode famille (plusieurs utilisateurs sur un même inventaire)
- Application disponible sur Android
- Intégration de l’IA pour recommandations et prédictions (en développement)

---

## Structure de la base de données

Le projet repose sur une base de données relationnelle. La structure SQL complète est disponible dans le fichier [`ustock_structure.sql`](./ustock_structure.sql).

Exemples de tables :

- `users` : stocke les informations d'authentification et de profil utilisateur, incluant les champs first_name, last_name, email, username, birth_date, gender, password_hash, et profile_image_url. La clé primaire id permet l'identification unique de chaque utilisateur.
- `products` : centralise les informations produits obtenues depuis Open Food Facts, avec les attributs barcode (clé unique), product_name, brand, content_size, nutriscore, et image_url. Cette table évite la duplication des données produits entre utilisateurs.
- `stocks` : établit la relation entre utilisateurs et produits avec quantity, expiration_date, et added_at. Chaque entrée correspond à un produit spécifique dans l'inventaire d'un utilisateur avec sa date de péremption.
- `product_consumption` : trace l'historique des consommations avec product_id, user_id, quantity, status (consumed/wasted), expiration_date, et consumption_date. Cette table permet les analyses statistiques de gaspillage.
- `families` : regroupement de comptes pour le mode famille

---

## Installation
Se rendre sur l'AppStore et installer **Ustock** 

---

## Contribuer
Les contributions sont les bienvenues ! N’hésitez pas à ouvrir une issue ou une pull request pour suggérer des améliorations ou corriger des bugs.

---

## Licence
Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus d’informations.
