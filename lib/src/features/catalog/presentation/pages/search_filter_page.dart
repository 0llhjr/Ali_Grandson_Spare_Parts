// ============================================================
// search_filter_page.dart — Advanced Search & Filter Screen
// ============================================================
// A full-screen search page that combines free-text search with
// multiple simultaneous filter options:
//
//   Search bar    — keyword match on name, description, brand.
//   Category chips — filter by a specific product category.
//   Brand chips    — filter by brand (Bosch, Toyota, NGK, etc.).
//   Vehicle chips  — filter by vehicle type (Sedan, SUV, etc.).
//   Price slider   — set a minimum and/or maximum price.
//   In Stock Only  — toggle switch to hide unavailable products.
//
// All filters re-query the database every time a value changes.
// The "Reset" button in the app bar clears everything at once.
//
// An optional [initialQuery] can be passed from the dashboard's
// search bar so the user's typed text carries over.
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/user_view_product_page.dart';

/// Full-screen search and multi-filter page for the product catalogue.
class SearchFilterPage extends StatefulWidget {
  /// Pre-fill the search bar with this text when the page opens.
  final String? initialQuery;

  const SearchFilterPage({super.key, this.initialQuery});

  @override
  State<SearchFilterPage> createState() => _SearchFilterPageState();
}

class _SearchFilterPageState extends State<SearchFilterPage> {
  // Text field controller for the keyword search bar.
  final _searchController = TextEditingController();

  // Products matching all active filters (shown in the results list).
  List<Map<String, dynamic>> _products = [];

  // All categories for the category chip row.
  List<Map<String, dynamic>> _categories = [];

  // All distinct brand names for the brand chip row.
  List<String> _brands = [];

  // All distinct vehicle types for the vehicle chip row.
  List<String> _vehicleTypes = [];

  // True while a DB query is running (shows a spinner in the results area).
  bool _isLoading = false;

  // False until the first _init() call completes; prevents showing
  // the filter panel before the options are loaded.
  bool _initialized = false;

  // Warehouse preference from SharedPreferences (null = all warehouses).
  int? _warehouseId;

  // The highest price in the catalogue — used as the slider's max value.
  double _maxPrice = 500;

