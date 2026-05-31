# Knowledge Base — Document 10: Chatbot Quick-Response Reference Sheet

This document provides pre-written, concise responses for the most common chatbot queries. The chatbot should use these as templates and adapt them naturally based on context.

---

## Greetings & Small Talk

**[INTENT: Greeting]**  
Hello! Welcome to Ali Grandson Spare Parts support. I am here to help you find the right parts, track your order, or answer any questions about our store. How can I assist you today?

**[INTENT: How are you]**  
I am doing great, thank you for asking! I am ready to help you with any spare parts needs. What can I do for you?

**[INTENT: Thank you]**  
You are very welcome! If you have any other questions or need help with your order, I am always here. Have a great day!

**[INTENT: Goodbye]**  
Goodbye! Thank you for choosing Ali Grandson Spare Parts. Drive safe!

---

## Store Information

**[INTENT: Where is the store / store location]**  
Ali Grandson Spare Parts has 7 locations across Oman:
1. Muscat – Wadi Kabir (Head Office) — Industrial Area, PC 118
2. Salalah – Al-Nahdha — Near Salalah Grand Mall
3. Sohar – Al-Multaqa — Industrial Area near OAPIL roundabout
4. Sur – Al-Wusta — Near Sur Central Hospital
5. Nizwa – Al-Aqr — Al-Aqr Industrial Area
6. Buraimi – Al-Sarooj — Near Buraimi Hotel
7. Ibri – Al-Nakheel — Near Ibri Central Market

Which city are you in? I can give you the exact address and phone number.

**[INTENT: Store hours / opening hours]**  
Our main Muscat branch is open Saturday to Thursday 8:00 AM – 8:00 PM and Friday 9:00 AM – 12:00 PM then 4:00 PM – 8:00 PM. The app is available 24/7 for online orders. Hours vary slightly per branch — which city are you asking about?

**[INTENT: Phone number / contact number]**  
You can reach us on:
- **WhatsApp:** +968 9576 0754 (fastest — 8 AM to 8 PM, Sat–Thu)
- **Phone:** +968 9576 0754
- **Email:** aligrandsoncompany@gmail.com
- Or visit any of our 7 branches across Oman.

**[INTENT: WhatsApp number]**  
Our WhatsApp number is **+968 9576 0754**. We are available from 8:00 AM to 8:00 PM, Saturday to Thursday.

**[INTENT: Email address]**  
Our contact email is **aligrandsoncompany@gmail.com**. We respond within 1 business day.

**[INTENT: Salalah branch]**  
Our Salalah branch is on Al-Nahdha Street, near Al-Nahdha Roundabout, adjacent to Salalah Grand Mall parking entrance. Phone: +968 2329 5500 | WhatsApp: +968 9329 5500. Open Sat–Thu 8 AM–7:30 PM, Fri 9–11:30 AM and 4–7:30 PM.

**[INTENT: Sohar branch]**  
Our Sohar branch is in the Industrial Area, Al-Multaqa Street, beside Sohar Hyundai Service Centre. Phone: +968 2685 4400 | WhatsApp: +968 9685 4400. Open Sat–Thu 7:30 AM–7 PM.

**[INTENT: Nizwa branch]**  
Our Nizwa branch is in Al-Aqr Industrial Area, behind the Nizwa Souq roundabout. Phone: +968 2541 2200 | WhatsApp: +968 9541 2200. Open Sat–Thu 8 AM–7:30 PM.

**[INTENT: Buraimi branch]**  
Our Buraimi branch is on Al-Sarooj Street, near the Buraimi Hotel and Conference Centre. Phone: +968 2565 8800 | WhatsApp: +968 9565 8800. Open Sat–Thu 8 AM–8 PM.

**[INTENT: Sur branch]**  
Our Sur branch is in Al-Wusta District, opposite Sur Central Hospital. Phone: +968 2554 7700 | WhatsApp: +968 9554 7700. Open Sat–Thu 8 AM–7 PM.

**[INTENT: Ibri branch]**  
Our Ibri branch is in Al-Nakheel Commercial Area near Ibri Central Market. Phone: +968 2569 3300 | WhatsApp: +968 9569 3300. Open Sat–Thu 8:30 AM–7 PM.

---

## Ordering

**[INTENT: How to place an order]**  
Placing an order is easy! Here are the steps:
1. Log in to the app.
2. Browse the catalogue or search for your part.
3. Tap a product and tap **ADD TO CART**. Enter the quantity.
4. Tap the bag icon in the bottom navigation bar, then tap **PROCEED TO CHECKOUT**.
5. Enter your delivery address and choose payment (Cash on Delivery or Card).
6. Tap **CONFIRM & PLACE ORDER**. Done!

You will receive email notifications as your order progresses.

**[INTENT: Can I order without account]**  
No, you need a free account to order. Registration takes under 2 minutes — tap **CREATE ACCOUNT** on the home screen and fill in your details.

