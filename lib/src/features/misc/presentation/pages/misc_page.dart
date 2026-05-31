// ============================================================
// misc_page.dart — Miscellaneous / User Menu Screen
// ============================================================
// Opened when the user taps the "Menu" icon in the bottom
// navigation bar. Acts as a central hub for all user-facing
// sections that are not part of the main shopping flow.
//
// Sections displayed:
//   Account  — Profile settings, My Orders
//   Shopping — Wishlist, Cart
//   Support  — AI Chat / FAQ
//   Danger   — Sign Out button (red, requires confirmation)
//
// A profile header at the top shows the user's name, email,
// and username loaded from the database.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:alis_grandson_app/src/features/orders/presentation/pages/user_orders_page.dart';
import 'package:alis_grandson_app/src/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:alis_grandson_app/src/features/cart/presentation/pages/cart_page.dart';
import 'package:alis_grandson_app/src/features/support/presentation/pages/faq_page.dart';
import 'package:alis_grandson_app/src/features/home/presentation/pages/home_page.dart';

/// Central menu screen listing all user sections and a logout button.
class MiscPage extends StatefulWidget {
  const MiscPage({super.key});

  @override
  State<MiscPage> createState() => _MiscPageState();
}

class _MiscPageState extends State<MiscPage> {
  // User's full name shown in the header (falls back to username).
  String _displayName = '';

  // The logged-in username (@handle).
  String _username = '';

  // The user's email address shown under their name.
  String _email = '';

  // True while loading the user's profile from the database.
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Reads the username from the session, then fetches the user's
  /// full name and email from the database for the profile header.
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';
    if (username.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByUsername(username);
      if (mounted) {
        setState(() {
          _username = username;
          _displayName =
              (user != null && (user['name'] as String?)?.isNotEmpty == true)
                  ? user['name']
                  : username;
          _email = user?['email'] ?? '';
          _isLoadingProfile = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  /// Shows a confirmation dialog then clears the session and
  /// navigates to the landing page, removing all routes from the stack.
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              minimumSize: const Size(100, 40),
            ),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SessionManager.clearSession();
      if (!mounted) return;
      // Remove every route so the user cannot press Back and return to the dashboard.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  /// Pushes [page] onto the navigation stack.
  void _navigateTo(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('MENU'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button — this is a tab, not a pushed screen
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User profile header ───────────────────────────
            _buildProfileHeader(),

            const SizedBox(height: 20),

            // ── Account section ───────────────────────────────
            _buildSection(
              'Account',
              [
                _buildMenuItem(
                  icon: Icons.person_rounded,
                  title: 'My Profile',
                  subtitle: 'Edit name, email, phone and password',
                  onTap: () => _navigateTo(const ProfilePage()),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'My Orders',
                  subtitle: 'Track active and past orders',
                  onTap: () => _navigateTo(const UserOrdersPage()),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Shopping section ──────────────────────────────
            _buildSection(
              'Shopping',
              [
                _buildMenuItem(
                  icon: Icons.favorite_rounded,
                  title: 'My Wishlist',
                  subtitle: 'Products you have saved',
                  onTap: () => _navigateTo(const WishlistPage()),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.shopping_bag_rounded,
                  title: 'My Cart',
                  subtitle: 'Items ready to order',
                  onTap: () => _navigateTo(const CartPage()),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Support section ───────────────────────────────
            _buildSection(
              'Support',
              [
                _buildMenuItem(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Support Chat',
                  subtitle: 'Ask our AI assistant anything',
                  onTap: () => _navigateTo(const FAQPage()),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Sign out button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: kErrorColor),
                label: const Text(
                  'SIGN OUT',
                  style: TextStyle(color: kErrorColor, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: kErrorColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Profile header ─────────────────────────────────────────

  /// White card showing the user's avatar, name, email, and a quick edit button.
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: kSurfaceColor,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          // ── Avatar circle ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kPrimaryColor, width: 2),
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: kGreyLight,
              child: Icon(Icons.person_rounded, size: 38, color: kGreyMedium),
            ),
          ),

          const SizedBox(width: 16),

          // ── Name, email, username ──────────────────────────
          Expanded(
            child: _isLoadingProfile
                ? const Text('Loading…', style: TextStyle(color: kTextSecondary))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _email,
                          style: const TextStyle(fontSize: 12, color: kTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (_username.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@$_username',
                          style: const TextStyle(fontSize: 12, color: kGreyMedium),
                        ),
                      ],
                    ],
                  ),
          ),

          // ── Edit profile shortcut ──────────────────────────
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined, color: kPrimaryColor, size: 18),
            ),
            onPressed: () => _navigateTo(const ProfilePage()),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }

  // ── Section helpers ────────────────────────────────────────

  /// Wraps [items] in a labelled white card with a section title above.
  Widget _buildSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: kTextSecondary,
                letterSpacing: 1.4,
              ),
            ),
          ),
          // Card containing the menu items
          Container(
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kGreyLight),
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  /// A single tappable row inside a section card.
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kPrimaryColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: kSecondaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: kTextSecondary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: kGreyMedium),
      onTap: onTap,
    );
  }

  /// A thin divider line used between items inside a section card.
  Widget _buildDivider() {
    return const Divider(height: 1, indent: 60, color: kGreyLight);
  }
}
