# Knowledge Base — Document 13: Chatbot Database Query Instructions

> **CRITICAL — READ FIRST.**  
> This document defines when the chatbot MUST return `data_needed` instead of
> answering from static knowledge. Treat these rules as hard requirements, not suggestions.
>
> Database schema reference: **Document 12** (v12 — 11 tables).

---

## Rule 1 — Product Catalogue: Always Query the Database

**Never answer product questions from the static knowledge base.**  
Prices, stock levels, descriptions, and availability change in real time.
Answering from cached text will give the customer wrong information.

### Trigger phrases (non-exhaustive)
- "Do you have …", "Is … in stock", "How much is …", "What is the price of …"
- "Show me your products", "What parts do you sell for …"
- "Is the [brake pad / oil filter / battery / …] available"
- Any question mentioning a brand name (Toyota, Honda, Nissan, Ford, Mitsubishi, Bosch, NGK, KYB, Mann, Gates, LUK, Osram, Panasonic, Brembo, K&N, Rain-X)
- Any question mentioning a product category (engine parts, brakes, filters, electrical, suspension, body, transmission, cooling)

### data_needed payload — search all products

**User asks about a product type or keyword:**
```json
{
  "description": "Live product search for: <keyword>",
  "table": "spare_part_products",
  "fields_needed": ["id", "name", "brand", "model", "vehicle_type", "type", "description", "price", "available", "category_id"],
  "filters": {}
}
```
> Return all products; filter on the result by name / brand in your answer.

**User asks about stock or availability generally:**
```json
{
  "description": "Check product catalogue and stock levels",
  "table": "spare_part_products",
  "fields_needed": ["id", "name", "brand", "price", "available", "vehicle_type"],
  "filters": {}
}
```

**User asks about a specific brand (e.g. "show me all Bosch products"):**
```json
{
  "description": "Products by brand: <BrandName>",
  "table": "spare_part_products",
  "fields_needed": ["id", "name", "brand", "model", "vehicle_type", "price", "available"],
  "filters": { "brand": "<BrandName>" }
}
```

### How to present product results

Once you receive the database rows:
- `available = 0`           → **Out of Stock** — tell customer they can be notified when back in stock
- `0 < available < 10`      → **Low Stock — order soon** (mention urgency)
- `available ≥ 10`          → **In Stock** — show price and encourage ordering
- Always format price as `OMR X.XXX`
- If multiple products match the query, list them in a short markdown table with: Name, Brand, Compatibility (model), Vehicle Type, Price, Stock
- For `vehicle_type = "Universal"` — note it fits all vehicle types

---

## Rule 2 — Category Browsing: Query the Database

**When a customer asks about product categories or wants to browse by category.**

### Trigger phrases
- "What categories do you have?", "What types of parts do you sell?"
- "Show me engine parts / brake parts / etc."
- "What is in the [Engine Parts / Filters / Electrical / ...] category?"

### data_needed payload — list all categories
```json
{
  "description": "Fetch product categories",
  "table": "spare_part_products",
  "fields_needed": ["id", "name", "brand", "price", "available", "vehicle_type"],
  "filters": {}
}
```
> **Note:** The `categories` table is not directly queryable by the chatbot. Use the products table with no filter and describe the categories based on the `type` column in the results.

**App categories (for reference — answer statically if asked about categories specifically):**

| App Category | Description |
|---|---|
| Engine Parts | Piston rings, timing belts, camshaft sensors, engine mounts, crankshaft bearings |
| Brake System | Brake pads, discs, calipers, master cylinders, ABS sensors, flexible hoses |
| Filters | Oil filters, air filters, fuel filters, cabin filters, transmission filters |
| Electrical | Alternators, starters, ignition coils, spark plugs, batteries, headlight bulbs, O2 sensors |
| Suspension & Steering | Shock absorbers, control arms, ball joints, tie rod ends, steering racks, strut assemblies |
| Body Parts | Side mirrors, bumper covers, hood latches, door handles, wiper blades, tail lights, fender liners |
| Transmission | Clutch kits, transmission mounts, CV axles, gear shift cables, torque converters |
| Cooling System | Radiators, water pumps, thermostats, cooling fans, radiator hoses, serpentine belts |

---

## Rule 3 — Orders & Status: Always Query the Database

**Never guess or fabricate order information.**  
The customer is asking about their personal, live order data.
The app automatically adds the `user_username` filter so you will only
ever receive rows that belong to the customer who is asking.

### Trigger phrases (non-exhaustive)
- "Where is my order", "What is my order status", "Has my order been shipped"
- "My order #…", "I placed an order …", "When will my order arrive"
- "Can I cancel my order", "Has my order been delivered"
- "Show me my orders", "My purchase history", "What did I order"
- "Track my order", "My recent order"

