// ============================================================
// wishlist_page.dart — Customer Saved Items Screen
// ============================================================
// Shows all products the logged-in customer has saved to their
// wishlist by tapping the ♥ heart icon on any product card.
//
// Features:
//   • Pull-to-refresh reloads the list from the database.
//   • Tapping a card opens the product detail screen.
//   • Tapping the filled red heart immediately removes the product
//     from the wishlist without a confirmation dialog.
//   • If the wishlist is empty an illustration and a call-to-action
//     button are shown instead of an empty list.
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/user_view_product_page.dart';

/// Displays and manages the customer's saved wishlist items.
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  // The customer's wishlist items merged with product data.
  List<Map<String, dynamic>> _items = [];

  // True while loading from the database.
  bool _isLoading = true;

  // The logged-in customer's username (from SharedPreferences).
  String _username = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads the username from session storage then fetches the wishlist
  /// from the database. If no username is found (not logged in),
  /// the page simply shows an empty list state.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('user_username') ?? '';
    if (_username.isNotEmpty) {
      final items =
          await DatabaseHelper.instance.getUserWishlist(_username);
      if (mounted) setState(() {
        _items = items;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Removes one product from the wishlist in the database,
  /// then removes it from the local list immediately so the
  /// UI updates without needing a full reload.
  Future<void> _remove(int productId) async {
    await DatabaseHelper.instance.removeFromWishlist(_username, productId);
    setState(() => _items.removeWhere((i) => i['id'] == productId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from wishlist'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Navigates to the product detail screen with a fade animation.
  /// Reloads the wishlist when returning in case the user removed it
  /// from the detail page too.
  void _viewProduct(int productId) {
    Navigator.of(context)
        .push(PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, animation, __) =>
              UserViewProductPage(productId: productId),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('MY WISHLIST'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kPrimaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _buildCard(_items[i]),
                  ),
                ),
    );
  }

  /// Placeholder shown when the wishlist has no items yet.
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline_rounded,
              size: 90, color: kGreyMedium.withOpacity(0.4)),
          const SizedBox(height: 24),
          const Text(
            'Your wishlist is empty',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kSecondaryColor),
          ),
          const SizedBox(height: 10),
          const Text(
            'Save parts you like by tapping the heart icon.',
            style: TextStyle(color: kTextSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style:
                ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            child: const Text('EXPLORE PARTS'),
          ),
        ],
      ),
    );
  }

  /// Renders one wishlist item with image, name, price, stock badge,
  /// and a red heart button that removes it when tapped.
  Widget _buildCard(Map<String, dynamic> item) {
    final inStock = (item['available'] as int) > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kGreyLight, width: 1),
      ),
      color: kSurfaceColor,
      child: InkWell(
        onTap: () => _viewProduct(item['id'] as int),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              Hero(
                tag: 'product_${item['id']}',
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: kGrey100,
                  ),
                  child: FutureBuilder<Uint8List?>(
                    future: DatabaseHelper.instance
                        .getProductImage(item['id'] as int),
                    builder: (_, snap) {
                      if (snap.connectionState == ConnectionState.done &&
                          snap.data != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(snap.data!, fit: BoxFit.cover),
                        );
                      }
                      return const Icon(Icons.image_outlined,
                          color: kGreyMedium, size: 28);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['brand']?.toUpperCase() ?? 'GENUINE',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kAccentColor,
                          letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['name'] ?? 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kSecondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['model'] ?? '',
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OMR ${item['price']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: kPrimaryColor,
                              fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: inStock
                                ? kSuccessColor.withOpacity(0.1)
                                : kErrorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            inStock ? 'IN STOCK' : 'OUT OF STOCK',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: inStock ? kSuccessColor : kErrorColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Remove heart button
              IconButton(
                icon: const Icon(Icons.favorite_rounded,
                    color: kPrimaryColor, size: 24),
                onPressed: () => _remove(item['id'] as int),
                tooltip: 'Remove from wishlist',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
