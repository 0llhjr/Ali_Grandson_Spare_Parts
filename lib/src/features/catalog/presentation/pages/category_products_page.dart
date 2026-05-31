// ============================================================
// category_products_page.dart — Products by Category Screen
// ============================================================
// Lists all spare parts belonging to a single category.
// The page supports live filtering without leaving the screen:
//
//   Search bar  — keyword search within this category only.
//   In Stock    — toggle chip to hide out-of-stock items.
//   Brand       — dropdown chip to filter by brand name.
//   Vehicle     — dropdown chip to filter by vehicle type.
//
// All filters update the list instantly on change.
// A "Clear" button in the app bar appears when any filter is active.
//
// Products are fetched respecting the user's currently selected
// warehouse (read from SharedPreferences on init).
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/user_view_product_page.dart';

/// Shows products filtered to one category with search and chip filters.
class CategoryProductsPage extends StatefulWidget {
  /// The category's database id (used to scope the DB query).
  final int categoryId;

  /// The category name displayed in the app bar title.
  final String categoryName;

  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  // Products currently shown (updated whenever a filter changes).
  List<Map<String, dynamic>> _products = [];

  // All distinct brand names for the Brand filter chip.
  List<String> _brands = [];

  // All distinct vehicle types for the Vehicle filter chip.
  List<String> _vehicleTypes = [];

  // True while a database query is running.
  bool _isLoading = true;

  // The warehouse id saved in preferences (null = show all warehouses).
  int? _warehouseId;

  // Controls the search text field at the top of the filter bar.
  final _searchController = TextEditingController();

