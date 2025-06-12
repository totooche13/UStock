# UStock – Home Inventory Management

**UStock** is an app designed for individuals to efficiently manage their food inventory at home. With a product scanning system, expiration tracking, and automated shopping list generation, it helps reduce food waste and simplifies grocery organization.

---

## Features

### Complete and Functional Application

- Product scanning via barcode (high compatibility)
- Expiration alerts and notifications
- Integrated inventory with stock tracking
- Automatic shopping list creation

### Easy to Use

- Intuitive and user-friendly interface

### Additional Features

- Statistics on consumed and wasted products
- Family mode (multiple users sharing one inventory)
- App available on Android
- AI integration for smart recommendations and predictions (in development)

---

## Database Structure

The project relies on a relational database. The complete SQL structure is available in [`ustock_structure.sql`](./ustock_structure.sql).

Example tables:

- `users`: stores authentication and user profile information, including fields like first_name, last_name, email, username, birth_date, gender, password_hash, and profile_image_url. The primary key id uniquely identifies each user.
- `products`: centralizes product information retrieved from Open Food Facts, with attributes such as barcode (unique key), product_name, brand, content_size, nutriscore, and image_url. This table avoids duplicating product data across users.
- `stocks`: defines the relationship between users and products with fields like quantity, expiration_date, and added_at. Each entry corresponds to a specific product in a user's inventory along with its expiration date.
- `product_consumption`: logs consumption history with product_id, user_id, quantity, status (consumed/wasted), expiration_date, and consumption_date. This table supports statistical analysis of food waste.
- `families`: groups accounts for the family mode.

---

## Installation

Go to the AppStore and install **UStock**.

---

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request to suggest improvements or fix bugs.

---

## License

This project is licensed under the MIT License. See the LICENSE file for more information.
