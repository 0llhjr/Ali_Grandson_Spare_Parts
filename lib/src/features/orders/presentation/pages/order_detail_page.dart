// ============================================================
// order_detail_page.dart — Customer Order Details Screen
// ============================================================
// Shows all information about a single order for the customer:
//   • A coloured status banner (Pending=yellow, Delivered=green, etc.)
//   • Order summary card (date, payment mode, total, completion date)
//   • Delivery details card (address, phone, special instructions)
//   • A list of all individual items in the order
//
// The order map is passed from UserOrdersPage; item details are
// fetched from the database using the order's id.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

/// Read-only order details view for customers.
class OrderDetailPage extends StatefulWidget {
  /// The full order row map passed from the orders list screen.
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  List<Map<String, dynamic>> _orderItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
  }

  Future<void> _loadOrderItems() async {
    final items = await DatabaseHelper.instance.getOrderItems(widget.order['id'] as int);
    if (mounted) {
      setState(() {
        _orderItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('ORDER #${widget.order['id'].toString().padLeft(5, '0')}'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'Order Summary',
                    [
                      _buildDetailRow('Placed Date', widget.order['order_date']?.split('.')[0] ?? 'N/A'),
                      _buildDetailRow('Payment Mode', widget.order['payment_mode']),
                      _buildDetailRow('Final Amount', 'OMR ${widget.order['total_price']}', isHighlight: true),
                      if (widget.order['completion_date'] != null)
                        _buildDetailRow('Completed On', widget.order['completion_date']?.split('.')[0] ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Delivery Details',
                    [
                      _buildDetailRow('Recipient', widget.order['user_username']),
                      _buildDetailRow('Contact', widget.order['phone']),
                      _buildDetailRow('Address', widget.order['address']),
                      if (widget.order['special_instructions'] != null && (widget.order['special_instructions'] as String).isNotEmpty)
                        _buildDetailRow('Note', widget.order['special_instructions']),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ORDERED ITEMS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kSecondaryColor, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  ..._orderItems.map((item) => _buildItemTile(item)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner() {
    Color statusColor = _getStatusColor(widget.order['status']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: statusColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Status', style: TextStyle(fontSize: 12, color: kTextSecondary)),
              Text(
                widget.order['status'].toUpperCase(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGreyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kSecondaryColor)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 14)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
                color: isHighlight ? kPrimaryColor : kSecondaryColor,
                fontSize: isHighlight ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreyLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.settings_suggest_outlined, color: kPrimaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['product_name'] ?? 'Unknown Part', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Quantity: ${item['quantity']}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            'OMR ${item['price']}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
        ],
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
