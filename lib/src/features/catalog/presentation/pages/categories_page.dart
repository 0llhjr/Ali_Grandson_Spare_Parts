// ============================================================
// categories_page.dart — All Categories Grid Screen
// ============================================================
// Shows every product category in a 2-column grid.
// Each card displays:
//   • A circular icon (from the category's stored icon name).
//   • The category name.
//   • The number of products in that category (as a badge).
//
// Tapping a card opens CategoryProductsPage which lists all
// products belonging to that category.
//
// Product counts are fetched with getProductCountsByCategory()
// which returns a Map<categoryId, count> in one DB call.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/category_products_page.dart';

/// Full-page category browser shown when the user taps "See All" on the dashboard.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  // All category records from the database.
  List<Map<String, dynamic>> _categories = [];

  // Maps category id → product count (e.g. {1: 7, 2: 7, 3: 6, ...}).
  Map<int, int> _counts = {};

  // True while waiting for database queries.
  bool _isLoading = true;

  // Converts the text icon name stored in the database to a Flutter IconData.
  static const _iconMap = <String, IconData>{
    'settings': Icons.settings,
    'emergency_share': Icons.emergency_share,
    'filter_alt': Icons.filter_alt,
    'bolt': Icons.bolt,
    'tune': Icons.tune,
    'directions_car': Icons.directions_car,
    'swap_horiz': Icons.swap_horiz,
    'ac_unit': Icons.ac_unit,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads categories and their product counts from the database.
  Future<void> _load() async {
    final cats = await DatabaseHelper.instance.getCategories();
    // getProductCountsByCategory() returns one Map with all counts — more
    // efficient than querying each category separately.
    final counts = await DatabaseHelper.instance.getProductCountsByCategory();
    if (mounted) {
      setState(() {
        _categories = cats;
        _counts = counts;
        _isLoading = false;
      });
    }
  }

  /// Opens the product list for the tapped category.
  void _openCategory(Map<String, dynamic> cat) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CategoryProductsPage(
        categoryId: cat['id'] as int,
        categoryName: cat['name'] as String,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('ALL CATEGORIES'),
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
          : _categories.isEmpty
              ? const Center(child: Text('No categories found.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) => _buildCard(_categories[i]),
                ),
    );
  }

  /// Renders one category tile with icon, name, and product-count badge.
  Widget _buildCard(Map<String, dynamic> cat) {
    final id = cat['id'] as int;
    final name = cat['name'] as String;
    final iconKey = cat['icon'] as String? ?? 'category';
    final icon = _iconMap[iconKey] ?? Icons.category;
    final count = _counts[id] ?? 0;

    return GestureDetector(
      onTap: () => _openCategory(cat),
      child: Container(
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGreyLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: kPrimaryColor, size: 28),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kAccentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: kSecondaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? 'part' : 'parts'}',
                style: const TextStyle(fontSize: 11, color: kTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
