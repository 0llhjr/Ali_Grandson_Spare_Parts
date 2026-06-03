// ============================================================
// order_page.dart — Checkout / Order Placement Screen
// ============================================================
// Presents a checkout form after the user taps "Proceed to Checkout"
// from the cart.  The user enters:
//   • Delivery address and contact phone number.
//   • Optional special instructions (e.g. "Leave with neighbour").
//   • Payment method: Cash on Delivery or Card.
//     — Selecting Card reveals additional card detail fields with:
//       · Auto-formatting (4-4-4-4 or Amex 4-6-5 grouping)
//       · Live card-type detection (Visa / Mastercard / Amex / Discover)
//         shown as a branded badge at the end of the number field.
//       · Luhn algorithm check — number text turns red when invalid.
//       · Expiry date turns red + shows "Expired" when past.
//       · Checkout button is disabled until all card fields are valid.
//
// On confirmation:
//   1. The order is saved via placeOrder() (atomic DB transaction).
//   2. Email notifications sent to admin + stock alerts if needed.
//   3. The user is returned to the dashboard.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/shared/services/email_service.dart';
import 'package:alis_grandson_app/src/shared/utils/email_templates.dart';

// ── Card type ──────────────────────────────────────────────────
enum _CardType { unknown, visa, mastercard, amex, discover }

// ── Input formatters ───────────────────────────────────────────

/// Formats card number as groups of 4 (XXXX XXXX XXXX XXXX) for
/// standard cards, or 4-6-5 (XXXX XXXXXX XXXXX) for Amex.
/// Strips non-digits and caps length automatically.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final isAmex = RegExp(r'^3[47]').hasMatch(digits);
    final maxLen = isAmex ? 15 : 16;
    final raw = digits.length > maxLen ? digits.substring(0, maxLen) : digits;

    String formatted;
    if (isAmex) {
      if (raw.length <= 4) {
        formatted = raw;
      } else if (raw.length <= 10) {
        formatted = '${raw.substring(0, 4)} ${raw.substring(4)}';
      } else {
        formatted =
            '${raw.substring(0, 4)} ${raw.substring(4, 10)} ${raw.substring(10)}';
      }
    } else {
      final buf = StringBuffer();
      for (int i = 0; i < raw.length; i++) {
        if (i > 0 && i % 4 == 0) buf.write(' ');
        buf.write(raw[i]);
      }
      formatted = buf.toString();
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Automatically inserts "/" after the month digits: 05 → 05/26
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) return oldValue;

    final formatted = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Page ───────────────────────────────────────────────────────

