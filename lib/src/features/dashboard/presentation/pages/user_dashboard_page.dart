// ============================================================
// user_dashboard_page.dart — Customer Home Screen
// ============================================================
// The main screen customers see after logging in.  It contains:
//
//   Fixed maroon header — greeting, warehouse selector, search bar.
//   Banner carousel     — auto-sliding promotional images.
//   Categories row      — horizontal scrollable category chips.
//   Products list       — all in-stock products (filtered by warehouse
//                         and search keyword).
//   Bottom navigation   — Home, Wishlist, Cart, Chat, Menu (Misc hub).
//
// Data is refreshed every time the user returns from another screen
// so cart counts and stock levels stay current.
//
// A separate private _WishlistHeart widget (at the bottom of this
// file) manages its own wishlist toggle state independently for each
// product card — this avoids rebuilding the whole list when one
// heart is tapped.
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/widgets/banner_carousel.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/user_view_product_page.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/categories_page.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/category_products_page.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/search_filter_page.dart';
import 'package:alis_grandson_app/src/features/cart/presentation/pages/cart_page.dart';
import 'package:alis_grandson_app/src/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:alis_grandson_app/src/features/support/presentation/pages/faq_page.dart';
import 'package:alis_grandson_app/src/features/misc/presentation/pages/misc_page.dart';

