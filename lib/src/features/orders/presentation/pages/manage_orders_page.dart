// ============================================================
// manage_orders_page.dart — Admin Orders List Screen
// ============================================================
// Lists all customer orders for the admin to review and manage.
// An optional [filter] can be passed to show only:
//   'pending'   — orders not yet delivered or cancelled
//   'completed' — orders marked as Delivered
//   null        — all orders
//
// Tapping an order opens AdminOrderDetailPage where the admin
// can update the fulfilment status and send notifications.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/orders/presentation/pages/admin_order_detail_page.dart';

/// Admin screen listing all orders, optionally filtered by status.
class ManageOrdersPage extends StatefulWidget {
  /// Optional filter: 'pending', 'completed', or null for all orders.
  final String? filter;
  const ManageOrdersPage({super.key, this.filter});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final orders = await DatabaseHelper.instance.getAllOrders(filter: widget.filter);
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Manage Orders';
    if (widget.filter == 'pending') title = 'Pending Orders';
    if (widget.filter == 'completed') title = 'Completed Orders';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders found.'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Order #${order['id']} - ${order['user_username']}'),
                        subtitle: Text('Total: OMR ${order['total_price']} - Status: ${order['status']}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminOrderDetailPage(order: order),
                            ),
                          ).then((_) => _loadOrders());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
