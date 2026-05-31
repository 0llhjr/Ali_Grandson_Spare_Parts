// ============================================================
// manage_products_page.dart — Admin Product Inventory Screen
// ============================================================
// Shows the admin a searchable list of all spare-part products.
// An optional [filter] can narrow the list to:
//   'out_of_stock' — products with 0 units available
//   'low_stock'    — products with 1–9 units available
//   null           — all products
//
// Each row shows a small thumbnail, name, price, and a coloured
// stock dot (red/yellow/green).  Tapping a row opens ViewProductPage
// where the admin can edit or delete the product.
//
// The "+" icon in the app bar opens AddProductPage.
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/add_product_page.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/view_product_page.dart';

/// Admin screen for browsing and managing the product catalogue.
class ManageProductsPage extends StatefulWidget {
  /// Optional filter: 'out_of_stock', 'low_stock', or null for all.
  final String? filter;
  const ManageProductsPage({super.key, this.filter});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.instance.getProducts(filter: widget.filter);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProducts(String keyword) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.instance.searchProducts(keyword);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'PRODUCT INVENTORY';
    if (widget.filter == 'out_of_stock') title = 'OUT OF STOCK';
    if (widget.filter == 'low_stock') title = 'LOW STOCK';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kPrimaryColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProductPage()),
            ).then((_) => _loadProducts()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) => _buildProductItem(_products[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: kSurfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search inventory...',
          prefixIcon: const Icon(Icons.search_rounded),
          fillColor: kGreyLight.withOpacity(0.5),
        ),
        onChanged: _searchProducts,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: kGreyMedium.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No products found', style: TextStyle(color: kTextSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    int stock = product['available'] as int;
    Color statusColor = stock == 0 ? kErrorColor : (stock < 10 ? kWarningColor : kSuccessColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kGreyLight)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: kGreyLight),
          child: FutureBuilder<Uint8List?>(
            future: DatabaseHelper.instance.getProductImage(product['id'] as int),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(snapshot.data!, fit: BoxFit.cover));
              }
              return const Icon(Icons.image, color: kGreyMedium);
            },
          ),
        ),
        title: Text(product['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('OMR ${product['price']}', style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Stock: $stock', style: const TextStyle(fontSize: 12, color: kTextSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kGreyMedium),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViewProductPage(productId: product['id'] as int)),
        ).then((_) => _loadProducts()),
      ),
    );
  }
}