/// The main shopping home screen shown to logged-in customers.
class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  // Controller for the search text field in the header.
  final TextEditingController _searchController = TextEditingController();

  // The list of products currently displayed (may be filtered/searched).
  List<Map<String, dynamic>> _products = [];

  // All product categories (Engine Parts, Brakes, Filters, etc.).
  List<Map<String, dynamic>> _categories = [];

  // All warehouse locations fetched from the database.
  List<Map<String, dynamic>> _warehouses = [];

  // True while we are waiting for database queries to finish.
  bool _isLoading = true;

  // The name shown in the greeting ("Hello, John").
  String _displayName = '';

  // Number shown on the cart badge in the header and bottom bar.
  int _cartItemCount = 0;

  // The currently logged-in customer's username (from SharedPreferences).
  String _username = '';

  // The warehouse id the user has chosen to filter by (null = all).
  int? _selectedWarehouseId;

  // The display name for the selected warehouse (shown in the header).
  String _selectedWarehouseName = 'All Warehouses';

  @override
  void initState() {
    super.initState();
    // Load everything the dashboard needs as soon as the screen opens.
    _loadDashboardData();
  }

  @override
  void dispose() {
    // Always dispose controllers to free memory when the widget is destroyed.
    _searchController.dispose();
    super.dispose();
  }

  /// Reads the saved session, fetches the user's name and warehouse
  /// preference, then loads categories, products, and the cart count
  /// all at the same time using Future.wait (parallel execution).
  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('user_username') ?? '';
    _selectedWarehouseId = prefs.getInt('selected_warehouse_id');

    // Fetch the user record only if a username exists.
    final user = _username.isNotEmpty
        ? await DatabaseHelper.instance.getUserByUsername(_username)
        : null;
    final warehouses = await DatabaseHelper.instance.getWarehouses();

    if (mounted) {
      // Find the stored warehouse name, or fall back to "All Warehouses".
      final warehouseName = _selectedWarehouseId != null
          ? warehouses
              .firstWhere(
                (w) => w['id'] == _selectedWarehouseId,
                orElse: () => {'name': 'All Warehouses'},
              )['name'] as String
          : 'All Warehouses';
      setState(() {
        // Show full name if available, otherwise fall back to username.
        _displayName =
            (user != null && (user['name'] as String?)?.isNotEmpty == true)
                ? user['name']
                : _username;
        _warehouses = warehouses;
        _selectedWarehouseName = warehouseName;
      });
    }
    // Load these three things in parallel — all start at the same moment.
    await Future.wait([_loadCategories(), _loadProducts(), _loadCartCount()]);
  }

  /// Fetches all product categories from the database.
  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  /// Counts how many unique items are in the user's cart and
  /// updates the badge number on the cart icon.
  Future<void> _loadCartCount() async {
    if (_username.isEmpty) return;
    final items = await DatabaseHelper.instance.getCartItems(_username);
    if (mounted) setState(() => _cartItemCount = items.length);
  }

  /// Loads the full product list (filtered by warehouse if one is selected).
  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final products = await DatabaseHelper.instance
        .getProducts(warehouseId: _selectedWarehouseId);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  /// Called every time the user types in the search bar.
  /// Runs a keyword search if [keyword] is non-empty, or reloads all
  /// products if the search bar is cleared.
  Future<void> _searchProducts(String keyword) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final products = keyword.isEmpty
        ? await DatabaseHelper.instance
            .getProducts(warehouseId: _selectedWarehouseId)
        : await DatabaseHelper.instance
            .searchProducts(keyword, warehouseId: _selectedWarehouseId);
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  /// Saves the chosen warehouse to SharedPreferences so the choice
  /// persists across app restarts, then reloads the product list.
  Future<void> _selectWarehouse(int? warehouseId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    if (warehouseId == null) {
      await prefs.remove('selected_warehouse_id');
    } else {
      await prefs.setInt('selected_warehouse_id', warehouseId);
    }
    setState(() {
      _selectedWarehouseId = warehouseId;
      _selectedWarehouseName = name;
    });
    _loadProducts();
  }

  /// Opens a bottom sheet listing all warehouses so the user
  /// can switch the stock source they are browsing.
  void _showWarehouseSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kGreyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Warehouse',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kSecondaryColor)),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.store_rounded, color: kPrimaryColor),
            title: const Text('All Warehouses'),
            trailing: _selectedWarehouseId == null
                ? const Icon(Icons.check, color: kPrimaryColor)
                : null,
            onTap: () {
              Navigator.pop(context);
              _selectWarehouse(null, 'All Warehouses');
            },
          ),
          ..._warehouses.map((w) => ListTile(
                leading:
                    const Icon(Icons.warehouse_rounded, color: kAccentColor),
                title: Text(w['name'] as String),
                subtitle: w['location'] != null
                    ? Text(w['location'] as String,
                        style: const TextStyle(fontSize: 12))
                    : null,
                trailing: _selectedWarehouseId == w['id']
                    ? const Icon(Icons.check, color: kPrimaryColor)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _selectWarehouse(w['id'] as int, w['name'] as String);
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Pushes CategoryProductsPage for the tapped category.
  void _openCategoryPage(Map<String, dynamic> cat) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CategoryProductsPage(
        categoryId: cat['id'] as int,
        categoryName: cat['name'] as String,
      ),
    ));
  }

  /// Opens the advanced search & filter screen.
  /// Any text already typed in the search bar is passed as the initial query.
  void _openSearchFilter() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SearchFilterPage(
        initialQuery: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      ),
    ));
  }

  /// Navigates to a product's detail page with a fade animation.
  /// Refreshes the product list and cart count when returning.
  void _navigateToProduct(int productId) {
    Navigator.of(context)
        .push(PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, animation, __) =>
              UserViewProductPage(productId: productId),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ))
        .then((_) {
      _loadProducts();
      _loadCartCount();
    });
  }

  /// Generic helper to push any page and refresh the cart count on return.
  void _navigateTo(Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) => _loadCartCount());
  }

  /// Converts the category's stored icon string (e.g. "bolt") to a
  /// Flutter IconData object. Falls back to a generic category icon.
  static IconData _categoryIcon(String name) {
    const map = {
      'settings': Icons.settings_rounded,
      'emergency_share': Icons.emergency_rounded,
      'filter_alt': Icons.filter_alt_rounded,
      'bolt': Icons.bolt_rounded,
      'tune': Icons.tune_rounded,
      'directions_car': Icons.directions_car_rounded,
      'swap_horiz': Icons.swap_horiz_rounded,
      'ac_unit': Icons.ac_unit_rounded,
    };
    return map[name] ?? Icons.category_rounded;
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: kPrimaryColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildBannerSection(),
                        const SizedBox(height: 28),
                        _buildCategoriesSection(),
                        const SizedBox(height: 28),
                        _buildProductsSectionHeader(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()))
                  else if (_products.isEmpty)
                    const SliverFillRemaining(
                        child: Center(child: Text('No products found.')))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _buildProductCard(_products[i]),
                          childCount: _products.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Fixed maroon header ──────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: kPrimaryColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warehouse selector row
              GestureDetector(
                onTap: _showWarehouseSheet,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: kAccentColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _selectedWarehouseName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Greeting + cart
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $_displayName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Find the right spare part',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _buildCartBadge(),
                ],
              ),
              const SizedBox(height: 12),
              // Search bar + filter button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                            fontSize: 14, color: kSecondaryColor, height: 1),
                        decoration: InputDecoration(
                          hintText: 'Search parts, brands...',
                          hintStyle: const TextStyle(
                              color: kGreyMedium, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: kPrimaryColor, size: 22),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18, color: kGreyMedium),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadProducts();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: const BorderSide(
                                color: kAccentColor, width: 2),
                          ),
                        ),
                        onChanged: _searchProducts,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter button
                  GestureDetector(
                    onTap: _openSearchFilter,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartBadge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined,
              color: Colors.white, size: 28),
          onPressed: () => _navigateTo(const CartPage()),
        ),
        if (_cartItemCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: kAccentColor, shape: BoxShape.circle),
              constraints:
                  const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$_cartItemCount',
                style: const TextStyle(
                    color: kPrimaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ── Banner section ───────────────────────────────────────────

  Widget _buildBannerSection() {
    return const BannerCarousel();
  }

  // ── Categories horizontal scroll ─────────────────────────────

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Category',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesPage()),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                      fontSize: 13,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_categories.isEmpty)
          const SizedBox(height: 90)
        else
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (_, i) => _buildCategoryCircle(_categories[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCircle(Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () => _openCategoryPage(cat),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _categoryIcon(cat['icon'] ?? 'category'),
                color: kPrimaryColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cat['name'] ?? '',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: kSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Products section header ───────────────────────────────────

  Widget _buildProductsSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'All Products',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kSecondaryColor),
          ),
          Text(
            '${_products.length} items',
            style: const TextStyle(fontSize: 13, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  // ── Product card ─────────────────────────────────────────────

  Widget _buildProductCard(Map<String, dynamic> product) {
    final inStock = (product['available'] as int) > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kGreyLight, width: 1),
      ),
      color: kSurfaceColor,
      child: InkWell(
        onTap: () => _navigateToProduct(product['id'] as int),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image with wishlist heart overlay
              Stack(
                children: [
                  Hero(
                    tag: 'product_${product['id']}',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: kGrey100,
                      ),
                      child: FutureBuilder<Uint8List?>(
                        future: DatabaseHelper.instance
                            .getProductImage(product['id'] as int),
                        builder: (_, snap) {
                          if (snap.connectionState == ConnectionState.done &&
                              snap.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(snap.data!,
                                  fit: BoxFit.cover),
                            );
                          }
                          return const Icon(Icons.image_outlined,
                              color: kGreyMedium, size: 28);
                        },
                      ),
                    ),
                  ),
                  // Wishlist heart button on card
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _WishlistHeart(
                      productId: product['id'] as int,
                      username: _username,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Product info
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
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['name'] ?? 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kSecondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['model'] ?? '',
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
                          'OMR ${product['price']}',
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom navigation bar ────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, Icons.home_outlined, 'Home',
                  isActive: true, onTap: () {}),
              _navItem(Icons.favorite_rounded, Icons.favorite_outline_rounded,
                  'Wishlist',
                  onTap: () => _navigateTo(const WishlistPage())),
              _navItem(Icons.shopping_bag_rounded,
                  Icons.shopping_bag_outlined, 'Cart',
                  badge: _cartItemCount,
                  onTap: () => _navigateTo(const CartPage())),
              _navItem(Icons.chat_bubble_rounded,
                  Icons.chat_bubble_outline_rounded, 'Chat',
                  onTap: () => _navigateTo(const FAQPage())),
              // Misc opens a hub page with Profile, Orders, Wishlist, Cart, Chat, and Sign Out.
              _navItem(Icons.grid_view_rounded, Icons.grid_view_outlined,
                  'Menu',
                  onTap: () => _navigateTo(const MiscPage())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label, {
    bool isActive = false,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? kPrimaryColor : kGreyMedium,
                  size: 26,
                ),
                if (badge > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: kAccentColor, shape: BoxShape.circle),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                            color: kPrimaryDark,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? kPrimaryColor : kGreyMedium,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wishlist heart widget (stateful, self-contained) ─────────
// This is a small private widget that lives on each product card.
// It is separate from the main page so that tapping the heart
// only rebuilds this tiny widget — not the entire product list.

class _WishlistHeart extends StatefulWidget {
  final int productId;
  final String username;
  const _WishlistHeart({required this.productId, required this.username});

  @override
  State<_WishlistHeart> createState() => _WishlistHeartState();
}

class _WishlistHeartState extends State<_WishlistHeart> {
  // Whether this product is currently in the user's wishlist.
  bool _inWishlist = false;

  @override
  void initState() {
    super.initState();
    // Check the wishlist status from the database as soon as the heart renders.
    _check();
  }

  /// Asks the database whether this product is already wishlisted.
  Future<void> _check() async {
    if (widget.username.isEmpty) return;
    final result = await DatabaseHelper.instance
        .isInWishlist(widget.username, widget.productId);
    if (mounted) setState(() => _inWishlist = result);
  }

  /// Adds to or removes from the wishlist depending on current state.
  Future<void> _toggle() async {
    if (widget.username.isEmpty) return;
    if (_inWishlist) {
      await DatabaseHelper.instance
          .removeFromWishlist(widget.username, widget.productId);
    } else {
      await DatabaseHelper.instance
          .addToWishlist(widget.username, widget.productId);
    }
    // Flip the local state immediately so the icon changes without another DB read.
    if (mounted) setState(() => _inWishlist = !_inWishlist);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _inWishlist ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          color: _inWishlist ? kPrimaryColor : kGreyMedium,
          size: 16,
        ),
      ),
    );
  }
}
