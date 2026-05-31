================================================================
KNOWLEDGE BASE — DOCUMENT 12
TOPIC: App Database Schema (Technical Reference)
================================================================

Database File  : alis_grandson.db  (SQLite, stored on-device)
Schema Version : 12  (current)
ORM / Driver   : sqflite (Flutter package)
Manager Class  : DatabaseHelper (lib/src/core/database/database_helper.dart)

This document describes every table in the app's local SQLite database —
what each column stores, its data type, and how tables relate to each other.
Useful for developers, the chatbot, and understanding what data the app captures.

================================================================
1. TABLE: categories
   Purpose: Product categories displayed in the app catalogue.
   Added   : Schema v11
================================================================

| # | Column | Type    | Constraints              | Description                          |
|---|--------|---------|--------------------------|--------------------------------------|
| 1 | id     | INTEGER | PRIMARY KEY AUTOINCREMENT| Auto-assigned category ID.           |
| 2 | name   | TEXT    | NOT NULL, UNIQUE         | Category label (e.g. "Engine Parts").|
| 3 | icon   | TEXT    | NOT NULL DEFAULT 'category' | Material icon name string used to render the category icon in the UI. |

Seeded categories (8 total):
  1  Engine Parts          — icon: settings
  2  Brake System          — icon: emergency_share
  3  Filters               — icon: filter_alt
  4  Electrical            — icon: bolt
  5  Suspension & Steering — icon: tune
  6  Body Parts            — icon: directions_car
  7  Transmission          — icon: swap_horiz
  8  Cooling System        — icon: ac_unit

Notes:
  - UNIQUE constraint on name prevents duplicate categories.
  - ConflictAlgorithm.ignore is used during seeding (safe to re-run).

================================================================
2. TABLE: users
   Purpose: Stores all registered customer accounts.
================================================================

| # | Column   | Type    | Constraints              | Description                          |
|---|----------|---------|--------------------------|--------------------------------------|
| 1 | username | TEXT    | PRIMARY KEY              | Unique login handle chosen at signup. Cannot be changed after registration. |
| 2 | name     | TEXT    | NOT NULL                 | Customer's full display name.        |
| 3 | email    | TEXT    | UNIQUE, NOT NULL         | Login credential and notification address. Must be unique across all accounts. |
| 4 | phone    | TEXT    | NOT NULL                 | Customer's mobile number (used on orders and delivery). |
| 5 | password | TEXT    | NOT NULL                 | Password stored locally on device only. |
| 6 | dob      | TEXT    | NOT NULL                 | Date of birth in ISO-8601 format (YYYY-MM-DD). |

Notes:
  - username is the primary key (text, not integer).
  - email has a UNIQUE constraint — one account per email address.
  - phone column was added in schema migration v5.

================================================================
3. TABLE: admins
   Purpose: Stores admin login credentials.
================================================================

| # | Column   | Type    | Constraints              | Description                          |
|---|----------|---------|--------------------------|--------------------------------------|
| 1 | id       | INTEGER | PRIMARY KEY AUTOINCREMENT| Auto-assigned row ID.                |
| 2 | email    | TEXT    | NOT NULL                 | Admin login ID (default: "admin").   |
| 3 | password | TEXT    | NOT NULL                 | Admin password (default: "admin123").|

Notes:
  - Seeded with one default admin row on first install.
  - Change the default credentials after first login for security.

================================================================
4. TABLE: spare_part_products
   Purpose: The product catalogue — every item the store sells.
================================================================

| #  | Column      | Type    | Constraints                      | Description                          |
|----|-------------|---------|----------------------------------|--------------------------------------|
| 1  | id          | INTEGER | PRIMARY KEY AUTOINCREMENT        | Unique product ID.                   |
| 2  | name        | TEXT    | NOT NULL                         | Product name (e.g. "Timing Belt Kit"). |
| 3  | description | TEXT    |                                  | Long-form product description. Can be NULL. |
| 4  | image       | BLOB    |                                  | Raw image bytes (Uint8List). Stored directly in DB. Loaded separately via getProductImage(id) for performance. |
| 5  | type        | TEXT    |                                  | Part category label (e.g. "Engine", "Brakes", "Filter"). |
| 6  | brand       | TEXT    |                                  | Manufacturer / brand name (e.g. "Toyota", "Bosch", "NGK"). |
| 7  | model       | TEXT    |                                  | Compatible vehicle model or years (e.g. "Camry 2.4L", "All Models"). |
| 8  | vehicle_type| TEXT    |                                  | Vehicle body type (e.g. "Sedan", "SUV", "Pickup Truck"). Added v12. |
| 9  | price       | REAL    | NOT NULL                         | Selling price in Omani Rials (OMR).  |
| 10 | available   | INTEGER | NOT NULL                         | Total units in stock across all warehouses. 0 = Out of Stock. |
| 11 | category_id | INTEGER | REFERENCES categories(id)        | FK to the categories table. Added v11. |