**[INTENT: Minimum order]**  
There is no minimum order value. You can order a single item and receive it with free delivery anywhere in Oman!

**[INTENT: Order confirmation / where is my confirmation]**  
After placing an order, check your email inbox (including spam/junk) for a confirmation from aligrandsoncompany@gmail.com. You can also view your order in the app under My Orders.

---

## Delivery

**[INTENT: Delivery time / how long]**  
Delivery times depend on your location:

| Area | Estimated Time |
|------|----------------|
| Muscat | Same day (orders before 2 PM) or next business day |
| Salalah/Dhofar | 1–2 business days |
| Sohar | Same day or next day |
| Nizwa | Next business day |
| Sur | 1–2 business days |
| Buraimi | Same day or next day |
| Ibri | Next business day |
| Remote areas | 3–5 business days |

**All deliveries are FREE!**

**[INTENT: Delivery cost / delivery fee]**  
Great news — delivery is completely **FREE** on all orders, no minimum required!

**[INTENT: Self pick-up]**  
Yes! During checkout, select **Self Pick-Up** and choose your nearest branch. Your order will be ready within 2–4 hours. You will get an app notification and email when it is ready. Bring your order number when collecting.

**[INTENT: Track order / where is my order]**  
To track your order, open the app and go to **My Orders**. The ACTIVE tab shows your current orders with real-time status (Pending → Ready → In Delivery → Delivered). You also receive email updates automatically for every status change.

**[INTENT: Cancel order]**  
You can cancel an order while it is in **PENDING** status. Contact us immediately via WhatsApp (+968 9576 0754) or email (aligrandsoncompany@gmail.com) with your order number. Once the order is READY or IN DELIVERY, cancellation is not possible.

---

## Products

> **IMPORTANT:** For any specific product, price, or stock question, always query the live database via `data_needed`. Do not answer from this document. See Document 13 for query payloads.

**[INTENT: Do you have / availability check]**  
*(Query database first, then respond)*  
Search for the product in the app using the search bar. If it shows **IN STOCK**, you can order immediately. If **OUT OF STOCK**, you will be emailed automatically when it is available. You can also WhatsApp us at +968 9576 0754 for a quick check.

**[INTENT: Browse by category]**  
Our app has 8 product categories you can browse:
1. Engine Parts
2. Brake System
3. Filters
4. Electrical
5. Suspension & Steering
6. Body Parts
7. Transmission
8. Cooling System

Tap any category circle on the dashboard, or tap "See All" to open the full grid. You can also filter by vehicle type (Sedan, SUV, Pickup Truck, Universal) within each category.

**[INTENT: Part for specific vehicle]**  
To find the right part for your vehicle, it helps to know:
- Car make (e.g. Toyota, Nissan, Honda)
- Car model (e.g. Land Cruiser, Patrol, Accord)
- Year (e.g. 2019)
- Engine type (e.g. 4.0L petrol, 2.8L diesel)
- What part you need (e.g. brake pads, air filter)

Use the **Search & Filter** page in the app (tap the sliders icon) and filter by vehicle type to narrow results. Or WhatsApp us the details at +968 9576 0754.

**[INTENT: Brake pads]**  
*(Query database for current prices, then respond)*  
We stock brake pads for most vehicles — ceramic pads for everyday sedans (quieter, less dust) and semi-metallic for heavy SUVs and off-road use (higher heat resistance). Search "brake pad" in the app or filter by the "Brake System" category.

**[INTENT: Oil filter]**  
*(Query database for current prices, then respond)*  
We stock quality oil filters from Bosch and other brands for most vehicles. In Oman's dusty climate, change your oil filter every 5,000 km (conventional oil) or 8,000–10,000 km (synthetic). Search "oil filter" in the app.

**[INTENT: Spark plugs]**  
*(Query database for current prices, then respond)*  
We stock NGK iridium spark plugs — the world's leading brand. Replace as a full set. Search "spark plug" in the app or browse the "Electrical" category.

**[INTENT: Air filter]**  
*(Query database for current prices, then respond)*  
We stock quality air filters. In Oman's dusty environment, inspect your air filter every 10,000 km and replace by 15,000–20,000 km. Search "air filter" in the app.

**[INTENT: Wiper blades]**  
*(Query database for current prices, then respond)*  
We stock wiper blades in sizes for most vehicles. If you are in Salalah, replace your wipers before the Khareef (monsoon) in July. Search "wiper" in the app.

**[INTENT: Battery]**  
*(Query database for current prices, then respond)*  
We stock AGM and standard car batteries for most vehicles. Batteries in Oman typically last only 2–3 years due to extreme heat. **Free battery testing** is available at all 7 branches. Search "battery" in the app.

**[INTENT: Shock absorbers]**  
*(Query database for current prices, then respond)*  
We stock shock absorbers and strut assemblies. For off-road use common in Oman (wadis, dunes), upgraded shocks are recommended. Inspect every 30,000 km. Search "shock" in the app or browse "Suspension & Steering".

---

## Wishlist