/// Checkout screen where users provide delivery details and confirm the order.
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  final EmailService _emailService = EmailService();

  String _paymentMode = 'Cash on Delivery';
  List<Map<String, dynamic>> _cartItems = [];
  String _username = '';
  String _customerName = '';
  bool _isLoading = true;

  // ── Card validation state (updated on every keystroke) ──────
  _CardType _cardType = _CardType.unknown;
  bool _luhnValid = false;
  bool _expiryExpired = false;

  // ── Lifecycle ───────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    _cardNumberController.addListener(_onCardNumberChanged);
    _expiryDateController.addListener(_onExpiryChanged);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // ── Card listeners ──────────────────────────────────────────

  void _onCardNumberChanged() {
    final digits = _cardNumberController.text.replaceAll(' ', '');
    setState(() {
      _cardType = _detectCardType(digits);
      _luhnValid = _luhnCheck(digits);
    });
  }

  void _onExpiryChanged() {
    setState(() {
      _expiryExpired = _isExpired(_expiryDateController.text);
    });
  }

  // ── Card logic (static helpers) ─────────────────────────────

  static _CardType _detectCardType(String digits) {
    if (digits.isEmpty) return _CardType.unknown;
    if (digits.startsWith('4')) return _CardType.visa;
    if (RegExp(r'^5[1-5]').hasMatch(digits)) return _CardType.mastercard;
    if (digits.length >= 4) {
      final prefix = int.tryParse(digits.substring(0, 4)) ?? 0;
      if (prefix >= 2221 && prefix <= 2720) return _CardType.mastercard;
    }
    if (RegExp(r'^3[47]').hasMatch(digits)) return _CardType.amex;
    if (RegExp(r'^6(?:011|5\d\d|4[4-9]\d)').hasMatch(digits)) {
      return _CardType.discover;
    }
    return _CardType.unknown;
  }

  /// Returns true when the stripped digit string passes the Luhn algorithm.
  static bool _luhnCheck(String digits) {
    if (digits.length < 13 || digits.length > 19) return false;
    if (!RegExp(r'^\d+$').hasMatch(digits)) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Returns true if [expiry] (MM/YY) is in the past.
  /// Cards are valid through the last day of the stated month.
  static bool _isExpired(String expiry) {
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) return false;
    final parts = expiry.split('/');
    final month = int.parse(parts[0]);
    final year = 2000 + int.parse(parts[1]);
    if (month < 1 || month > 12) return false;
    final now = DateTime.now();
    if (year < now.year) return true;
    if (year == now.year && month < now.month) return true;
    return false;
  }

  // ── Checkout gate ───────────────────────────────────────────

  /// Returns false when Card is selected and any field is invalid.
  /// Used to disable the checkout button in real time.
  bool get _canCheckout {
    if (_paymentMode != 'Card') return true;
    final digits = _cardNumberController.text.replaceAll(' ', '');
    final expiryOk = RegExp(r'^\d{2}/\d{2}$')
            .hasMatch(_expiryDateController.text) &&
        !_expiryExpired;
    return _cardNameController.text.trim().isNotEmpty &&
        digits.length >= 13 &&
        _luhnValid &&
        expiryOk &&
        _cvvController.text.length >= 3;
  }

  // ── Data loading ────────────────────────────────────────────

  Future<void> _loadOrderData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('user_username') ?? '';
    if (_username.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByUsername(_username);
      if (user != null) {
        _phoneController.text = user['phone'] ?? '';
        _customerName = user['name'] ?? _username;
      }
      _cartItems = await DatabaseHelper.instance.getCartItems(_username);
    }
    setState(() => _isLoading = false);
  }

  double get _totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));

  // ── Order placement ─────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final order = {
      'user_username': _username,
      'address': _addressController.text,
      'phone': _phoneController.text,
      'special_instructions': _instructionsController.text,
      'payment_mode': _paymentMode,
      'total_price': _totalPrice,
      'status': 'Pending',
      'order_date': DateTime.now().toString(),
    };

    final orderId = await DatabaseHelper.instance.placeOrder(order, _cartItems);
    _sendAdminNotifications(orderId.toString());

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order placed successfully! Notifications sent to Admin.'),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/user_dashboard',
      (route) => false,
    );
  }

  Future<void> _sendAdminNotifications(String orderId) async {
    final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? 'admin@example.com';
    await _emailService.sendGoogleEmail(
      recipientEmails: adminEmail,
      subject: 'New Order Received #$orderId',
      htmlBody: await EmailTemplates.newOrderAdmin(
          orderId, _customerName, 'OMR ${_totalPrice.toStringAsFixed(3)}'),
    );
    for (var item in _cartItems) {
      final product = await DatabaseHelper.instance.getProduct(item['id']);
      if (product != null) {
        final available = product['available'] as int;
        if (available == 0) {
          await _emailService.sendGoogleEmail(
            recipientEmails: adminEmail,
            subject: 'Out of Stock Alert: ${product['name']}',
            htmlBody: await EmailTemplates.outOfStockAdmin(product['name']),
          );
        } else if (available < 5) {
          await _emailService.sendGoogleEmail(
            recipientEmails: adminEmail,
            subject: 'Low Stock Alert: ${product['name']}',
            htmlBody: await EmailTemplates.lowStockAdmin(product['name'], available),
          );
        }
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('CHECKOUT'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        Icons.location_on_outlined, 'Delivery Information'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Full Delivery Address',
                        hintText: 'Building, Street, Area, City',
                      ),
                      maxLines: 2,
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter your address' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter a phone number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Special Instructions (optional)',
                        hintText: 'e.g. Leave with neighbour',
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                        Icons.payment_outlined, 'Payment Method'),
                    const SizedBox(height: 16),
                    _buildPaymentOption(
                        'Cash on Delivery', Icons.payments_outlined),
                    const SizedBox(height: 12),
                    _buildPaymentOption('Card', Icons.credit_card_outlined),
                    if (_paymentMode == 'Card') _buildCardDetails(),
                    const SizedBox(height: 32),
                    _buildOrderSummary(),
                    const SizedBox(height: 32),
                    // Disabled automatically when card fields are invalid
                    ElevatedButton(
                      onPressed: _canCheckout ? _placeOrder : null,
                      style: ElevatedButton.styleFrom(
                        shadowColor: kPrimaryColor.withValues(alpha: 0.3),
                        elevation: 10,
                      ),
                      child: const Text('CONFIRM & PLACE ORDER'),
                    ),
                    if (_paymentMode == 'Card' && !_canCheckout)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Please fix the card details above to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: kErrorColor,
                              fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Section helpers ─────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kSecondaryColor,
              letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String mode, IconData icon) {
    final isSelected = _paymentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? kPrimaryColor : kGreyLight, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPrimaryColor : kTextSecondary),
            const SizedBox(width: 16),
            Text(
              mode,
              style: TextStyle(
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? kPrimaryColor : kSecondaryColor,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }

  // ── Card details section ────────────────────────────────────

  Widget _buildCardDetails() {
    final digits = _cardNumberController.text.replaceAll(' ', '');
    // Amex is 15 digits; all other networks are 16.
    // Only trigger the Luhn error once the FULL expected length is reached
    // so the user is not flagged while still typing the last few digits.
    final expectedLen = _cardType == _CardType.amex ? 15 : 16;
    final showLuhnError = digits.length == expectedLen && !_luhnValid;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kGreyLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card holder name ──────────────────────────────
          TextFormField(
            controller: _cardNameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Card Holder Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
              isDense: true,
            ),
            validator: (v) => _paymentMode == 'Card' && (v?.trim().isEmpty ?? true)
                ? 'Card holder name is required'
                : null,
          ),

          const SizedBox(height: 16),

          // ── Card number ───────────────────────────────────
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [_CardNumberFormatter()],
            style: TextStyle(
              color: showLuhnError ? Colors.red : null,
              fontSize: 13,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '0000  0000  0000  0000',
              prefixIcon: const Icon(Icons.credit_card_outlined),
              // Card brand badge — shows once first digit is typed
              suffixIcon: digits.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: _buildCardBrand(),
                    ),
              // Red border override when Luhn fails
              enabledBorder: showLuhnError
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 1.5),
                    )
                  : null,
              focusedBorder: showLuhnError
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 2),
                    )
                  : null,
              labelStyle: showLuhnError
                  ? const TextStyle(color: Colors.red)
                  : null,
              errorStyle: const TextStyle(color: Colors.red),
            ),
            validator: (v) {
              if (_paymentMode != 'Card') return null;
              if (v == null || v.isEmpty) return 'Card number is required';
              final d = v.replaceAll(' ', '');
              if (d.length < 13) return 'Card number is too short';
              if (!_luhnCheck(d)) return 'Invalid card number — please check';
              return null;
            },
          ),

          // Inline Luhn error hint (real-time, before form submission)
          if (showLuhnError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 14),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Invalid card number',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ── Expiry + CVV row ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expiry date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _expiryDateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_ExpiryDateFormatter()],
                      style: TextStyle(
                        color: _expiryExpired ? Colors.red : null,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        hintText: 'MM/YY',
                        isDense: true,
                        prefixIcon:
                            const Icon(Icons.calendar_today_outlined, size: 18),
                        labelStyle: _expiryExpired
                            ? const TextStyle(color: Colors.red)
                            : null,
                        enabledBorder: _expiryExpired
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1.5),
                              )
                            : null,
                        focusedBorder: _expiryExpired
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 2),
                              )
                            : null,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                      validator: (v) {
                        if (_paymentMode != 'Card') return null;
                        if (v == null || v.isEmpty) return 'Required';
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) {
                          return 'Use MM/YY format';
                        }
                        final parts = v.split('/');
                        final month = int.parse(parts[0]);
                        if (month < 1 || month > 12) return 'Invalid month';
                        if (_isExpired(v)) return 'Card is expired';
                        return null;
                      },
                    ),
                    // Real-time "Expired" badge below the field
                    if (_expiryExpired)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined,
                                size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              'Expired',
                              style: TextStyle(
                                  color: Colors.red[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // CVV
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '•••',
                    isDense: true,
                    prefixIcon:
                        Icon(Icons.lock_outline_rounded, size: 18),
                  ),
                  validator: (v) {
                    if (_paymentMode != 'Card') return null;
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 3) return 'Invalid CVV';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card brand badge ────────────────────────────────────────

  /// Returns a small branded widget showing the detected card network.
  Widget _buildCardBrand() {
    switch (_cardType) {
      case _CardType.visa:
        return _visaBadge();
      case _CardType.mastercard:
        return _mastercardBadge();
      case _CardType.amex:
        return _amexBadge();
      case _CardType.discover:
        return _discoverBadge();
      case _CardType.unknown:
        return const Icon(Icons.credit_card_outlined, color: kGreyMedium);
    }
  }

  Widget _visaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F71), // Visa navy
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'VISA',
        style: TextStyle(
          color: Colors.white,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _mastercardBadge() {
    return SizedBox(
      width: 42,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B), // MC red
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFF79E1B).withValues(alpha: 0.9), // MC orange
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amexBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF007BC1), // Amex blue
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'AMEX',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _discoverBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6600), // Discover orange
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'DISC',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Order summary ───────────────────────────────────────────

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSecondaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items Total',
                  style: TextStyle(color: Colors.white70)),
              Text(
                'OMR ${_totalPrice.toStringAsFixed(3)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: Colors.white70)),
              Text('FREE',
                  style: TextStyle(
                      color: kAccentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white24),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(
                'OMR ${_totalPrice.toStringAsFixed(3)}',
                style: const TextStyle(
                    color: kAccentColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