Stock thresholds used in the app:
  available = 0           → Out of Stock  (red badge)
  0 < available < 10      → Low Stock     (yellow badge)
  available ≥ 10          → In Stock      (green badge)

Vehicle type values (used as filter in app):
  "Sedan" | "SUV" | "Pickup Truck" | "Van" | "Hatchback" | "Universal"

Notes:
  - image BLOB is excluded from list queries for performance; fetched individually.
  - available is recomputed by recomputeProductAvailable() from warehouse_stock sums.
  - Stock is decremented atomically inside a DB transaction when an order is placed.
  - 54 products seeded across 8 categories. 5 additional products with images from product_data.dart.

================================================================
5. TABLE: warehouses
   Purpose: Physical warehouse / branch locations.
   Added   : Schema v11
================================================================

| # | Column    | Type    | Constraints              | Description                          |
|---|-----------|---------|--------------------------|--------------------------------------|
| 1 | id        | INTEGER | PRIMARY KEY AUTOINCREMENT| Unique warehouse ID.                 |
| 2 | name      | TEXT    | NOT NULL                 | Warehouse display name (e.g. "Muscat Main Warehouse"). |
| 3 | address   | TEXT    | NOT NULL                 | Street / area address.               |
| 4 | city      | TEXT    | NOT NULL                 | City name (e.g. "Muscat", "Salalah").|
| 5 | phone     | TEXT    |                          | Branch contact number. Nullable.     |
| 6 | is_active | INTEGER | NOT NULL DEFAULT 1       | 1 = active branch, 0 = inactive. Only active warehouses appear in the customer UI. |

Seeded warehouses (2 in app DB — full 7-branch network described in Document 02):
  1  Muscat Main Warehouse — Industrial Area, Way 3014, Muscat — +968 2446 0000
  2  Salalah Branch        — Salalah Industrial Estate, Salalah — +968 2329 0000

Notes:
  - Customers can filter product listings by selecting a warehouse from the header dropdown.
  - Selected warehouse id is persisted in SharedPreferences ('selected_warehouse_id').

================================================================
6. TABLE: warehouse_stock
   Purpose: Maps products to warehouses with per-location quantities.
   Added   : Schema v11
================================================================

| # | Column       | Type    | Constraints                           | Description                          |
|---|--------------|---------|---------------------------------------|--------------------------------------|
| 1 | id           | INTEGER | PRIMARY KEY AUTOINCREMENT             | Unique row ID.                       |
| 2 | warehouse_id | INTEGER | NOT NULL, FK → warehouses(id)         | Which warehouse holds this stock.    |
| 3 | product_id   | INTEGER | NOT NULL, FK → spare_part_products(id)| Which product.                       |
| 4 | quantity     | INTEGER | NOT NULL DEFAULT 0                    | Units at this specific warehouse.    |
|   |              |         | UNIQUE(warehouse_id, product_id)      | One row per product per warehouse.   |

Notes:
  - spare_part_products.available = SUM of all warehouse_stock.quantity for that product.
  - When admin edits stock via setWarehouseStock(), recomputeProductAvailable() is called automatically.
  - When a warehouse filter is active in the customer app, available shown = that warehouse's quantity only.

================================================================
7. TABLE: cart
   Purpose: Holds items a customer has added to their cart but not yet ordered.
================================================================

| # | Column        | Type    | Constraints                           | Description                          |
|---|---------------|---------|---------------------------------------|--------------------------------------|
| 1 | id            | INTEGER | PRIMARY KEY AUTOINCREMENT             | Unique cart row ID.                  |
| 2 | user_username | TEXT    | NOT NULL, FK → users(username)        | Which customer owns this cart item.  |
| 3 | product_id    | INTEGER | NOT NULL, FK → spare_part_products(id)| Which product was added.             |
| 4 | quantity      | INTEGER | NOT NULL                              | How many units the customer wants.   |

Notes:
  - If a customer adds the same product twice, quantity is merged (not duplicated).
  - The entire cart is deleted atomically when placeOrder() succeeds.
  - Quantity is capped by available stock in the UI (cannot exceed stock).
  - Added in schema migration v6.

================================================================
8. TABLE: orders
   Purpose: Confirmed purchase orders placed by customers.
================================================================

