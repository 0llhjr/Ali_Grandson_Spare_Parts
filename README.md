# Ali Grandson Spare Parts — Project Documentation

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Directory Structure](#3-directory-structure)
4. [Database Structure](#4-database-structure)
5. [File Responsibilities](#5-file-responsibilities)
6. [Navigation Flow](#6-navigation-flow)
7. [Email Notification System](#7-email-notification-system)
8. [Chatbot System](#8-chatbot-system)
9. [Use Cases](#9-use-cases)
10. [Configuration](#10-configuration)

---

## 1. Project Overview

**Ali Grandson Spare Parts** is a Flutter mobile application for a spare-parts store based in Muscat, Oman. It supports two types of users:

| User Type | Access |
|-----------|--------|
| **Customer** | Browse products by category or search, filter by warehouse / brand / vehicle type / price, add to cart, manage wishlist, place orders, track order status, use the AI support chatbot, manage their own profile |
| **Admin** | Manage products and inventory, manage warehouses and stock levels, view and update orders, manage customers, view revenue analytics, manage FAQ questions |

All data is stored locally on the device using **SQLite** via the `sqflite` package. Email notifications are sent via a **Google Apps Script** relay. The AI support chatbot connects to an external server that queries the local database for live data.

---

## 2. Technology Stack

| Concern | Package / Tool |
|---------|---------------|
| UI Framework | Flutter (Material 3) |
| Local Database | `sqflite` — SQLite on-device |
| Session Storage | `shared_preferences` — key-value store |
| Image Picking | `image_picker` |
| Image Processing | `image` |
| Charts | `fl_chart` |
| CSV Export | `csv` |
| File Sharing | `share_plus`, `open_filex` |
| HTTP / Email | `http` + Google Apps Script relay |
| AI Chatbot | `http` + external chatbot server (two-step flow) |
| Markdown Rendering | `flutter_markdown_plus` (chatbot responses) |
| Environment Vars | `flutter_dotenv` (`.env` file) |
| Date Formatting | `intl` |

---

## 3. Directory Structure

```
lib/
├── main.dart                              ← App entry point
└── src/
    ├── app.dart                           ← Root widget, theme, named routes
    ├── core/
    │   ├── database/
    │   │   └── database_helper.dart       ← ALL database operations (singleton, v12)
    │   ├── session/
    │   │   └── session_manager.dart       ← Login session read/write
    │   └── theme/
    │       └── app_colors.dart            ← Brand colour palette
    ├── features/
    │   ├── analytics/
    │   │   └── presentation/pages/
    │   │       └── revenue_analytics_page.dart
    │   ├── auth/
    │   │   └── presentation/pages/
    │   │       ├── login_admin_page.dart
    │   │       ├── login_user_page.dart
    │   │       └── signup_user_page.dart
    │   ├── cart/
    │   │   └── presentation/pages/
    │   │       └── cart_page.dart
    │   ├── catalog/
    │   │   ├── data/
    │   │   │   └── product_data.dart      ← Default seed products (5 with images)
    │   │   └── presentation/pages/
    │   │       ├── add_product_page.dart
    │   │       ├── categories_page.dart   ← Customer: all-categories grid
    │   │       ├── category_products_page.dart ← Customer: products in one category
    │   │       ├── edit_product_page.dart
    │   │       ├── manage_products_page.dart
    │   │       ├── search_filter_page.dart ← Customer: advanced search + all filters
    │   │       ├── user_view_product_page.dart
    │   │       └── view_product_page.dart
    │   ├── dashboard/
    │   │   ├── presentation/pages/
    │   │   │   ├── admin_dashboard_page.dart
    │   │   │   └── user_dashboard_page.dart
    │   │   └── presentation/widgets/
    │   │       └── banner_carousel.dart
    │   ├── home/
    │   │   └── presentation/pages/
    │   │       └── home_page.dart         ← Landing / splash screen
    │   ├── misc/
    │   │   └── presentation/pages/
    │   │       └── misc_page.dart         ← Customer: menu hub (Profile, Orders, Wishlist, Cart, Chat, Sign Out)
    │   ├── orders/
    │   │   └── presentation/pages/
    │   │       ├── admin_order_detail_page.dart
    │   │       ├── manage_orders_page.dart
    │   │       ├── order_detail_page.dart
    │   │       ├── order_page.dart        ← Checkout form with card validation
    │   │       └── user_orders_page.dart
    │   ├── profile/
    │   │   └── presentation/pages/
    │   │       ├── edit_user_page.dart
    │   │       ├── manage_users_page.dart
    │   │       ├── profile_page.dart
    │   │       └── view_user_page.dart
    │   ├── support/
    │   │   └── presentation/pages/
    │   │       ├── add_edit_faq_page.dart
    │   │       ├── faq_page.dart          ← AI chatbot UI with Markdown rendering
    │   │       └── manage_faqs_page.dart
    │   └── wishlist/
    │       └── presentation/pages/
    │           └── wishlist_page.dart     ← Customer: saved / hearted products
    └── shared/
        ├── services/
        │   ├── chatbot_service.dart       ← AI chatbot HTTP client (two-step flow + session)
        │   └── email_service.dart         ← HTTP POST to Google Apps Script
        └── utils/
            └── email_templates.dart       ← HTML email body builders
```

> **Asset folders** (inside `lib/assets/`):
> - `Imgs/` — app logo and app icon
> - `Banner_Imgs/` — three promotional carousel banners
> - `Product_Data/` — default product images (seeded on first run)
> - `email_templates/` — HTML email template assets

---

## 4. Database Structure

**File name:** `alis_grandson.db`  
**Schema version:** 12 (current — incremented on each migration)  
**Total tables:** 11

### Table: `categories`
Product categories shown in the app catalogue. *(Added v11)*

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `name` | TEXT | UNIQUE — e.g. "Engine Parts" |
| `icon` | TEXT | Material icon name string |

**8 seeded categories:** Engine Parts, Brake System, Filters, Electrical, Suspension & Steering, Body Parts, Transmission, Cooling System.

---

### Table: `users`
Registered customer accounts.

| Column | Type | Notes |
|--------|------|-------|
| `username` | TEXT | **Primary Key** — permanent, cannot be changed |
| `name` | TEXT | Full display name |
| `email` | TEXT | UNIQUE — used for login and notifications |
| `phone` | TEXT | Contact number |
| `password` | TEXT | Stored locally on device |
| `dob` | TEXT | Date of birth as `YYYY-MM-DD` |

---

### Table: `admins`
Admin login credentials.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `email` | TEXT | Admin ID (default: `admin`) |
| `password` | TEXT | Admin password (default: `admin123`) |

---

### Table: `spare_part_products`
The product catalogue.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `name` | TEXT | Product name |
| `description` | TEXT | Long-form description |
| `image` | BLOB | Raw image bytes — loaded separately for performance |
| `type` | TEXT | Part category label (e.g. "Engine", "Brakes") |
| `brand` | TEXT | Manufacturer brand |
| `model` | TEXT | Compatible vehicle model / years |
| `vehicle_type` | TEXT | Body type: Sedan, SUV, Pickup Truck, Van, Hatchback, Universal *(Added v12)* |
| `price` | REAL | Price in Omani Rials (OMR) |
| `available` | INTEGER | Total units in stock (0 = Out of Stock, <10 = Low Stock) |
| `category_id` | INTEGER | FK → `categories.id` *(Added v11)* |

**54 products seeded** across 8 categories. 5 additional products with images from `product_data.dart`.

---

### Table: `warehouses`
Physical branch / warehouse locations. *(Added v11)*

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `name` | TEXT | Display name (e.g. "Muscat Main Warehouse") |
| `address` | TEXT | Street address |
| `city` | TEXT | City name |
| `phone` | TEXT | Branch phone number |
| `is_active` | INTEGER | 1 = active, 0 = hidden from customer UI |

**2 seeded warehouses:** Muscat Main Warehouse, Salalah Branch.

---

### Table: `warehouse_stock`
Per-warehouse stock quantities for each product. *(Added v11)*

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `warehouse_id` | INTEGER | FK → `warehouses.id` |
| `product_id` | INTEGER | FK → `spare_part_products.id` |
| `quantity` | INTEGER | Units at this specific warehouse |

UNIQUE constraint on `(warehouse_id, product_id)`. `spare_part_products.available` is always the SUM of all warehouse quantities for that product.

---

### Table: `cart`
Shopping cart items (not yet ordered).

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `user_username` | TEXT | FK → `users.username` |
| `product_id` | INTEGER | FK → `spare_part_products.id` |
| `quantity` | INTEGER | Number of units |

Adding the same product twice merges quantity. Cart is cleared atomically when an order is placed.

---

### Table: `orders`
Confirmed customer purchases.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `user_username` | TEXT | FK → `users.username` |
| `address` | TEXT | Delivery address |
| `phone` | TEXT | Contact phone for delivery |
| `special_instructions` | TEXT | Optional delivery note |
| `payment_mode` | TEXT | `Cash on Delivery` or `Card` |
| `total_price` | REAL | Grand total in OMR at time of order |
| `status` | TEXT | `Pending` / `Ready` / `In Delivery` / `Delivered` / `Cancelled` |
| `order_date` | TEXT | ISO-8601 datetime |
| `completion_date` | TEXT | Set when Delivered or Cancelled |

---

### Table: `order_items`
Individual products within each order.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `order_id` | INTEGER | FK → `orders.id` |
| `product_id` | INTEGER | FK → `spare_part_products.id` |
| `quantity` | INTEGER | Units purchased |
| `price` | REAL | Unit price snapshot at time of purchase |

---

### Table: `faqs`
FAQ question shortcuts shown in the chatbot Support screen.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `question` | TEXT | The FAQ question text |
| `answer` | TEXT | Always empty — answers generated live by AI chatbot |

8 default questions seeded. Admin can add, edit, delete, and restore defaults.

---

### Table: `wishlist`
Products a customer has saved / hearted. *(Added v11)*

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `user_username` | TEXT | FK → `users.username` |
| `product_id` | INTEGER | FK → `spare_part_products.id` |
| `added_at` | TEXT | ISO-8601 datetime when hearted |

UNIQUE constraint on `(user_username, product_id)`.

---

### Entity–Relationship Summary

```
categories ──────────────────────── spare_part_products ─── warehouse_stock ─── warehouses
                  (category_id FK)        (product_id FK)       (warehouse_id FK)

users ──┬─< cart          (product_id FK → spare_part_products)
        ├─< orders ──< order_items (product_id FK → spare_part_products)
        └─< wishlist      (product_id FK → spare_part_products)

admins  — standalone, no FK
faqs    — standalone, no FK
```

---

### Schema Version History

| Version | Change |
|---------|--------|
| v1–v4 | Initial tables (users without phone, products, no cart/orders) |
| v5 | Added `phone` to `users` |
| v6 | Added `cart` table |
| v7 | Added `orders` and `order_items` tables |
| v8 | Added `special_instructions` to `orders` |
| v9 | Added `completion_date` to `orders` |
| v10 | Added `faqs` table |
| v11 | Added `categories`, `warehouses`, `warehouse_stock`, `wishlist` tables; added `category_id` to products |
| **v12** | Added `vehicle_type` to `spare_part_products` ← **current** |

---

## 5. File Responsibilities

### Core

| File | Responsibility |
|------|----------------|
| `main.dart` | Loads `.env`, seeds the database, checks login session, starts the app |
| `app.dart` | Global theme, named routes for all 12 customer + admin screens |
| `database_helper.dart` | Singleton providing all CRUD for all 11 database tables (v12) |
| `session_manager.dart` | Reads/writes user and admin login state to `SharedPreferences` |
| `app_colors.dart` | Central colour palette — all brand colours in one place |

### Auth

| File | Responsibility |
|------|----------------|
| `home_page.dart` | Landing screen with Customer Login, Create Account, and Admin Access buttons |
| `login_user_page.dart` | Customer email + password login form with session check on open |
| `login_admin_page.dart` | Admin-only login form (dark theme) with session check on open |
| `signup_user_page.dart` | New customer registration with username + email uniqueness validation |

### Dashboard

| File | Responsibility |
|------|----------------|
| `admin_dashboard_page.dart` | Admin home: revenue card, 6-tile stats grid, quick actions, side drawer |
| `user_dashboard_page.dart` | Customer home: maroon header (warehouse selector, search, cart badge), banner carousel, category circles, product list, bottom nav bar |
| `banner_carousel.dart` | Auto-scrolling promotional banner widget with dot indicators |

### Catalog

| File | Responsibility |
|------|----------------|
| `product_data.dart` | 5 default products with images; `seedDatabase()` called at startup |
| `manage_products_page.dart` | Admin inventory list with search and stock-level colour indicators |
| `add_product_page.dart` | Admin form to create a new product + email all customers |
| `edit_product_page.dart` | Admin form to update a product + restock email if stock goes 0→positive |
| `view_product_page.dart` | Admin read-only product detail with Edit and Delete actions |
| `user_view_product_page.dart` | Customer product detail: hero image, wishlist toggle, Add to Cart with quantity dialog |
| `categories_page.dart` | Customer 2-column grid of all 8 categories with product-count badges |
| `category_products_page.dart` | Customer product list scoped to one category with search + chip filters (brand, vehicle type, in-stock toggle) |
| `search_filter_page.dart` | Customer advanced search: category chips, brand chips, vehicle type chips, price range slider, in-stock toggle |

### Cart & Orders

| File | Responsibility |
|------|----------------|
| `cart_page.dart` | Customer cart: quantity controls, item removal, total, checkout button |
| `order_page.dart` | Checkout form: address, phone, special instructions, COD/Card payment with live Luhn validation and card-type detection |
| `user_orders_page.dart` | Customer order history: Active / Completed tabs |
| `order_detail_page.dart` | Customer read-only view of a single order with colour-coded status banner |
| `manage_orders_page.dart` | Admin list of all orders with optional status filter |
| `admin_order_detail_page.dart` | Admin order management: status dropdown + customer email notification; cancellation requires a reason |

### Wishlist

| File | Responsibility |
|------|----------------|
| `wishlist_page.dart` | Customer saved-items list: pull-to-refresh, tap to view product, heart button to remove |

### Profile & Users

| File | Responsibility |
|------|----------------|
| `profile_page.dart` | Customer self-service: edit name, email, phone, password |
| `manage_users_page.dart` | Admin list of all customer accounts |
| `view_user_page.dart` | Admin user detail: Edit, Reset Password (random 10-char + email), Delete |
| `edit_user_page.dart` | Admin form to modify a customer's account fields |

### Misc (Menu Hub)

| File | Responsibility |
|------|----------------|
| `misc_page.dart` | Customer menu hub opened from the bottom nav "Menu" tab. Shows a profile header (name, email, username) and grouped list items: Profile, My Orders, Wishlist, Cart, Support Chat, Sign Out |

### Support / FAQs

| File | Responsibility |
|------|----------------|
| `faq_page.dart` | AI-powered chatbot UI: chat bubbles, Markdown rendering, FAQ picker bottom sheet, New Chat button |
| `manage_faqs_page.dart` | Admin FAQ list with edit/delete per item and Restore Defaults action |
| `add_edit_faq_page.dart` | Dual-purpose form for creating or editing a FAQ question (answers generated by AI, not stored) |

### Analytics

| File | Responsibility |
|------|----------------|
| `revenue_analytics_page.dart` | Revenue line chart (fl_chart), period filter chips (Week/Month/Quarter/Year/Custom), CSV export with Open or Share |

### Shared Services

| File | Responsibility |
|------|----------------|
| `chatbot_service.dart` | Two-step AI chatbot HTTP client: POST /chat → if `data_needed` query local SQLite → POST /chat/respond. Maintains session_id per conversation. Security: only whitelisted tables, private tables auto-scoped to logged-in user. |
| `email_service.dart` | HTTP POST to Google Apps Script relay; handles 200 and 302 responses as success |
| `email_templates.dart` | HTML email body builders for all 9 notification types |

---

## 6. Navigation Flow

```
App Start
  ├── Admin logged in?  →  AdminDashboardPage
  ├── User logged in?   →  UserDashboardPage
  └── Neither           →  HomePage
                               ├── CUSTOMER LOGIN   →  LoginUserPage  →  UserDashboardPage
                               ├── CREATE ACCOUNT   →  SignupUserPage →  LoginUserPage
                               └── ADMIN ACCESS     →  LoginAdminPage →  AdminDashboardPage

UserDashboardPage — bottom navigation bar (5 tabs)
  ├── Home (active)
  │     ├── Search bar        →  live product filter on dashboard
  │     ├── Filter icon       →  SearchFilterPage
  │     ├── Category circle   →  CategoryProductsPage
  │     │     └── Product card →  UserViewProductPage → (Add to Cart) → CartPage → OrderPage
  │     ├── "See All" categories → CategoriesPage → CategoryProductsPage
  │     ├── Warehouse selector → bottom sheet (select warehouse, filters stock)
  │     └── Product card      →  UserViewProductPage
  │           ├── Add to Cart  →  CartPage → OrderPage → UserDashboardPage
  │           └── Heart (♥)   →  toggle WishlistPage
  ├── Wishlist ♥              →  WishlistPage → UserViewProductPage
  ├── Cart 🛍                  →  CartPage → OrderPage → UserDashboardPage
  ├── Chat 💬                  →  FAQPage (AI chatbot)
  └── Menu ☰                  →  MiscPage
        ├── My Profile         →  ProfilePage
        ├── My Orders          →  UserOrdersPage → OrderDetailPage
        ├── My Wishlist        →  WishlistPage
        ├── My Cart            →  CartPage
        ├── Support Chat       →  FAQPage
        └── Sign Out           →  (confirmation dialog) → HomePage

AdminDashboardPage — side drawer
  ├── Revenue card tap  →  RevenueAnalyticsPage
  ├── Product Inventory →  ManageProductsPage   →  ViewProductPage  →  EditProductPage
  ├── Add Product       →  AddProductPage
  ├── Orders & Sales    →  ManageOrdersPage     →  AdminOrderDetailPage
  ├── User Management   →  ManageUsersPage      →  ViewUserPage  →  EditUserPage
  └── Support Content   →  ManageFAQsPage       →  AddEditFAQPage
```

### Named Routes (app.dart)

| Route | Screen |
|-------|--------|
| `/home` | `HomePage` |
| `/login_user` | `LoginUserPage` |
| `/login_admin` | `LoginAdminPage` |
| `/signup_user` | `SignupUserPage` |
| `/admin_dashboard` | `AdminDashboardPage` |
| `/user_dashboard` | `UserDashboardPage` |
| `/misc` | `MiscPage` |
| `/profile` | `ProfilePage` |
| `/my_orders` | `UserOrdersPage` |
| `/wishlist` | `WishlistPage` |
| `/cart` | `CartPage` |
| `/chat` | `FAQPage` |

---

## 7. Email Notification System

Emails are sent via **Google Apps Script** acting as an SMTP relay.

### Triggers & Templates

| Event | Recipient | Template |
|-------|-----------|----------|
| Customer places order | Admin | `newOrderAdmin` |
| Stock drops below 5 after order | Admin | `lowStockAdmin` |
| Product reaches 0 stock after order | Admin | `outOfStockAdmin` |
| Order status changes (any) | Customer | `orderStatusChanged` |
| Order marked Delivered | Customer | `orderDelivered` |
| Order cancelled (with reason) | Customer | `orderCancelled` |
| Product restocked (0→positive stock) | All customers | `productBackInStock` |
| New product added by admin | All customers | `newProductAdded` |
| Admin resets customer password | Affected customer | `passwordReset` |

### Environment Variables (`.env` file)

```
GOOGLE_SCRIPT_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
EMAIL_TOKEN=your_shared_secret
EMAIL_NAME=Ali Grandson Spare Parts
ADMIN_EMAIL=admin@example.com
CHATBOT_URL=https://your-chatbot-server.com
CHATBOT_API_KEY=your_chatbot_api_key
```

---

## 8. Chatbot System

The AI support chatbot (`faq_page.dart` + `chatbot_service.dart`) uses a **two-step HTTP flow**:

### Step 1 — POST `/chat`
```json
{ "question": "user's question", "session_id": "<null on first message, then reused>" }
```
Server responds with either:
- `{ "status": "answered", "answer": "...", "session_id": "..." }` → display immediately
- `{ "status": "data_needed", "ref_code": "...", "data_request": {...}, "session_id": "..." }` → proceed to Step 2

### Step 2 — Query local SQLite + POST `/chat/respond`
The app queries the local database using the `data_request` spec, then sends:
```json
{ "ref_code": "...", "data": [...rows...] }
```
Server responds with the final answer.

### Security Rules (enforced in `chatbot_service.dart`)
- Only whitelisted tables can be queried: `spare_part_products`, `orders`, `order_items`, `faqs`, `users`, `cart`, `wishlist`
- Private tables (`orders`, `cart`, `users`, `wishlist`) are automatically scoped to the logged-in `user_username` — the chatbot server can never read another customer's data
- Results are capped at 50 rows per query

### Session Management
- `session_id` is `null` on the first message; the server creates one and returns it
- Every subsequent message sends the `session_id` back to maintain conversation context (last 3 Q&A pairs)
- Sessions expire after 30 minutes of inactivity on the server
- Tapping **New Chat** calls `ChatbotService.resetSession()` which sets `session_id = null`

---

## 9. Use Cases

### UC-1: New Customer Registration
**Actor:** New visitor  
**Steps:**
1. Opens the app → sees the HomePage.
2. Taps **CREATE ACCOUNT**.
3. Fills in username, full name, email, phone, password (min 8 chars), and date of birth (calendar picker).
4. Taps **CREATE ACCOUNT** — uniqueness checks run for username and email.
5. On success, redirected to the login screen with a success message.
6. Signs in → lands on `UserDashboardPage`.

---

### UC-2: Customer Places an Order
**Actor:** Logged-in customer  
**Steps:**
1. Browses the product catalogue (or searches, or browses by category, or uses advanced filters).
2. Optionally selects a warehouse from the header to see only local stock.
3. Taps a product card → opens `UserViewProductPage`.
4. Taps **ADD TO CART**, enters a quantity (validated against stock).
5. Navigates to `CartPage` via the bottom nav bag icon → adjusts quantities, removes items.
6. Taps **PROCEED TO CHECKOUT** → fills in delivery address, phone, optional instructions.
7. Chooses payment (Cash on Delivery or Card with live Luhn + expiry validation).
8. Taps **CONFIRM & PLACE ORDER**.
9. Database atomically inserts order, deducts stock, clears cart.
10. Admin receives a "New Order" email. Stock alert emails sent if needed.
11. Returns to `UserDashboardPage`.

---

### UC-3: Admin Updates Order Status
**Actor:** Admin  
**Steps:**
1. Opens `AdminDashboardPage` → taps **Pending Orders** stat tile.
2. Selects an order from `ManageOrdersPage`.
3. On `AdminOrderDetailPage`, changes status via the dropdown: `Pending → Ready → In Delivery → Delivered`.
4. Selecting **Cancelled** shows a dialog prompting for a reason.
5. Status saved to database; `completion_date` recorded for Delivered/Cancelled.
6. Customer receives an email notification with the new status (or cancellation reason).

---

### UC-4: Admin Manages Product Inventory
**Actor:** Admin  
**Steps:**
1. Opens **Product Inventory** from the dashboard or side drawer.
2. Filters to **Out of Stock** or **Low Stock** if needed.
3. Taps a product → `ViewProductPage`.
4. Taps **EDIT DETAILS** → `EditProductPage` to update name, price, stock, vehicle type, image.
5. If stock was 0 and is increased, all customers receive a "Back in Stock" email.
6. Admin can permanently delete a product via the bin icon (confirmation dialog required).

---

### UC-5: Admin Resets a Customer Password
**Actor:** Admin  
**Steps:**
1. Navigates to **User Management** → taps a customer card.
2. On `ViewUserPage` taps **RESET PASSWORD** → confirmation dialog.
3. App generates a random 10-character password, saves it, and emails it to the customer.
4. Customer logs in with the temporary password and can change it in Profile.

---

### UC-6: Customer Views Order History
**Actor:** Logged-in customer  
**Steps:**
1. Taps the **Menu** tab in the bottom navigation bar → `MiscPage`.
2. Taps **My Orders** → `UserOrdersPage`.
3. **ACTIVE** tab shows current orders (Pending, Ready, In Delivery).
4. **COMPLETED** tab shows past orders (Delivered, Cancelled).
5. Taps any order card → `OrderDetailPage` showing status banner, order summary, delivery details, and item list.

---

### UC-7: Admin Views Revenue Analytics
**Actor:** Admin  
**Steps:**
1. Taps the revenue card on `AdminDashboardPage`.
2. `RevenueAnalyticsPage` opens, defaulting to the current month.
3. Admin selects a filter: Week, Month, Quarter, Year, Last Year, or a custom date range.
4. The line chart updates with daily revenue totals.
5. Admin taps the export icon → a timestamped CSV is generated.
6. Admin chooses **OPEN** (in a spreadsheet app) or **SHARE** (via OS share sheet).

---

### UC-8: Customer Uses AI Support Chatbot
**Actor:** Logged-in customer  
**Steps:**
1. Taps the **Chat** icon in the bottom navigation bar → `FAQPage`.
2. Screen opens with a greeting from the AI assistant.
3. Customer types a question or taps the FAQ list icon to pick a pre-defined question.
4. `ChatbotService.ask()` sends the question (with `session_id`) to the chatbot server.
5. If the server needs live data (e.g. stock prices, order status), it returns `data_needed`. The app queries local SQLite and sends the result back.
6. The bot's answer appears as a left-aligned white bubble with full Markdown rendering (tables, bold, lists).
7. Customer can start a fresh conversation by tapping **New Chat** (clears session).

---

### UC-9: Customer Manages Wishlist
**Actor:** Logged-in customer  
**Steps:**
1. On any product card or product detail page, taps the **♥ heart** icon to save the product.
2. The heart fills in maroon immediately (optimistic UI update).
3. Taps the **heart icon** in the bottom navigation bar → `WishlistPage`.
4. Sees all saved products sorted by most recently added.
5. Taps a card to view the product; taps the filled heart to remove it.

---

### UC-10: Customer Browses by Category and Filters
**Actor:** Logged-in customer  
**Steps:**
1. On `UserDashboardPage`, taps a category circle (e.g. "Electrical") → `CategoryProductsPage`.
2. Uses the search bar, In Stock toggle, Brand chip, or Vehicle Type chip to narrow results.
3. Alternatively taps "See All" → `CategoriesPage` showing all 8 categories with product counts.
4. For full control taps the filter icon → `SearchFilterPage` with category chips, brand chips, vehicle type chips, price range slider, and in-stock toggle.
5. Taps a product → `UserViewProductPage`.

---

## 10. Configuration

### Required `.env` file
Place a `.env` file at the project root (next to `pubspec.yaml`):

```
GOOGLE_SCRIPT_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
EMAIL_TOKEN=your_secret_token
EMAIL_NAME=Ali Grandson Spare Parts
ADMIN_EMAIL=admin@yourdomain.com
CHATBOT_URL=https://your-chatbot-server.com
CHATBOT_API_KEY=your_chatbot_api_key
```

If the `.env` file is missing:
- Email notifications are silently skipped.
- The chatbot falls back to `http://localhost:8000` and will show a connection error.
- All other app features work normally.

### Default Admin Credentials
Created automatically on first install:
- **Email / ID:** `admin`
- **Password:** `admin123`

> Change these credentials after first login for security.

### Database Seeding (on first install)
1. `ProductData.seedDatabase()` — inserts 5 products with images from `lib/assets/Product_Data/` (only if the products table is empty).
2. `_seedCategories()` — inserts 8 product categories.
3. `_seedWarehouses()` — inserts 2 warehouse records (Muscat, Salalah).
4. `_seedSampleProducts()` — inserts 54 spare-part products across all 8 categories with warehouse stock records.
5. `seedFAQs()` — inserts 8 default FAQ questions.
6. Admin row inserted: email = `admin`, password = `admin123`.