**[INTENT: What is the wishlist / how do I use it]**  
The wishlist lets you save products you are interested in for later. Tap the **heart icon (♥)** on any product card or detail page to add it. Access your wishlist by tapping the **heart icon** in the bottom navigation bar. To remove a product, tap the filled heart on the wishlist page.

**[INTENT: My wishlist / what's on my wishlist]**  
*(Query database via `data_needed` with `table: "wishlist"`, then list the saved products)*

---

## Payment

**[INTENT: Payment methods]**  
We accept:
- **Cash on Delivery (COD)** — pay when your order arrives
- **Credit/Debit Card** — Visa, Mastercard, American Express (secure in-app payment with real-time validation)
- **Bank Transfer** — for wholesale/corporate accounts
- **Branch payment** — cash or card at any of our 7 stores

**[INTENT: Is it safe to pay by card]**  
Absolutely. Card payments are processed through a PCI-DSS compliant, encrypted payment gateway. We never store your full card number.

**[INTENT: Cash on delivery]**  
Yes, Cash on Delivery is available on all orders. Pay the exact amount in Omani Rials to the delivery driver when your order arrives. A receipt will be issued.

**[INTENT: Card validation errors]**  
The app validates your card in real time. If the card number turns red, it means the digits do not form a valid card number — check for a typo. If the expiry date turns red, the card may be expired. The checkout button stays disabled until all fields are valid. If you believe your card is valid but the app rejects it, contact your bank or try a different card.

---

## Returns & Warranty

**[INTENT: Return policy / can I return]**  
Yes! You can return items within 7 days of delivery if they are:
- Unused and in original packaging (change of mind)
- Damaged or defective on arrival
- The wrong item was delivered

Contact us via WhatsApp (+968 9576 0754) or aligrandsoncompany@gmail.com with your order number and reason.

**[INTENT: Wrong item received]**  
We are sorry about that! Please contact us within 48 hours of receiving the wrong item. WhatsApp us at +968 9576 0754 with your order number and a photo. We will arrange a free collection and send you the correct item immediately.

**[INTENT: Damaged item]**  
We apologise for the inconvenience. Please take photos of the damage and contact us within 24 hours at +968 9576 0754 (WhatsApp) or aligrandsoncompany@gmail.com. We will replace the item at no cost to you.

**[INTENT: Warranty]**  
Most products come with a warranty:

| Product | Warranty |
|---------|---------|
| Brake pads/discs | 12 months or 20,000 km |
| Shock absorbers | 18 months or 30,000 km |
| Batteries | 24 months |
| Spark plugs | 12 months |
| Alternators/starters | 12 months |
| Clutch kits | 6 months or 20,000 km |

Filters and wiper blades are consumables with no warranty. Contact support with your order number to make a warranty claim.

---

## Promotions

**[INTENT: Discounts / offers / promotions]**  
Current promotions include:
- First order: 5% OFF with code **WELCOME5** (new customers, valid 30 days, min order OMR 10)
- National Day (Nov 17–19): 18% OFF sitewide
- Summer (Jun–Aug): Battery + Oil Filter combo 15% OFF
- Bulk buy: 5% OFF for 3+ identical items, 10% OFF for 5+ identical items
- Free delivery: Always — on every order, no minimum!

**[INTENT: First order discount]**  
Welcome! As a new customer, you get **5% OFF your first order**. Use code **WELCOME5** at checkout. Valid for 30 days from registration, minimum order OMR 10.

---

## Wholesale & Business

**[INTENT: Wholesale / bulk order for garage]**  
We have a Wholesale Programme for garages, workshops, and fleet operators with volume discounts up to 20%. Contact our Wholesale Department:
- **Email:** aligrandsoncompany@gmail.com
- **Phone:** +968 9576 0754

**[INTENT: Corporate fleet account]**  
Yes! Companies managing 5+ vehicles can apply for a Corporate Fleet Account with dedicated pricing, monthly invoicing, and priority service. Email aligrandsoncompany@gmail.com or call +968 9576 0754.

---

## Escalation Phrases

**[INTENT: Speak to a human / real agent]**  
Of course! Here is how to reach our team directly:
- **WhatsApp:** +968 9576 0754 (fastest — available 8 AM to 8 PM, Sat–Thu)
- **Phone:** +968 9576 0754
- **Email:** aligrandsoncompany@gmail.com
- Visit any branch in person

**[INTENT: Complaint]**  
I am sorry to hear you had an issue. Your satisfaction is very important to us. Please contact our Customer Relations team directly:
- **WhatsApp:** +968 9576 0754
- **Email:** aligrandsoncompany@gmail.com

Please include your order number and a description of the issue. We aim to resolve all complaints within 1 business day.

**[INTENT: Not satisfied with answer]**  
I understand. For more detailed help, please reach our support team:
- **WhatsApp:** +968 9576 0754 (response within minutes during business hours)
- **Email:** aligrandsoncompany@gmail.com

They will be happy to assist you further.
