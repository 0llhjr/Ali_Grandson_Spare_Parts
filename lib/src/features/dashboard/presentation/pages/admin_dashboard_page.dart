// ============================================================
// admin_dashboard_page.dart — Admin Main Dashboard Screen
// ============================================================
// The home screen for the admin after login.  It provides a
// high-level overview of the store at a glance:
//
//   Revenue card  — current month and all-time revenue.
//   Stats grid    — 6 tappable tiles: users, products,
//                   pending orders, completed orders,
//                   out-of-stock items, low-stock items.
//   Quick actions — shortcuts to add a new product and manage FAQs.
//
// All numbers are loaded fresh from the database in
// _loadDashboardData(), which is also called when returning from
// any sub-screen (via .then(() => _loadDashboardData())).
//
// A side drawer gives quick navigation to all admin sections.
// The logout button clears the session and returns to HomePage.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/manage_products_page.dart';
import 'package:alis_grandson_app/src/features/profile/presentation/pages/manage_users_page.dart';
import 'package:alis_grandson_app/src/features/orders/presentation/pages/manage_orders_page.dart';
import 'package:alis_grandson_app/src/features/support/presentation/pages/manage_faqs_page.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/catalog/presentation/pages/add_product_page.dart';
import 'package:alis_grandson_app/src/features/analytics/presentation/pages/revenue_analytics_page.dart';
import 'package:alis_grandson_app/src/features/home/presentation/pages/home_page.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';

/// Admin home screen showing store statistics and quick navigation.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _userCount = 0;
  int _productCount = 0;
  int _outOfStockCount = 0;
  int _lowStockCount = 0;
  int _pendingOrderCount = 0;
  int _completedOrderCount = 0;
  double _totalRevenue = 0.0;
  double _monthRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Fetches all eight dashboard statistics from the database in sequence
  /// and updates the state variables so the UI rebuilds with fresh numbers.
  Future<void> _loadDashboardData() async {
    final db = DatabaseHelper.instance;
    final userCount = await db.getUsersCount();
    final productCount = await db.getProductsCount();
    final outOfStockCount = await db.getOutOfStockCount();
    final lowStockCount = await db.getLowStockCount();
    final pendingCount = await db.getPendingOrdersCount();
    final completedCount = await db.getCompletedOrdersCount();
    final totalRevenue = await db.getTotalRevenue();
    final monthRevenue = await db.getCurrentMonthRevenue();

    if (mounted) {
      setState(() {
        _userCount = userCount;
        _productCount = productCount;
        _outOfStockCount = outOfStockCount;
        _lowStockCount = lowStockCount;
        _pendingOrderCount = pendingCount;
        _completedOrderCount = completedCount;
        _totalRevenue = totalRevenue;
        _monthRevenue = monthRevenue;
      });
    }
  }

  /// Clears the saved admin session and returns to the landing (home) page.
  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('ADMIN CONSOLE'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: kErrorColor),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: kPrimaryColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRevenueCard(),
              const SizedBox(height: 24),
              const Text(
                'Store Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kSecondaryColor),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  _buildStatCard('Total Users', _userCount.toString(), Icons.people_alt_rounded, kSecondaryColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageUsersPage())).then((_) => _loadDashboardData());
                  }),
                  _buildStatCard('Products', _productCount.toString(), Icons.inventory_2_rounded, kPrimaryColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageProductsPage())).then((_) => _loadDashboardData());
                  }),
                  _buildStatCard('Pending Orders', _pendingOrderCount.toString(), Icons.shopping_cart_rounded, kAccentColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageOrdersPage(filter: 'pending'))).then((_) => _loadDashboardData());
                  }),
                  _buildStatCard('Completed Orders', _completedOrderCount.toString(), Icons.task_alt_rounded, kSuccessColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageOrdersPage(filter: 'completed'))).then((_) => _loadDashboardData());
                  }),
                  _buildStatCard('Out of Stock', _outOfStockCount.toString(), Icons.warning_rounded, kErrorColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageProductsPage(filter: 'out_of_stock'))).then((_) => _loadDashboardData());
                  }),
                  _buildStatCard('Low Stock', _lowStockCount.toString(), Icons.hourglass_bottom_rounded, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageProductsPage(filter: 'low_stock'))).then((_) => _loadDashboardData());
                  }),
                ],
              ),
              const SizedBox(height: 24),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  /// The large maroon gradient card at the top showing this month's
  /// revenue and an all-time total. Tapping it opens the analytics screen.
  Widget _buildRevenueCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RevenueAnalyticsPage()),
        ).then((_) => _loadDashboardData());
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kPrimaryDark, kPrimaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Month Revenue',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Icon(Icons.analytics_outlined, color: Colors.white.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'OMR ${_monthRevenue.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: OMR ${_totalRevenue.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// One stat tile in the 2-column grid (e.g. "Total Users: 12").
  /// Tapping it navigates to the relevant management screen.
  /// [subtitle] shows an optional additional note below the value.
  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap, {String? subtitle}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kGreyLight, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: kTextSecondary, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The "Quick Actions" section below the stats grid — shortcuts
  /// to add a product and manage support FAQs.
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kSecondaryColor),
        ),
        const SizedBox(height: 16),
        _buildActionTile(Icons.add_box_rounded, 'Add New Product', 'Expand your catalog', kPrimaryColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage())).then((_) => _loadDashboardData());
        }),
        _buildActionTile(Icons.help_center_rounded, 'Manage Support', 'Update FAQs & help text', kSecondaryColor, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageFAQsPage()));
        }),
      ],
    );
  }

  /// A card-style list tile used in the Quick Actions section.
  Widget _buildActionTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kGreyLight)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// The side navigation drawer listing all admin sections.
  Widget _buildAdminDrawer() {
    return Drawer(
      backgroundColor: kSurfaceColor,
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: kPrimaryColor),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'CONTROL PANEL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerTile(Icons.dashboard_rounded, 'Dashboard', () => Navigator.pop(context)),
          _buildDrawerTile(Icons.people_rounded, 'User Management', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageUsersPage()));
          }),
          _buildDrawerTile(Icons.shopping_bag_rounded, 'Product Inventory', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageProductsPage()));
          }),
          _buildDrawerTile(Icons.receipt_long_rounded, 'Orders & Sales', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageOrdersPage()));
          }),
          _buildDrawerTile(Icons.support_agent_rounded, 'Support Content', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageFAQsPage()));
          }),
          const Spacer(),
          const Divider(),
          _buildDrawerTile(Icons.logout_rounded, 'Sign Out', _logout, isDestructive: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// One list item in the drawer. [isDestructive] makes it red (used for Sign Out).
  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? kErrorColor : kSecondaryColor),
      title: Text(title, style: TextStyle(color: isDestructive ? kErrorColor : kSecondaryColor, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