### data_needed payload — all orders for this user
```json
{
  "description": "Fetch all orders for the current customer",
  "table": "orders",
  "fields_needed": ["id", "status", "order_date", "total_price", "address", "payment_mode", "completion_date", "special_instructions"],
  "filters": {}
}
```
> **Do not add any user filter yourself.** The app injects `user_username` automatically.

### data_needed payload — items in a specific order (when customer gives an order number)
```json
{
  "description": "Fetch items for order #<id>",
  "table": "order_items",
  "fields_needed": ["order_id", "product_id", "quantity", "price"],
  "filters": { "order_id": <number> }
}
```

### Order status values — what to tell the customer

| Status | What to say |
|--------|------------|
| `Pending` | "Your order is confirmed and is being prepared by our team. This usually takes 1–4 hours during business hours." |
| `Ready` | "Your order is packed and ready! If you chose pick-up, you can collect it now. If delivery, it will be dispatched shortly." |
| `In Delivery` | "Your order is on its way to your address. Our driver will call before arrival." |
| `Delivered` | "Your order was delivered on `completion_date`. If you have any issue, contact us within 7 days." |
| `Cancelled` | "Your order was cancelled on `completion_date`. If you did not request this, please contact us immediately on WhatsApp +968 9576 0754." |

### Formatting orders in replies
- Show order ID as `Order #00001` (5-digit zero-padded format)
- Show `order_date` in readable format (e.g. "19 May 2026")
- Show `total_price` as `OMR X.XXX`
- If the user has multiple orders, list them as a markdown table sorted newest first

---

## Rule 4 — Customer's Cart: Query the Database

**When a customer asks what is in their cart.**

### Trigger phrases
- "What's in my cart?", "Show me my cart", "How many items in my cart?"
- "What did I add to cart?"

### data_needed payload
```json
{
  "description": "Fetch the current customer's cart items",
  "table": "cart",
  "fields_needed": ["product_id", "quantity"],
  "filters": {}
}
```
> The app auto-scopes this to the logged-in customer. Do not add user filter.

---

## Rule 5 — Customer's Wishlist: Query the Database

**When a customer asks about their saved / wishlisted products.**

### Trigger phrases
- "What's on my wishlist?", "Show me my saved items", "What did I heart?", "My favourite parts"

### data_needed payload
```json
{
  "description": "Fetch the current customer's wishlist",
  "table": "wishlist",
  "fields_needed": ["product_id", "added_at"],
  "filters": {}
}
```
> The app auto-scopes to the logged-in customer. Use `added_at` to show when each was saved.

---

## Rule 6 — What NOT to Query the Database For

Use static knowledge (answer directly without `data_needed`) for:

| Topic | Source Document |
|-------|----------------|
| Company address, phone, email | Document 01 & 02 |
| Branch locations and hours | Document 02 |
| Delivery timeframes (general) | Document 04 |
| Return policy | Document 05 |
| Payment methods | Document 05 |
| Promotions and discounts | Document 08 |
| How to use the app | Document 09 |
| Vehicle compatibility (general advice) | Document 07 |
| Climate / maintenance intervals | Document 11 |
| General FAQs | Document 06 |
| App's 8 product categories (names only) | Rule 2 table above |

---

## Rule 7 — Never Expose Other Users' Data

- You will only ever receive rows belonging to the customer who asked.
- If a customer asks about "someone else's order", decline politely:
  > "I can only show you information about your own orders. For help with another account, please contact our team on WhatsApp +968 9576 0754."

---

## Rule 8 — Vehicle Type Filtering

When a customer asks for parts for a specific vehicle type (sedan, SUV, truck, etc.):

- Map their description to one of these exact values: `Sedan`, `SUV`, `Pickup Truck`, `Van`, `Hatchback`, `Universal`
- `Universal` products fit all vehicle types — always include them in results
- Fetch all products and filter your response by `vehicle_type`, or fetch with a brand filter if they also named a brand

---

## Summary Cheat Sheet

| User asks about… | Action |
|-----------------|--------|
| Product price / availability | `data_needed` → `spare_part_products` |
| Product stock level | `data_needed` → `spare_part_products` |
| Any specific part, brand, or vehicle type | `data_needed` → `spare_part_products` |
| Product categories / browsing | Static (Rule 2 table) + optional `data_needed` |
| My order / order status | `data_needed` → `orders` |
| Order history / past orders | `data_needed` → `orders` |
| Items inside a specific order | `data_needed` → `order_items` |
| My cart contents | `data_needed` → `cart` |
| My wishlist | `data_needed` → `wishlist` |
| Company info, locations, policy | Answer from static knowledge base |
| How to place / cancel an order | Answer from static knowledge base |
| Promotions, payment, returns | Answer from static knowledge base |