  // ── Active filter values ─────────────────────────────────────
  int? _selectedCategoryId;     // null = all categories
  String? _selectedBrand;       // null = all brands
  String? _selectedVehicleType; // null = all vehicle types
  bool _inStockOnly = false;    // false = show all (in and out of stock)
  RangeValues _priceRange = const RangeValues(0, 500); // full range by default

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Reads the saved warehouse, fetches all filter options from the DB,
  /// sets the price slider max to the most expensive product, then fetches
  /// the initial product list.
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _warehouseId = prefs.getInt('selected_warehouse_id');
    final cats = await DatabaseHelper.instance.getCategories();
    final brands = await DatabaseHelper.instance.getDistinctBrands();
    final types = await DatabaseHelper.instance.getDistinctVehicleTypes();
    final maxPrice = await DatabaseHelper.instance.getMaxProductPrice();
    // Guard against a zero maxPrice (e.g. empty catalogue) so the slider works.
    final resolvedMax = maxPrice > 0 ? maxPrice : 500.0;
    setState(() {
      _categories = cats;
      _brands = brands;
      _vehicleTypes = types;
      _maxPrice = resolvedMax;
      _priceRange = RangeValues(0, resolvedMax);
      _initialized = true;
    });
    await _fetch();
  }

  /// Runs a search or a plain getProducts() call with all active filters.
  /// minPrice and maxPrice are only sent to the DB when they are
  /// non-default (i.e. the slider has been moved from its edges).
  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final keyword = _searchController.text.trim();
    List<Map<String, dynamic>> results;
    if (keyword.isEmpty) {
      results = await DatabaseHelper.instance.getProducts(
        categoryId: _selectedCategoryId,
        warehouseId: _warehouseId,
        brand: _selectedBrand,
        vehicleType: _selectedVehicleType,
        minPrice: _priceRange.start > 0 ? _priceRange.start : null,
        maxPrice: _priceRange.end < _maxPrice ? _priceRange.end : null,
        inStockOnly: _inStockOnly,
      );
    } else {
      results = await DatabaseHelper.instance.searchProducts(
        keyword,
        categoryId: _selectedCategoryId,
        warehouseId: _warehouseId,
        brand: _selectedBrand,
        vehicleType: _selectedVehicleType,
        minPrice: _priceRange.start > 0 ? _priceRange.start : null,
        maxPrice: _priceRange.end < _maxPrice ? _priceRange.end : null,
        inStockOnly: _inStockOnly,
      );
    }
    if (mounted) setState(() {
      _products = results;
      _isLoading = false;
    });
  }

  /// Resets every filter and the search bar back to their defaults.
  void _clearAll() {
    setState(() {
      _searchController.clear();
      _selectedCategoryId = null;
      _selectedBrand = null;
      _selectedVehicleType = null;
      _inStockOnly = false;
      _priceRange = RangeValues(0, _maxPrice);
    });
    _fetch();
  }

  /// True when at least one filter differs from its default value.
  /// Controls the visibility of the "Reset" button in the app bar.
  bool get _hasActiveFilters =>
      _selectedCategoryId != null ||
      _selectedBrand != null ||
      _selectedVehicleType != null ||
      _inStockOnly ||
      _priceRange.start > 0 ||
      _priceRange.end < _maxPrice;

  /// Navigates to the product detail page with a fade animation.
  void _openProduct(int productId) {
    Navigator.of(context)
        .push(PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, animation, __) =>
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
        title: const Text('SEARCH & FILTER'),
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
        actions: [
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Reset', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildFiltersPanel()),
                SliverToBoxAdapter(child: _buildResultsHeader()),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildCard(_products[i]),
                        childCount: _products.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  /// The white panel at the top of the screen containing search + all filter chips.
  Widget _buildFiltersPanel() {
    return Container(
      color: kSurfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchController,
              autofocus: widget.initialQuery == null,
              onChanged: (_) => _fetch(),
              decoration: InputDecoration(
                hintText: 'Search spare parts...',
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
          ),

          // Category chips
          if (_categories.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Text('Category',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kTextSecondary,
                      letterSpacing: 0.8)),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final id = cat['id'] as int;
                  final active = _selectedCategoryId == id;
                  return _chip(
                    cat['name'] as String,
                    active,
                    () {
                      setState(() => _selectedCategoryId =
                          active ? null : id);
                      _fetch();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Brand chips
          if (_brands.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Text('Brand',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kTextSecondary,
                      letterSpacing: 0.8)),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _brands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final brand = _brands[i];
                  final active = _selectedBrand == brand;
                  return _chip(brand, active, () {
                    setState(() =>
                        _selectedBrand = active ? null : brand);
                    _fetch();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Vehicle type chips
          if (_vehicleTypes.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Text('Vehicle Type',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kTextSecondary,
                      letterSpacing: 0.8)),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _vehicleTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final vt = _vehicleTypes[i];
                  final active = _selectedVehicleType == vt;
                  return _chip(vt, active, () {
                    setState(() =>
                        _selectedVehicleType = active ? null : vt);
                    _fetch();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Price range
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price (OMR)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kTextSecondary,
                        letterSpacing: 0.8)),
                Text(
                  '${_priceRange.start.toStringAsFixed(2)} – ${_priceRange.end.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor),
                ),
              ],
            ),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: _maxPrice,
            activeColor: kPrimaryColor,
            inactiveColor: kGreyLight,
            onChanged: (v) => setState(() => _priceRange = v),
            onChangeEnd: (_) => _fetch(),
          ),

          // In-stock toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('In Stock Only',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kSecondaryColor)),
                Switch(
                  value: _inStockOnly,
                  activeColor: kPrimaryColor,
                  onChanged: (v) {
                    setState(() => _inStockOnly = v);
                    _fetch();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A simple toggle chip — maroon when active, grey when inactive.
  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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

  /// Shows the result count ("5 results") between the filter panel and the list.
  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            _isLoading
                ? 'Searching...'
                : '${_products.length} ${_products.length == 1 ? 'result' : 'results'}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: kSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 70, color: kGreyMedium.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No parts found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor)),
            const SizedBox(height: 8),
            const Text('Try a different search or clear some filters',
                style: TextStyle(color: kTextSecondary),
                textAlign: TextAlign.center),
            if (_hasActiveFilters || _searchController.text.isNotEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _clearAll,
                child: const Text('CLEAR ALL'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> product) {
    final inStock = (product['available'] as int) > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  width: 80,
                  height: 80,
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
                          child: Image.memory(snap.data!, fit: BoxFit.cover),
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
                    const SizedBox(height: 3),
                    Text(
                      product['name'] ?? 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OMR ${product['price']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: kPrimaryColor,
                              fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
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
            ],
          ),
        ),
      ),
    );
  }
}