  // Currently active filter values (null = no filter applied).
  String? _selectedBrand;
  String? _selectedVehicleType;
  bool _inStockOnly = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Reads the saved warehouse, pre-loads brand and vehicle-type lists
  /// for the filter chips, then fetches the initial product list.
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _warehouseId = prefs.getInt('selected_warehouse_id');
    final brands = await DatabaseHelper.instance.getDistinctBrands();
    final types = await DatabaseHelper.instance.getDistinctVehicleTypes();
    setState(() {
      _brands = brands;
      _vehicleTypes = types;
    });
    await _fetch();
  }

  /// Queries the database with all active filters applied.
  /// Called after every filter change or search keystroke.
  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final keyword = _searchController.text.trim();
    List<Map<String, dynamic>> results;
    if (keyword.isEmpty) {
      results = await DatabaseHelper.instance.getProducts(
        categoryId: widget.categoryId,
        warehouseId: _warehouseId,
        brand: _selectedBrand,
        vehicleType: _selectedVehicleType,
        inStockOnly: _inStockOnly,
      );
    } else {
      results = await DatabaseHelper.instance.searchProducts(
        keyword,
        categoryId: widget.categoryId,
        warehouseId: _warehouseId,
        brand: _selectedBrand,
        vehicleType: _selectedVehicleType,
        inStockOnly: _inStockOnly,
      );
    }
    if (mounted) setState(() {
      _products = results;
      _isLoading = false;
    });
  }

  /// Resets all active filters and the search box, then re-fetches.
  void _clearFilters() {
    setState(() {
      _selectedBrand = null;
      _selectedVehicleType = null;
      _inStockOnly = false;
      _searchController.clear();
    });
    _fetch();
  }

  /// True when at least one filter is active — used to show the "Clear" button.
  bool get _hasFilters =>
      _selectedBrand != null || _selectedVehicleType != null || _inStockOnly;

  /// Navigates to the product detail page with a fade transition.
  void _openProduct(int productId) {
    Navigator.of(context)
        .push(PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) =>
              UserViewProductPage(productId: productId),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ))
        .then((_) => _fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(widget.categoryName.toUpperCase()),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_hasFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        color: kPrimaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          itemBuilder: (_, i) => _buildCard(_products[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Builds the white search + filter chip bar pinned above the list.
  Widget _buildSearchAndFilters() {
    return Container(
      color: kSurfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _fetch(),
            decoration: InputDecoration(
              hintText: 'Search in ${widget.categoryName}...',
              prefixIcon: const Icon(Icons.search, color: kTextSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _fetch();
                      },
                    )
                  : null,
              filled: true,
              fillColor: kGrey100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('In Stock', _inStockOnly, () {
                  setState(() => _inStockOnly = !_inStockOnly);
                  _fetch();
                }),
                const SizedBox(width: 8),
                if (_brands.isNotEmpty)
                  _dropdownChip<String>(
                    label: _selectedBrand ?? 'Brand',
                    isActive: _selectedBrand != null,
                    items: _brands,
                    value: _selectedBrand,
                    onChanged: (v) {
                      setState(() => _selectedBrand = v);
                      _fetch();
                    },
                  ),
                if (_brands.isNotEmpty) const SizedBox(width: 8),
                if (_vehicleTypes.isNotEmpty)
                  _dropdownChip<String>(
                    label: _selectedVehicleType ?? 'Vehicle',
                    isActive: _selectedVehicleType != null,
                    items: _vehicleTypes,
                    value: _selectedVehicleType,
                    onChanged: (v) {
                      setState(() => _selectedVehicleType = v);
                      _fetch();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// A toggle chip (e.g. "In Stock") that switches colour when active.
  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kPrimaryColor : kGrey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? kPrimaryColor : kGreyLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : kTextSecondary,
          ),
        ),
      ),
    );
  }

  /// A chip that shows the selected value and opens a picker bottom sheet
  /// when tapped. Tapping the same value a second time deselects it.
  Widget _dropdownChip<T>({
    required String label,
    required bool isActive,
    required List<T> items,
    required T? value,
    required ValueChanged<T?> onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<T>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _buildPickerSheet<T>(label, items, value),
        );
        if (result != null || value != null) {
          onChanged(result == value ? null : result);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryColor : kGrey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? kPrimaryColor : kGreyLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : kTextSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? Colors.white : kTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// The bottom sheet list used by _dropdownChip to pick a single value.
  Widget _buildPickerSheet<T>(String title, List<T> items, T? current) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (current != null)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Clear',
                        style: TextStyle(color: kTextSecondary)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              children: items
                  .map((item) => ListTile(
                        title: Text(item.toString()),
                        trailing: item == current
                            ? const Icon(Icons.check, color: kPrimaryColor)
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Shown when no products match the active filters or search query.
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Icon(Icons.search_off_rounded, size: 70, color: kGreyMedium.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No parts found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor)),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters',
              style: TextStyle(color: kTextSecondary)),
          if (_hasFilters || _searchController.text.isNotEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('CLEAR FILTERS'),
            ),
          ],
        ],
        ),
      ),
    );
  }

  /// Builds a single product card row with image, brand, name, price, and stock badge.
  Widget _buildCard(Map<String, dynamic> product) {
    final inStock = (product['available'] as int) > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kGreyLight),
      ),
      color: kSurfaceColor,
      child: InkWell(
        onTap: () => _openProduct(product['id'] as int),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'product_${product['id']}',
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: kGrey100,
                  ),
                  child: FutureBuilder<Uint8List?>(
                    future: DatabaseHelper.instance
                        .getProductImage(product['id'] as int),
                    builder: (_, snap) {
                      if (snap.connectionState == ConnectionState.done &&
                          snap.data != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              Image.memory(snap.data!, fit: BoxFit.cover),
                        );
                      }
                      return const Icon(Icons.image_outlined,
                          color: kGreyMedium, size: 24);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['brand']?.toUpperCase() ?? 'GENUINE',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kAccentColor,
                          letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['name'] ?? 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kSecondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product['vehicle_type'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product['vehicle_type'] as String,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OMR ${product['price']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: kPrimaryColor,
                              fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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
                              color:
                                  inStock ? kSuccessColor : kErrorColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
