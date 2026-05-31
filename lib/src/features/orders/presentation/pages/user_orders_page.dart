// ============================================================
// user_orders_page.dart — Customer Order History Screen
// ============================================================
// Shows the logged-in customer's orders split into two tabs:
//   • ACTIVE   — orders that are Pending, Ready, or In Delivery.
//   • COMPLETED — orders that are Delivered or Cancelled.
//
// Tapping any order card opens OrderDetailPage for full details.
// The TabController uses SingleTickerProviderStateMixin to drive
// the tab animation efficiently.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'order_detail_page.dart';

/// Displays the order history for the currently logged-in customer.
class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';
    if (username.isNotEmpty) {
      final allOrders = await DatabaseHelper.instance.getUserOrders(username);
      if (mounted) {
        setState(() {
          _pendingOrders = allOrders.where((order) => 
            order['status'] != 'Delivered' && order['status'] != 'Cancelled').toList();
          _completedOrders = allOrders.where((order) => 
            order['status'] == 'Delivered' || order['status'] == 'Cancelled').toList();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('PURCHASE HISTORY'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: kTextSecondary,
          indicatorColor: kPrimaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'ACTIVE'),
            Tab(text: 'COMPLETED'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_pendingOrders, 'No active orders'),
                _buildOrderList(_completedOrders, 'No past orders'),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String emptyMsg) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: kGreyMedium.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(color: kTextSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    Color statusColor = _getStatusColor(order['status']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kGreyLight),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderDetailPage(order: order)),
          ).then((_) => _loadOrders());
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order['id'].toString().padLeft(5, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order['order_date']?.split(' ')[0] ?? '',
                        style: const TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order['status'].toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(color: kTextSecondary)),
                  Text(
                    'OMR ${order['total_price']}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimaryColor, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: kGreyMedium),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tap for full tracking and item details',
                      style: TextStyle(color: kGreyMedium, fontSize: 11),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kGreyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return kWarningColor;
      case 'ready': return Colors.blue;
      case 'in delivery': return kAccentColor;
      case 'delivered': return kSuccessColor;
      case 'cancelled': return kErrorColor;
      default: return kSecondaryColor;
    }
  }
}
