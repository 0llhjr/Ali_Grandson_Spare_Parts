// ============================================================
// email_templates.dart — HTML Email Template Loader
// ============================================================
// Every HTML email body is stored as a standalone .html file
// under lib/assets/email_templates/.  This class loads each
// file via rootBundle, then replaces {{placeholder}} tokens
// with the actual runtime values before returning the string.
//
// All methods are async because rootBundle.loadString() is
// async.  Callers must await the result before passing it to
// EmailService.sendGoogleEmail().
//
// Placeholder convention: {{camelCaseName}}
//   {{year}}         — current calendar year (injected into every footer)
//
// Template files:
//   Admin alerts    — admin_low_stock.html, admin_out_of_stock.html,
//                     admin_new_order.html
//   Customer emails — customer_order_status.html,
//                     customer_order_cancelled.html,
//                     customer_order_delivered.html,
//                     customer_back_in_stock.html,
//                     customer_new_product.html,
//                     customer_password_reset.html,
//                     customer_forgot_password.html
// ============================================================

import 'package:flutter/services.dart' show rootBundle;

/// Loads and populates HTML email templates stored in
/// lib/assets/email_templates/.
class EmailTemplates {
  // ── Private Helpers ───────────────────────────────────────────

  /// Loads the HTML file at [assetPath] and replaces every key in
  /// [replacements] (formatted as {{key}}) with its corresponding value.
  /// Also injects {{year}} with the current calendar year.
  static Future<String> _load(
    String assetPath,
    Map<String, String> replacements,
  ) async {
    // Read the raw HTML from the bundled asset.
    String html = await rootBundle.loadString(assetPath);

    // Always inject the current year into the footer placeholder.
    html = html.replaceAll('{{year}}', DateTime.now().year.toString());

    // Replace each caller-supplied placeholder.
    replacements.forEach((key, value) {
      html = html.replaceAll('{{$key}}', value);
    });

    return html;
  }

  // ── Admin Alert Templates ─────────────────────────────────────

  /// Email sent to the admin when a product's stock drops below 5 units.
  ///
  /// [productName] is the name of the affected product.
  /// [quantity]    is the current stock level.
  static Future<String> lowStockAdmin(String productName, int quantity) {
    return _load(
      'lib/assets/email_templates/admin_low_stock.html',
      {
        'productName': productName,
        'quantity':    quantity.toString(),
      },
    );
  }

  /// Email sent to the admin when a product reaches zero stock.
  ///
  /// [productName] is the name of the out-of-stock product.
  static Future<String> outOfStockAdmin(String productName) {
    return _load(
      'lib/assets/email_templates/admin_out_of_stock.html',
      {'productName': productName},
    );
  }

  /// Email sent to the admin when a customer places a new order.
  ///
  /// [orderId]      is the order's database ID.
  /// [customerName] is the customer's display name.
  /// [totalAmount]  is the formatted price string (e.g. "OMR 25.500").
  static Future<String> newOrderAdmin(
      String orderId, String customerName, String totalAmount) {
    return _load(
      'lib/assets/email_templates/admin_new_order.html',
      {
        'orderId':      orderId,
        'customerName': customerName,
        'totalAmount':  totalAmount,
      },
    );
  }

  // ── Customer Notification Templates ──────────────────────────

  /// Email sent to the customer when their order status changes.
  ///
  /// [customerName] is the customer's display name.
  /// [orderId]      is the order's database ID.
  /// [newStatus]    is the updated status string.
  static Future<String> orderStatusChanged(
      String customerName, String orderId, String newStatus) {
    return _load(
      'lib/assets/email_templates/customer_order_status.html',
      {
        'customerName': customerName,
        'orderId':      orderId,
        'newStatus':    newStatus,
      },
    );
  }

  /// Email sent to the customer when their order is cancelled by the admin.
  ///
  /// [customerName] is the customer's display name.
  /// [orderId]      is the order's database ID.
  /// [reason]       is the admin's written explanation for the cancellation.
  static Future<String> orderCancelled(
      String customerName, String orderId, String reason) {
    return _load(
      'lib/assets/email_templates/customer_order_cancelled.html',
      {
        'customerName': customerName,
        'orderId':      orderId,
        'reason':       reason,
      },
    );
  }

  /// Email sent to the customer when their order is marked as Delivered.
  ///
  /// [customerName] is the customer's display name.
  /// [orderId]      is the order's database ID.
  static Future<String> orderDelivered(String customerName, String orderId) {
    return _load(
      'lib/assets/email_templates/customer_order_delivered.html',
      {
        'customerName': customerName,
        'orderId':      orderId,
      },
    );
  }

  /// Email sent to customers when a previously out-of-stock product is restocked.
  ///
  /// [customerName] is the customer's display name.
  /// [productName]  is the name of the restocked product.
  static Future<String> productBackInStock(
      String customerName, String productName) {
    return _load(
      'lib/assets/email_templates/customer_back_in_stock.html',
      {
        'customerName': customerName,
        'productName':  productName,
      },
    );
  }

  /// Email sent to customers when the admin adds a new product to the catalog.
  ///
  /// [customerName] is the customer's display name.
  /// [productName]  is the name of the new product.
  /// [description]  is the product's short description.
  static Future<String> newProductAdded(
      String customerName, String productName, String description) {
    return _load(
      'lib/assets/email_templates/customer_new_product.html',
      {
        'customerName': customerName,
        'productName':  productName,
        'description':  description,
      },
    );
  }

  /// Email sent to a customer when the admin manually resets their password.
  ///
  /// [customerName] is the customer's display name.
  /// [newPassword]  is the auto-generated temporary password.
  static Future<String> passwordReset(
      String customerName, String newPassword) {
    return _load(
      'lib/assets/email_templates/customer_password_reset.html',
      {
        'customerName': customerName,
        'context':      'An administrator has reset your account password. Use the temporary password below to sign in.',
        'password':     newPassword,
      },
    );
  }

  /// Email sent to a customer after they successfully change their own password.
  ///
  /// [customerName] is the customer's display name.
  /// [changedAt]    is a human-readable timestamp (e.g. "3 June 2026, 14:32").
  static Future<String> passwordChanged(
      String customerName, String changedAt) {
    return _load(
      'lib/assets/email_templates/customer_password_changed.html',
      {
        'customerName': customerName,
        'changedAt':    changedAt,
      },
    );
  }

  /// Email sent to a customer when they use the self-service forgot-password flow.
  ///
  /// [customerName] is the customer's display name.
  /// [tempPassword] is the randomly generated one-time password.
  static Future<String> forgotPasswordEmail(
      String customerName, String tempPassword) {
    return _load(
      'lib/assets/email_templates/customer_password_reset.html',
      {
        'customerName': customerName,
        'context':      'We received a request to reset the password for your account. Use the temporary password below to sign in.',
        'password':     tempPassword,
      },
    );
  }
}
