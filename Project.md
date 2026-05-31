# Ali Grandson Spare Parts — Project Documentation

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Directory Structure](#3-directory-structure)
4. [Database Structure](#4-database-structure)
5. [File Responsibilities](#5-file-responsibilities)
6. [Navigation Flow](#6-navigation-flow)
7. [Email Notification System](#7-email-notification-system)
8. [Use Cases](#8-use-cases)
9. [Configuration](#9-configuration)

---

## 1. Project Overview

**Ali Grandson Spare Parts** is a Flutter mobile application for a spare-parts store based in Muscat, Oman. It supports two types of users:

| User Type | Access |
|-----------|--------|
| **Customer** | Browse products, add to cart, place orders, track order status, view FAQs, manage their own profile |
| **Admin** | Manage products and inventory, view and update orders, manage customers, view revenue analytics, manage FAQs |

All data is stored locally on the device using **SQLite** via the `sqflite` package. Email notifications are sent via a **Google Apps Script** relay.

---

## 2. Technology Stack

| Concern | Package / Tool |
|---------|---------------|
| UI Framework | Flutter (Material 3) |
| Local Database | `sqflite` — SQLite on-device |
| Session Storage | `shared_preferences` — key-value store |
| Image Picking | `image_picker` |
| Charts | `fl_chart` |
| CSV Export | `csv` |
| File Sharing | `share_plus`, `open_filex` |
| HTTP / Email | `http` + Google Apps Script |
| Environment Vars | `flutter_dotenv` (`.env` file) |
| Date Formatting | `intl` |

---

## 3. Directory Structure

```
lib/
├── main.dart                          ← App entry point
└── src/
    ├── app.dart                       ← Root widget, theme, named routes
    ├── core/
    │   ├── database/
    │   │   └── database_helper.dart   ← ALL database operations (singleton)
    │   ├── session/
    │   │   └── session_manager.dart   ← Login session read/write
    │   └── theme/
    │       └── app_colors.dart        ← Brand colour palette
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
    │   │   │   └── product_data.dart  ← Default seed products
    │   │   └── presentation/pages/
    │   │       ├── add_product_page.dart
    │   │       ├── edit_product_page.dart
    │   │       ├── manage_products_page.dart
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
    │   │       └── home_page.dart     ← Landing / splash screen
    │   ├── orders/
    │   │   └── presentation/pages/
    │   │       ├── admin_order_detail_page.dart
    │   │       ├── manage_orders_page.dart
    │   │       ├── order_detail_page.dart
    │   │       ├── order_page.dart    ← Checkout form
    │   │       └── user_orders_page.dart
    │   ├── profile/
    │   │   └── presentation/pages/
    │   │       ├── edit_user_page.dart
    │   │       ├── manage_users_page.dart
    │   │       ├── profile_page.dart
    │   │       └── view_user_page.dart
    │   └── support/
    │       └── presentation/pages/
    │           ├── add_edit_faq_page.dart
    │           ├── faq_page.dart
    │           └── manage_faqs_page.dart
    └── shared/
        ├── services/
        │   └── email_service.dart     ← HTTP POST to Google Apps Script
        └── utils/
            └── email_templates.dart   ← HTML email body builders
```

> **Asset folders** (inside `lib/assets/`):
> - `Imgs/` — app logo and icons
> - `Banner_Imgs/` — three promotional carousel banners
> - `Product_Data/` — default product images (seeded on first run)

---

## 4. Database Structure

**File name:** `alis_grandson.db`  
**SQLite version:** 10 (incremented each schema change)

### Table: `users`
Stores registered customer accounts.

| Column | Type | Notes |
|--------|------|-------|
| `username` | TEXT | **Primary Key** |
| `name` | TEXT | Full display name |
| `email` | TEXT | Unique — used for login |
| `phone` | TEXT | Contact number |
| `password` | TEXT | Plain text (no hashing) |
| `dob` | TEXT | Date of birth as `YYYY-MM-DD` |

### Table: `admins`
Stores admin login credentials.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `email` | TEXT | Admin ID / email |
| `password` | TEXT | Admin password |

> **Default admin:** email = `admin`, password = `admin123`

### Table: `spare_part_products`
The product catalogue.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `name` | TEXT | Product name |
| `description` | TEXT | Short description |
| `image` | BLOB | Raw image bytes |
| `type` | TEXT | Vehicle type (Sedan, SUV, etc.) |
| `brand` | TEXT | Manufacturer brand |
| `model` | TEXT | Compatible model years |
| `price` | REAL | Price in Omani Rials (OMR) |
| `available` | INTEGER | Current stock quantity |

### Table: `cart`
Shopping cart items (not yet ordered).

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `user_username` | TEXT | FK → `users.username` |
| `product_id` | INTEGER | FK → `spare_part_products.id` |
| `quantity` | INTEGER | Number of units |

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
| `total_price` | REAL | Sum of all item prices |
| `status` | TEXT | `Pending` / `Ready` / `In Delivery` / `Delivered` / `Cancelled` |
| `order_date` | TEXT | ISO timestamp |
| `completion_date` | TEXT | Set when Delivered or Cancelled |

### Table: `order_items`
Individual products within each order.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `order_id` | INTEGER | FK → `orders.id` |
| `product_id` | INTEGER | FK → `spare_part_products.id` |
| `quantity` | INTEGER | Units purchased |
| `price` | REAL | Unit price at time of purchase |

### Table: `faqs`
Help questions and answers shown in the Support screen.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Auto-increment PK |
| `question` | TEXT | The FAQ question text |
| `answer` | TEXT | The detailed answer text |

### Entity–Relationship Summary

```
users ──┐
        ├─< cart         (user_username FK)
        ├─< orders       (user_username FK)
        │     └─< order_items (order_id FK)
        │           └── spare_part_products (product_id FK)
        └── (admins is a separate table, no FK link)

faqs  (standalone, no FK)
```

---

## 5. File Responsibilities

### Core

| File | Responsibility |
|------|----------------|
| `main.dart` | Loads `.env`, seeds the database, checks login session, starts the app |
| `app.dart` | Configures the global theme (colours, fonts, button styles) and named routes |
| `database_helper.dart` | Singleton providing all CRUD operations for every database table |
| `session_manager.dart` | Reads and writes login state to `SharedPreferences` |
| `app_colors.dart` | Central colour palette — all brand colours defined in one place |

### Auth

| File | Responsibility |
|------|----------------|
| `home_page.dart` | Landing screen with login, sign-up, and admin access buttons |
| `login_user_page.dart` | Customer email + password login form |
| `login_admin_page.dart` | Admin-only login form (dark theme) |
| `signup_user_page.dart` | New customer registration with uniqueness checks |

### Dashboard

| File | Responsibility |
|------|----------------|
| `admin_dashboard_page.dart` | Admin home: stats grid, revenue card, quick actions, side drawer |
| `user_dashboard_page.dart` | Customer home: banner carousel, search, product list, cart badge, side drawer |
| `banner_carousel.dart` | Reusable auto-scrolling promotional banner widget |

### Catalog

| File | Responsibility |
|------|----------------|
| `product_data.dart` | Default product list + `seedDatabase()` called at startup |
| `manage_products_page.dart` | Admin inventory list with stock-level colour indicators |
| `add_product_page.dart` | Admin form to create a new product + notify customers by email |
| `edit_product_page.dart` | Admin form to update a product + restock email if stock goes 0→positive |
| `view_product_page.dart` | Admin read-only detail view with edit and delete actions |
| `user_view_product_page.dart` | Customer detail view with "Add to Cart" dialog |

### Cart & Orders

| File | Responsibility |
|------|----------------|
| `cart_page.dart` | Customer cart: quantity adjustments, item removal, total, checkout |
| `order_page.dart` | Checkout form: address, phone, payment method, order confirmation |
| `user_orders_page.dart` | Customer order history split into Active / Completed tabs |
| `order_detail_page.dart` | Customer read-only view of a single order |
| `manage_orders_page.dart` | Admin list of all orders with optional status filter |
| `admin_order_detail_page.dart` | Admin order management: status dropdown + customer email notification |

### Profile & Users

| File | Responsibility |
|------|----------------|
| `profile_page.dart` | Customer self-service account settings |
| `manage_users_page.dart` | Admin list of all customer accounts |
| `view_user_page.dart` | Admin user detail: edit, reset password, delete |
| `edit_user_page.dart` | Admin form to modify a customer's account fields |

### Support / FAQs

| File | Responsibility |
|------|----------------|
| `faq_page.dart` | Customer chatbot-style FAQ interface |
| `manage_faqs_page.dart` | Admin FAQ list with expand/edit/delete and restore defaults |
| `add_edit_faq_page.dart` | Dual-purpose form for creating or editing a FAQ entry |

### Analytics

| File | Responsibility |
|------|----------------|
| `revenue_analytics_page.dart` | Revenue line chart, period filter chips, CSV export and share |

### Shared

| File | Responsibility |
|------|----------------|
| `email_service.dart` | HTTP POST to Google Apps Script; handles 200/302 responses |
| `email_templates.dart` | HTML email body builders for every notification type |

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

UserDashboardPage (side drawer)
  ├── Product card tap  →  UserViewProductPage  →  CartPage  →  OrderPage
  ├── Cart icon         →  CartPage             →  OrderPage
  ├── My Orders         →  UserOrdersPage       →  OrderDetailPage
  ├── Account Settings  →  ProfilePage
  └── Help & Support    →  FAQPage

AdminDashboardPage (side drawer)
  ├── Product Inventory →  ManageProductsPage   →  ViewProductPage  →  EditProductPage
  ├── Add Product       →  AddProductPage
  ├── Orders & Sales    →  ManageOrdersPage     →  AdminOrderDetailPage
  ├── User Management   →  ManageUsersPage      →  ViewUserPage  →  EditUserPage
  ├── Support Content   →  ManageFAQsPage       →  AddEditFAQPage
  └── Revenue Card tap  →  RevenueAnalyticsPage
```

---

## 7. Email Notification System

Emails are sent via **Google Apps Script** acting as an SMTP relay.

### Triggers & Templates

| Event | Recipient | Template |
|-------|-----------|----------|
| Customer places order | Admin | `newOrderAdmin` |
| Stock drops below 5 | Admin | `lowStockAdmin` |
| Product reaches 0 stock | Admin | `outOfStockAdmin` |
| Order status changes | Customer | `orderStatusChanged` |
| Order delivered | Customer | `orderDelivered` |
| Order cancelled | Customer | `orderCancelled` |
| Product restocked (0→positive) | All customers | `productBackInStock` |
| New product added | All customers | `newProductAdded` |
| Admin resets password | Affected customer | `passwordReset` |

### Environment Variables (`.env` file)

```
GOOGLE_SCRIPT_URL=https://script.google.com/...
EMAIL_TOKEN=your_shared_secret
EMAIL_NAME=Ali Grandson Spare Parts
ADMIN_EMAIL=admin@example.com
```

---

## 8. Use Cases

### UC-1: New Customer Registration
**Actor:** New visitor  
**Steps:**
1. Opens the app → sees the HomePage landing screen.
2. Taps **CREATE ACCOUNT**.
3. Fills in username, full name, email, phone, password (min 8 chars), and date of birth.
4. Taps **CREATE ACCOUNT** — the app checks that the username and email are not already taken.
5. On success, the user is redirected to the login screen with a success message.
6. The user signs in and lands on the UserDashboardPage.

---

### UC-2: Customer Places an Order
**Actor:** Logged-in customer  
**Steps:**
1. Browses the product catalogue on UserDashboardPage (or searches by keyword).
2. Taps a product card → opens UserViewProductPage with full details.
3. Taps **ADD TO CART**, enters a quantity (validated against stock).
4. Navigates to CartPage via the bag icon → reviews items, adjusts quantities.
5. Taps **PROCEED TO CHECKOUT** → fills in delivery address, phone, optional instructions.
6. Chooses payment method (Cash on Delivery or Card).
7. Taps **CONFIRM & PLACE ORDER**.
8. The database atomically inserts the order, deducts stock, and clears the cart.
9. Admin receives a "New Order" email. Stock alert emails sent if needed.

---

### UC-3: Admin Updates Order Status
**Actor:** Admin  
**Steps:**
1. Opens AdminDashboardPage → taps **Pending Orders** stat card.
2. Selects an order from ManageOrdersPage.
3. On AdminOrderDetailPage, changes status via the dropdown:  
   `Pending → Ready → In Delivery → Delivered`
4. If selecting **Cancelled**, a dialog prompts for a reason.
5. The status is saved to the database.
6. The customer receives an email notification with the new status (or cancellation reason).

---

### UC-4: Admin Manages Product Inventory
**Actor:** Admin  
**Steps:**
1. Opens **Product Inventory** from the dashboard or side drawer.
2. Can filter to show only **Out of Stock** or **Low Stock** items.
3. Taps a product to view its full detail page.
4. Taps **EDIT DETAILS** to update name, price, stock quantity, or image.
5. If stock was 0 and is increased, all registered customers receive a "Back in Stock" email.
6. Admin can permanently delete a product via the bin icon (confirmation required).

---

### UC-5: Admin Resets a Customer Password
**Actor:** Admin  
**Steps:**
1. Navigates to **User Management** → taps a customer card.
2. On ViewUserPage taps **RESET PASSWORD**.
3. Confirms the action in the confirmation dialog.
4. The app generates a random 10-character password, saves it to the database, and emails it to the customer.
5. The customer logs in with the new temporary password and can change it in their Profile.

---

### UC-6: Customer Views Order History
**Actor:** Logged-in customer  
**Steps:**
1. Opens the side drawer → taps **My Orders**.
2. UserOrdersPage shows two tabs: **ACTIVE** and **COMPLETED**.
3. Taps any order card to open OrderDetailPage.
4. Sees the current status banner, order summary (date, payment, total), delivery details, and the list of purchased items.

---

### UC-7: Admin Views Revenue Analytics
**Actor:** Admin  
**Steps:**
1. Taps the revenue card on AdminDashboardPage.
2. RevenueAnalyticsPage opens, defaulting to the current month.
3. Admin selects a different filter: Week, Quarter, Year, Last Year, or a custom date range.
4. The line chart updates showing daily revenue totals.
5. Admin taps the export icon → a CSV file is generated.
6. Admin chooses to **OPEN** (in a spreadsheet app) or **SHARE** (via email, messaging, etc.).

---

### UC-8: Customer Uses FAQ / Support
**Actor:** Logged-in customer  
**Steps:**
1. Opens the side drawer → taps **Help & Support**.
2. FAQPage opens with a greeting message from the bot.
3. Customer taps **ASK A QUESTION** → a bottom sheet lists all FAQ questions.
4. Customer taps a question.
5. Both the question and its answer appear in the chat as coloured speech bubbles.

---

## 9. Configuration

### Required `.env` file
Place a `.env` file at the project root (next to `pubspec.yaml`):

```
GOOGLE_SCRIPT_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
EMAIL_TOKEN=your_secret_token
EMAIL_NAME=Ali Grandson Spare Parts
ADMIN_EMAIL=admin@yourdomain.com
```

If the `.env` file is missing, email notifications will be silently skipped but the rest of the app will continue to work normally.

### Default Admin Credentials
Created automatically on first install:  
- **Email / ID:** `admin`  
- **Password:** `admin123`

> Change these credentials from the device by editing the `admins` table directly, or add a Change Password feature to the admin panel.
