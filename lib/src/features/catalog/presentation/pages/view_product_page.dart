// ============================================================
// view_product_page.dart — Admin: Product Detail Screen
// ============================================================
// Shows the admin a full read-only view of a product with a
// large expanding header image (SliverAppBar).
//
// Bottom action bar provides two buttons:
//   • EDIT DETAILS — navigates to EditProductPage
//   • Delete (bin icon) — shows a confirmation dialog, then
//     permanently removes the product from the database.
//
// Stock level is shown as a coloured badge (green/red).
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'edit_product_page.dart';

/// Admin product detail screen with edit and delete actions.
class ViewProductPage extends StatefulWidget {
  /// The database id of the product to display.
  final int productId;

  const ViewProductPage({super.key, required this.productId});

  @override
  State<ViewProductPage> createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {
  Map<String, dynamic>? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final product = await DatabaseHelper.instance.getProduct(widget.productId);
    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Product?', style: TextStyle(fontWeight: FontWeight.bold, color: kErrorColor)),
        content: const Text('This will permanently remove the item from your public catalog. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor, minimumSize: const Size(100, 40)),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteProduct(widget.productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product removed successfully'), backgroundColor: kSecondaryColor, behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop();
    }
  }

  void _navigateToEditProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EditProductPage(productId: widget.productId)),
    ).then((_) => _loadProduct());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Product data unavailable.'))
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBasicInfo(),
                            const SizedBox(height: 32),
                            _buildInventoryStatus(),
                            const SizedBox(height: 32),
                            _buildSectionHeader('Description'),
                            const SizedBox(height: 12),
                            Text(
                              _product!['description'] ?? 'No description provided for this part.',
                              style: const TextStyle(fontSize: 15, color: kTextSecondary, height: 1.6),
                            ),
                            const SizedBox(height: 32),
                            _buildSectionHeader('Specifications'),
                            const SizedBox(height: 16),
                            _buildSpecCard(),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomSheet: _product != null ? _buildActionDock() : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: kPrimaryColor,
      leading: IconButton(
        icon: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: FutureBuilder<Uint8List?>(
          future: DatabaseHelper.instance.getProductImage(widget.productId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            }
            return Container(color: kGreyLight, child: const Icon(Icons.image_outlined, size: 80, color: kGreyMedium));
          },
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _product!['brand']?.toUpperCase() ?? 'GENUINE',
          style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _product!['name'] ?? 'N/A',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kSecondaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'OMR ${_product!['price']}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimaryColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryStatus() {
    int stock = _product!['available'] as int;
    bool inStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (inStock ? kSuccessColor : kErrorColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (inStock ? kSuccessColor : kErrorColor).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(inStock ? Icons.inventory_2_rounded : Icons.block_rounded, size: 18, color: inStock ? kSuccessColor : kErrorColor),
          const SizedBox(width: 8),
          Text(
            inStock ? 'STOCK LEVEL: $stock UNITS' : 'OUT OF STOCK',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: inStock ? kSuccessColor : kErrorColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kSecondaryColor, letterSpacing: 1.5),
    );
  }

  Widget _buildSpecCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGreyLight),
      ),
      child: Column(
        children: [
          _buildSpecRow('Category', _product!['type'] ?? 'General'),
          const Divider(height: 24),
          _buildSpecRow('Model/Year', _product!['model'] ?? 'Universal'),
          const Divider(height: 24),
          _buildSpecRow('Database ID', '#${widget.productId.toString().padLeft(6, '0')}'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
      ],
    );
  }

  Widget _buildActionDock() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _navigateToEditProduct,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('EDIT DETAILS'),
                style: ElevatedButton.styleFrom(backgroundColor: kSecondaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(color: kErrorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: kErrorColor),
                onPressed: _deleteProduct,
                tooltip: 'Delete Product',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
