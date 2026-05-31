// ============================================================
// user_view_product_page.dart — Customer Product Detail Screen
// ============================================================
// Shows a customer the full details of a single spare part:
//   • Expanding hero image at the top (SliverAppBar).
//   • Brand, name, and price.
//   • Availability badge (In Stock / Out of Stock).
//   • Description and specifications (Type, Compatibility, Part ID).
//   • Bottom action bar with:
//       ♥ Wishlist toggle button.
//       ADD TO CART button (disabled when out of stock).
//
// When the user taps ADD TO CART, a dialog asks for the quantity.
// The quantity is validated against available stock before adding.
// After adding, the screen closes and returns to the product list.
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

/// Customer-facing product detail page with add-to-cart and wishlist.
class UserViewProductPage extends StatefulWidget {
  /// The database id of the product to display.
  final int productId;
  const UserViewProductPage({super.key, required this.productId});

  @override
  State<UserViewProductPage> createState() => _UserViewProductPageState();
}

class _UserViewProductPageState extends State<UserViewProductPage> {
  // The product record loaded from the database (null while loading).
  Map<String, dynamic>? _product;

  // True while the database call is in progress.
  bool _isLoading = true;

  // Whether this product is currently in the customer's wishlist.
  bool _inWishlist = false;

  // The logged-in customer's username (read from SharedPreferences).
  String _username = '';

  @override
  void initState() {
    super.initState();
    // Load the product data as soon as this screen opens.
    _load();
  }

  /// Reads the session username, fetches the product, and checks
  /// whether it is already in the customer's wishlist.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('user_username') ?? '';
    final product =
        await DatabaseHelper.instance.getProduct(widget.productId);
    // Only check wishlist status if a user is actually logged in.
    final inWishlist = _username.isNotEmpty
        ? await DatabaseHelper.instance
            .isInWishlist(_username, widget.productId)
        : false;
    if (mounted) {
      setState(() {
        _product = product;
        _inWishlist = inWishlist;
        _isLoading = false;
      });
    }
  }

  /// Adds or removes the product from the wishlist and shows a confirmation
  /// snack bar so the user knows the action worked.
  Future<void> _toggleWishlist() async {
    if (_username.isEmpty) return;
    if (_inWishlist) {
      await DatabaseHelper.instance
          .removeFromWishlist(_username, widget.productId);
    } else {
      await DatabaseHelper.instance
          .addToWishlist(_username, widget.productId);
    }
    if (mounted) {
      setState(() => _inWishlist = !_inWishlist);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _inWishlist ? 'Added to wishlist' : 'Removed from wishlist'),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              _inWishlist ? kPrimaryColor : kSecondaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Shows a dialog where the user can type a quantity before adding
  /// to cart. Validates that the requested amount does not exceed stock.
  void _showQuantityDialog() {
    final qtyController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Quantity',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many units would you like to add?'),
            const SizedBox(height: 20),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 15),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text);
              if (qty != null && qty > 0) {
                if (qty <= (_product!['available'] as int)) {
                  Navigator.pop(context);
                  _addToCart(qty);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Not enough stock available.'),
                        backgroundColor: kErrorColor),
                  );
                }
              }
            },
            style:
                ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  /// Inserts the item into the cart database and closes this screen.
  Future<void> _addToCart(int quantity) async {
    if (_username.isEmpty) return;
    await DatabaseHelper.instance
        .addToCart(_username, widget.productId, quantity);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart successfully!'),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Return to the product list so the user can keep browsing.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Product not found.'))
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _product!['brand']?.toUpperCase() ??
                                            'GENUINE',
                                        style: const TextStyle(
                                          color: kAccentColor,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _product!['name'] ?? 'N/A',
                                        style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: kSecondaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        kPrimaryColor.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'OMR ${_product!['price']}',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: kPrimaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildAvailabilityBadge(),
                            const SizedBox(height: 28),
                            const Text('Description',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(
                              _product!['description'] ??
                                  'No description available.',
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: kTextSecondary,
                                  height: 1.6),
                            ),
                            const SizedBox(height: 28),
                            const Text('Specifications',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 14),
                            _specRow('Type',
                                _product!['type'] ?? 'General'),
                            _specRow('Compatibility',
                                _product!['model'] ?? 'Universal'),
                            _specRow('Part ID',
                                '#${widget.productId.toString().padLeft(6, '0')}'),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomSheet: _product != null ? _buildBottomAction() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: kPrimaryColor,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.white24,
          child: Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Wishlist heart in app bar
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(
                _inWishlist
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                color: _inWishlist ? kAccentColor : Colors.white,
                size: 20,
              ),
            ),
            onPressed: _toggleWishlist,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_${widget.productId}',
          child: FutureBuilder<Uint8List?>(
            future: DatabaseHelper.instance
                .getProductImage(widget.productId),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.done &&
                  snap.data != null) {
                return Image.memory(snap.data!, fit: BoxFit.cover);
              }
              return Container(
                color: kGreyLight,
                child: const Icon(Icons.image,
                    size: 80, color: kGreyMedium),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Shows a green "In Stock" or red "Out of Stock" row with an icon.
  Widget _buildAvailabilityBadge() {
    final inStock = (_product!['available'] as int) > 0;
    return Row(
      children: [
        Icon(
          inStock
              ? Icons.check_circle_rounded
              : Icons.error_rounded,
          color: inStock ? kSuccessColor : kErrorColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          inStock
              ? 'In Stock (${_product!['available']} units)'
              : 'Out of Stock',
          style: TextStyle(
              color: inStock ? kSuccessColor : kErrorColor,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Renders one specification row: "Label:  Value" in two columns.
  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: kTextSecondary, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor)),
          ),
        ],
      ),
    );
  }

  /// The sticky bar at the bottom with the wishlist heart and ADD TO CART button.
  Widget _buildBottomAction() {
    final inStock = (_product!['available'] as int) > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Wishlist button
            GestureDetector(
              onTap: _toggleWishlist,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _inWishlist
                      ? kPrimaryColor.withOpacity(0.1)
                      : kGrey100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _inWishlist ? kPrimaryColor : kGreyLight),
                ),
                child: Icon(
                  _inWishlist
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: _inWishlist ? kPrimaryColor : kGreyMedium,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Add to cart button
            Expanded(
              child: ElevatedButton(
                onPressed: inStock ? _showQuantityDialog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      inStock ? kPrimaryColor : kGreyMedium,
                  disabledBackgroundColor: kGreyMedium,
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: Text(
                    inStock ? 'ADD TO CART' : 'OUT OF STOCK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
