// ============================================================
// admin_order_detail_page.dart — Admin Order Management Screen
// ============================================================
// Allows the admin to:
//   • View all details of a single order (customer, address, items).
//   • Change the fulfilment status via a dropdown:
//       Pending → Ready → In Delivery → Delivered / Cancelled
//   • Cancellation requires a reason which is emailed to the customer.
//   • Any status change triggers an email notification to the customer.
//
// The status change, database update, and email sending all happen
// in _processStatusUpdate() which is called after the admin
// selects a new value or confirms the cancellation dialog.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/shared/services/email_service.dart';
import 'package:alis_grandson_app/src/shared/utils/email_templates.dart';

/// Admin screen for viewing and updating a single order's status.
class AdminOrderDetailPage extends StatefulWidget {
  /// The full order row map passed from the orders list screen.
  final Map<String, dynamic> order;

  const AdminOrderDetailPage({super.key, required this.order});

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  List<Map<String, dynamic>> _orderItems = [];
  bool _isLoading = true;
  late String _selectedStatus;
  final List<String> _statuses = ['Pending', 'Ready', 'In Delivery', 'Delivered', 'Cancelled'];
  final EmailService _emailService = EmailService();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order['status'];
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

  Future<void> _updateStatus(String? newStatus) async {
    if (newStatus == null) return;

    if (newStatus == 'Cancelled') {
      _showCancellationDialog();
      return;
    }

    await _processStatusUpdate(newStatus);
  }

  Future<void> _processStatusUpdate(String newStatus, {String? reason}) async {
    setState(() => _isLoading = true);
    await DatabaseHelper.instance.updateOrderStatus(widget.order['id'] as int, newStatus);
    
    // Notify Customer via Email
    final user = await DatabaseHelper.instance.getUserByUsername(widget.order['user_username']);
    if (user != null && user['email'] != null) {
      String htmlBody;
      String subject;

      if (newStatus == 'Cancelled') {
        subject = 'Order Cancelled - #${widget.order['id']}';
        htmlBody = await EmailTemplates.orderCancelled(user['name'] ?? user['username'], widget.order['id'].toString(), reason ?? 'No reason provided');
      } else if (newStatus == 'Delivered') {
        subject = 'Order Delivered - #${widget.order['id']}';
        htmlBody = await EmailTemplates.orderDelivered(user['name'] ?? user['username'], widget.order['id'].toString());
      } else {
        subject = 'Order Status Updated - #${widget.order['id']}';
        htmlBody = await EmailTemplates.orderStatusChanged(user['name'] ?? user['username'], widget.order['id'].toString(), newStatus);
      }

      await _emailService.sendGoogleEmail(
        recipientEmails: user['email'],
        subject: subject,
        htmlBody: htmlBody,
      );
    }

    setState(() {
      _selectedStatus = newStatus;
      _isLoading = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order status updated and customer notified.'),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCancellationDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation. This will be sent to the customer.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'Reason for cancellation'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processStatusUpdate('Cancelled', reason: reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('CANCEL ORDER'),
          ),
        ],
      ),
    );
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
                  _buildStatusControlCard(),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'Customer & Delivery',
                    [
                      _buildDetailRow('Customer ID', widget.order['user_username']),
                      _buildDetailRow('Phone', widget.order['phone']),
                      _buildDetailRow('Address', widget.order['address']),
                      if (widget.order['special_instructions'] != null && (widget.order['special_instructions'] as String).isNotEmpty)
                        _buildDetailRow('Instructions', widget.order['special_instructions']),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Financial Summary',
                    [
                      _buildDetailRow('Placed On', widget.order['order_date']?.split('.')[0] ?? 'N/A'),
                      _buildDetailRow('Payment', widget.order['payment_mode']),
                      _buildDetailRow('Total Revenue', 'OMR ${widget.order['total_price']}', isHighlight: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'MANIFEST ITEMS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextSecondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  ..._orderItems.map((item) => _buildItemTile(item)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusControlCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Update Fullfillment Status', style: TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: kGreyLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreyMedium.withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryColor),
                items: _statuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status, style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: _updateStatus,
              ),
            ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13))),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
                color: isHighlight ? kPrimaryColor : kSecondaryColor,
                fontSize: isHighlight ? 16 : 13,
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
          const Icon(Icons.inventory_2_outlined, color: kGreyMedium, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['product_name'] ?? 'Unknown Part', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Qty: ${item['quantity']}', style: const TextStyle(color: kTextSecondary, fontSize: 12)),
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
}
