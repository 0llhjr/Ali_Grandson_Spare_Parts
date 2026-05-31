// ============================================================
// email_templates.dart — HTML Email Templates
// ============================================================
// Every automated email sent by the app is generated here as
// a styled HTML string.
//
// All templates use a shared _baseTemplate() layout that adds
// a consistent header, footer, and basic CSS styling.
//
// Template categories:
//   Admin alerts  — low stock, out of stock, new order received
//   Customer info — order status changes, cancellation, delivery,
//                   back-in-stock, new arrivals, password reset
// ============================================================

/// Provides pre-built HTML email bodies for all system notifications.
class EmailTemplates {
  // ── Private Base Layout ───────────────────────────────────────

  /// Wraps [content] inside a standard branded HTML email layout.
  /// [title] appears as the main heading inside the email body.
  static String _baseTemplate(String title, String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { width: 80%; margin: 20px auto; border: 1px solid #ddd; padding: 20px; border-radius: 10px; }
        .header { background-color: #f4f4f4; padding: 10px; text-align: center; border-bottom: 1px solid #ddd; }
        .content { padding: 20px; }
        .footer { font-size: 12px; text-align: center; color: #777; margin-top: 20px; }
        .button { display: inline-block; padding: 10px 20px; background-color: #007bff; color: #fff; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>Ali Grandson Spare Parts</h2>
        </div>
        <div class="content">
            <h3>$title</h3>
            $content
        </div>
        <div class="footer">
            &copy; ${DateTime.now().year} Ali Grandson Spare Parts. All rights reserved.
        </div>
    </div>
</body>
</html>
''';
  }

  // ── Admin Alert Templates ─────────────────────────────────────

  /// Email sent to the admin when a product's stock drops below 5 units.
  /// [productName] is the name of the affected product.
  /// [quantity] is the current stock level.
  static String lowStockAdmin(String productName, int quantity) {
    return _baseTemplate(
      'Low Stock Alert',
      '<p>Hello Admin,</p>'
      '<p>The stock for <strong>$productName</strong> is running low.</p>'
      '<p>Current Quantity: <strong>$quantity</strong></p>'
      '<p>Please consider restocking soon.</p>',
    );
  }

  /// Email sent to the admin when a product reaches zero stock.
  static String outOfStockAdmin(String productName) {
    return _baseTemplate(
      'Out of Stock Alert',
      '<p>Hello Admin,</p>'
      '<p>The product <strong>$productName</strong> is now <strong>out of stock</strong>.</p>'
      '<p>Please restock immediately to avoid missing potential sales.</p>',
    );
  }

  /// Email sent to the admin when a customer places a new order.
  /// [orderId] is the order's database id.
  /// [customerName] is the customer's display name.
  /// [totalAmount] is the formatted price string (e.g. "OMR 25.500").
  static String newOrderAdmin(String orderId, String customerName, String totalAmount) {
    return _baseTemplate(
      'New Order Received',
      '<p>Hello Admin,</p>'
      '<p>A new order has been placed.</p>'
      '<ul>'
      '<li>Order ID: #$orderId</li>'
      '<li>Customer: $customerName</li>'
      '<li>Total Amount: $totalAmount</li>'
      '</ul>'
      '<p>Please check the admin dashboard for details.</p>',
    );
  }

  // ── Customer Notification Templates ──────────────────────────

  /// Email sent to the customer when their order status changes
  /// (e.g. Pending → Ready → In Delivery).
  static String orderStatusChanged(
      String customerName, String orderId, String newStatus) {
    return _baseTemplate(
      'Order Update',
      '<p>Hi $customerName,</p>'
      '<p>The status of your order <strong>#$orderId</strong> has been updated to: '
      '<strong>$newStatus</strong>.</p>',
    );
  }

  /// Email sent to the customer when their order is cancelled by the admin.
  /// [reason] contains the admin's written explanation.
  static String orderCancelled(
      String customerName, String orderId, String reason) {
    return _baseTemplate(
      'Order Cancelled',
      '<p>Hi $customerName,</p>'
      '<p>We regret to inform you that your order <strong>#$orderId</strong> '
      'has been cancelled.</p>'
      '<p><strong>Reason for cancellation:</strong> $reason</p>'
      '<p>If you have any questions, please contact our support team.</p>',
    );
  }

  /// Email sent to the customer when their order is marked as Delivered.
  static String orderDelivered(String customerName, String orderId) {
    return _baseTemplate(
      'Order Delivered',
      '<p>Hi $customerName,</p>'
      '<p>Good news! Your order <strong>#$orderId</strong> has been delivered.</p>'
      '<p>We hope you are satisfied with your purchase. Thank you for shopping with us!</p>',
    );
  }

  /// Email sent to all customers when a previously out-of-stock product
  /// is restocked by the admin.
  static String productBackInStock(String customerName, String productName) {
    return _baseTemplate(
      'Back in Stock!',
      '<p>Hi $customerName,</p>'
      '<p>The product you were interested in, <strong>$productName</strong>, '
      'is now back in stock!</p>'
      '<p>Get it before it sells out again!</p>',
    );
  }

  /// Email sent to all customers when the admin adds a new product.
  static String newProductAdded(
      String customerName, String productName, String description) {
    return _baseTemplate(
      'New Arrival!',
      '<p>Hi $customerName,</p>'
      '<p>We have a new addition to our catalog: <strong>$productName</strong>.</p>'
      '<p>$description</p>'
      '<p>Check it out in the app now!</p>',
    );
  }

  /// Email sent to a customer when the admin resets their password.
  /// [newPassword] is the auto-generated temporary password.
  static String passwordReset(String customerName, String newPassword) {
    return _baseTemplate(
      'Password Reset',
      '<p>Hi $customerName,</p>'
      '<p>Your account password has been reset by the administrator.</p>'
      '<p>Your new temporary password is: <strong>$newPassword</strong></p>'
      '<p>Please log in and change your password as soon as possible for security reasons.</p>',
    );
  }
}
