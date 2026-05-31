// ============================================================
// login_admin_page.dart — Admin Login Screen
// ============================================================
// A restricted login page for store administrators only.
// The screen has a dark background to visually distinguish it
// from the regular customer login.
//
// Flow:
//   1. On open, check if admin is already logged in → go to dashboard.
//   2. Admin enters their ID/email and password.
//   3. Validate inputs (not empty).
//   4. Check the `admins` table in the database.
//   5a. Match found → save admin session, go to AdminDashboardPage.
//   5b. No match    → show "Access Denied" snack bar.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/pages/admin_dashboard_page.dart';

/// Secure login screen for admin users.
class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({super.key});

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _passwordController = TextEditingController();

  // Tracks whether the password field shows plain text.
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  /// Redirects to the admin dashboard if an admin session already exists.
  Future<void> _checkExistingSession() async {
    if (await SessionManager.isAdminLoggedIn()) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
      );
    }
  }

  /// Validates the form and attempts to authenticate against the admins table.
  void _login() async {
    if (_formKey.currentState!.validate()) {
      final email    = _emailController.text;
      final password = _passwordController.text;

      // Look for a matching admin account in the database.
      final admin = await DatabaseHelper.instance.getAdmin(email, password);

      if (admin != null) {
        // Valid admin — save the session and open the admin dashboard.
        await SessionManager.setAdminSession(email);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        );
      } else {
        // Invalid credentials — deny access.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Invalid Credentials'),
            backgroundColor: kErrorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dark background differentiates this from the customer login screen.
      backgroundColor: kSecondaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              // ── White card containing the form ─────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Admin shield icon at the top of the card.
                      const Icon(Icons.admin_panel_settings_rounded,
                          size: 64, color: kPrimaryColor),

                      const SizedBox(height: 16),

                      // ── Title & subtitle ──────────────────────
                      const Text(
                        'ADMIN LOGIN',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: kSecondaryColor,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Authorized Personnel Only',
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // ── Admin ID / Email field ─────────────────
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: kTextPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Admin ID / Email',
                          prefixIcon: Icon(Icons.badge_outlined),
                          fillColor: kGreyLight,
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Enter Admin ID' : null,
                      ),

                      const SizedBox(height: 20),

                      // ── Password field ─────────────────────────
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: kTextPrimary),
                        decoration: InputDecoration(
                          labelText: 'Secure Password',
                          prefixIcon: const Icon(Icons.lock_person_outlined),
                          fillColor: kGreyLight,
                          suffixIcon: IconButton(
                            icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () =>
                                setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Enter password' : null,
                      ),

                      const SizedBox(height: 40),

                      // ── Authenticate button ────────────────────
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shadowColor: kPrimaryColor.withOpacity(0.4),
                          elevation: 8,
                        ),
                        child: const Text('AUTHENTICATE'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Footer disclaimer ──────────────────────────
              const Text(
                'Proprietary System of Ali Grandsons Spare Parts',
                style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