| #  | Column               | Type    | Constraints                    | Description                          |
|----|----------------------|---------|--------------------------------|--------------------------------------|
| 1  | id                   | INTEGER | PRIMARY KEY AUTOINCREMENT      | Unique order ID (shown as #00001 format). |
| 2  | user_username        | TEXT    | NOT NULL, FK → users(username) | Which customer placed this order.    |
| 3  | address              | TEXT    | NOT NULL                       | Delivery address entered at checkout.|
| 4  | phone                | TEXT    | NOT NULL                       | Contact phone for delivery.          |
| 5  | special_instructions | TEXT    |                                | Optional delivery notes. Added v8.   |
| 6  | payment_mode         | TEXT    | NOT NULL                       | "Cash on Delivery" or "Card".        |
| 7  | total_price          | REAL    | NOT NULL                       | Grand total in OMR at time of order. |
| 8  | status               | TEXT    | NOT NULL                       | Current order state (see values below). |
| 9  | order_date           | TEXT    | NOT NULL                       | ISO-8601 datetime string.            |
| 10 | completion_date      | TEXT    |                                | ISO-8601 datetime when Delivered or Cancelled. Added v9. |

Order status lifecycle:
  Pending    → Order received, awaiting admin action.
  Ready      → Order packed and ready for dispatch or pick-up.
  In Delivery → Out for delivery to the customer.
  Delivered  → Successfully delivered. completion_date is set.
  Cancelled  → Cancelled (with reason emailed). completion_date is set.

Notes:
  - Revenue analytics only counts rows where status = 'Delivered'.
  - Email notifications are sent to the customer on every status change.

================================================================
9. TABLE: order_items
   Purpose: Individual product lines inside each order (one row per product per order).
================================================================

| # | Column     | Type    | Constraints                           | Description                          |
|---|------------|---------|---------------------------------------|--------------------------------------|
| 1 | id         | INTEGER | PRIMARY KEY AUTOINCREMENT             | Unique row ID.                       |
| 2 | order_id   | INTEGER | NOT NULL, FK → orders(id)             | Which order this item belongs to.    |
| 3 | product_id | INTEGER | NOT NULL, FK → spare_part_products(id)| Which product was ordered.           |
| 4 | quantity   | INTEGER | NOT NULL                              | Number of units purchased.           |
| 5 | price      | REAL    | NOT NULL                              | Unit price at time of purchase (snapshot — unchanged if product price changes later). |

Notes:
  - price is captured at checkout so historical orders stay accurate.

================================================================
10. TABLE: faqs
    Purpose: Question shortcuts shown in the Support chatbot screen.
================================================================

| # | Column   | Type    | Constraints              | Description                          |
|---|----------|---------|--------------------------|--------------------------------------|
| 1 | id       | INTEGER | PRIMARY KEY AUTOINCREMENT| Unique FAQ ID.                       |
| 2 | question | TEXT    | NOT NULL                 | The FAQ question text.               |
| 3 | answer   | TEXT    | NOT NULL                 | Stored empty ("")  — answers are generated live by the AI chatbot. |

Default FAQ questions (8):
  - How do I place an order?
  - Where are your store locations?
  - What is your WhatsApp number for support?
  - What payment methods do you accept?
  - Is my payment information secure?
  - How long does delivery take?
  - What is your return policy?
  - How do I track my order?

Notes:
  - Admin can add, edit, delete FAQ questions from Manage FAQs screen.
  - "Restore Defaults" button re-seeds the 8 default questions.
  - Added in schema migration v10.

================================================================
11. TABLE: wishlist
    Purpose: Products a customer has saved / hearted for later.
    Added   : Schema v11
================================================================

| # | Column        | Type    | Constraints                           | Description                          |
|---|---------------|---------|---------------------------------------|--------------------------------------|
| 1 | id            | INTEGER | PRIMARY KEY AUTOINCREMENT             | Unique row ID.                       |
| 2 | user_username | TEXT    | NOT NULL, FK → users(username)        | Which customer saved this item.      |
| 3 | product_id    | INTEGER | NOT NULL, FK → spare_part_products(id)| The saved product.                   |
| 4 | added_at      | TEXT    | NOT NULL                              | ISO-8601 datetime when hearted.      |
|   |               |         | UNIQUE(user_username, product_id)     | A product can only be wishlisted once per user. |

Notes:
  - Accessible via bottom navigation bar → heart icon → WishlistPage.
  - Each product card shows a heart icon overlay; tapping toggles wishlist state.
  - ConflictAlgorithm.ignore is used on insert (tapping twice does not error).

================================================================
ENTITY-RELATIONSHIP SUMMARY
================================================================

  categories ──────────────────────── spare_part_products ─── warehouse_stock ─── warehouses
                  (category_id FK)          (product_id FK)        (warehouse_id FK)

  users ──────────┬──── cart ────────── spare_part_products
                  │       (product_id FK)
                  │
                  ├──── orders ───────── order_items ────── spare_part_products
                  │       (order_id FK)      (product_id FK)
                  │
                  └──── wishlist ──────── spare_part_products
                            (product_id FK)

  admins   — standalone, no foreign keys
  faqs     — standalone, no foreign keys

================================================================
SCHEMA VERSION HISTORY
================================================================

  v1–v4  : Original tables (users without phone, spare_part_products basic, no cart/orders).
  v5     : Added phone column to users.
  v6     : Added cart table.
  v7     : Added orders and order_items tables.
  v8     : Added special_instructions column to orders.
  v9     : Added completion_date column to orders.
  v10    : Added faqs table.
  v11    : Added categories, warehouses, warehouse_stock, wishlist tables.
           Added category_id FK column to spare_part_products.
           Seeded 8 categories and 2 warehouses.
  v12    : Added vehicle_type TEXT column to spare_part_products.  ← CURRENT

================================================================
END OF DOCUMENT 12
================================================================
