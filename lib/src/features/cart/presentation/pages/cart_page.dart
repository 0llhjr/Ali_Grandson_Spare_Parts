// ============================================================
// cart_page.dart — Shopping Cart Screen
// ============================================================
// Shows all items the logged-in user has added to their cart.
// The user can:
//   • Increase or decrease an item's quantity (capped by stock).
//   • Remove an item entirely.
//   • See a running total of all items.
//   • Proceed to checkout (OrderPage).
//
// If the cart is empty a friendly "empty cart" graphic is shown.
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/orders/presentation/pages/order_page.dart';

/// Displays the current user's shopping cart.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // The list of cart items (each item is a merged product + cart row).
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  /// Reads the current user's username from session storage, then
  /// fetches all their cart items from the database.
  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';
    if (username.isNotEmpty) {
      final items = await DatabaseHelper.instance.getCartItems(username);
      if (mounted) {
        setState(() {
          _cartItems = items;
          _isLoading = false;
        });
      }
    }
  }

  /// Changes the quantity of an item.
  /// Prevents setting a quantity higher than the available stock.
  Future<void> _updateQuantity(Map<String, dynamic> item, int newQuantity) async {
    final available = item['available'] as int;

    // Guard: cannot order more than what is in stock.
    if (newQuantity > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only $available items available in stock.'),
          backgroundColor: kWarningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Only update if the new quantity is still a positive number.
    if (newQuantity > 0) {
      await DatabaseHelper.instance.updateCartItem(item['cart_id'], newQuantity);
      _loadCartItems(); // Refresh the list
    }
  }

  /// Removes a single item from the cart by its cart row id.
  Future<void> _deleteItem(int cartId) async {
    await DatabaseHelper.instance.deleteCartItem(cartId);
    _loadCartItems(); // Refresh the list
  }

  /// Computed property: sums price × quantity across all cart items.
  double get _totalPrice {
    return _cartItems.fold(
        0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('SHOPPING CART'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    // Scrollable list of cart items.
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return _buildCartItem(item);
                        },
                      ),
                    ),
                    // Sticky checkout panel at the bottom.
                    _buildCheckoutSection(),
                  ],
                ),
    );
  }

  /// Shown when there are no items in the cart.
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 100, color: kGreyMedium.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: kSecondaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            'Add some spare parts to get started!',
            style: TextStyle(color: kTextSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 54)),
            child: const Text('BACK TO EXPLORE'),
          ),
        ],
      ),
    );
  }

  /// Renders a single cart item card with image, name, price, and quantity controls.
  Widget _buildCartItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kGreyLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // ── Product image (async, loaded separately) ──────
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: kGreyLight),
              child: FutureBuilder<Uint8List?>(
                future: DatabaseHelper.instance.getProductImage(item['id'] as int),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                    );
                  }
                  return const Icon(Icons.image, color: kGreyMedium);
                },
              ),
            ),

            const SizedBox(width: 16),

            // ── Item details + quantity controls ──────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? 'No Name',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('OMR ${item['price']}',
                      style: const TextStyle(
                          color: kPrimaryColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  // Minus / quantity number / plus row
                  Row(
                    children: [
                      _buildQuantityButton(Icons.remove,
                          () => _updateQuantity(item, item['quantity'] - 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('${item['quantity']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      _buildQuantityButton(Icons.add,
                          () => _updateQuantity(item, item['quantity'] + 1)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Delete button ─────────────────────────────────
            IconButton(
              icon: const Icon(Icons.delete_outline, color: kErrorColor),
              onPressed: () => _deleteItem(item['cart_id']),
            ),
          ],
        ),
      ),
    );
  }

  /// A small circular +/- button used for adjusting item quantity.
  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kGreyMedium),
        ),
        child: Icon(icon, size: 18, color: kSecondaryColor),
      ),
    );
  }

  /// The sticky bottom panel showing the total price and the checkout button.
  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount',
                    style: TextStyle(color: kTextSecondary, fontSize: 16)),
                Text(
                  'OMR ${_totalPrice.toStringAsFixed(3)}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: kPrimaryColor),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Navigate to the checkout/order form.
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const OrderPage()));
              },
              style: ElevatedButton.styleFrom(
                shadowColor: kPrimaryColor.withOpacity(0.3),
                elevation: 10,
              ),
              child: const Text('PROCEED TO CHECKOUT'),
            ),
          ],
        ),
      ),
    );
  }
}
