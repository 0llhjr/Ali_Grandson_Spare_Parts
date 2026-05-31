// ============================================================
// signup_user_page.dart — Customer Registration Screen
// ============================================================
// New customers fill in this form to create an account.
// Fields collected: username, full name, email, phone,
//                   password, and date of birth.
//
// Validation rules:
//   • Username and email must be unique (checked against the DB).
//   • Email must match a basic regex pattern.
//   • Password must be at least 8 characters.
//   • Date of birth is picked via a calendar dialog (read-only field).
//
// On success: the user is sent to the login screen to sign in.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/pages/user_dashboard_page.dart';
import 'login_user_page.dart';

/// Registration form for new customer accounts.
class SignupUserPage extends StatefulWidget {
  const SignupUserPage({super.key});

  @override
  State<SignupUserPage> createState() => _SignupUserPageState();
}

class _SignupUserPageState extends State<SignupUserPage> {
  final _formKey = GlobalKey<FormState>();

  // One controller per input field.
  final _usernameController = TextEditingController();
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController      = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Skip registration if the user is already signed in.
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    if (await SessionManager.isUserLoggedIn()) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserDashboardPage()),
      );
    }
  }

  /// Validates inputs, checks uniqueness, then inserts the new account.
  void _signup() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final email    = _emailController.text;

      // Check whether the chosen username is already taken.
      final isUsernameTaken = await DatabaseHelper.instance.isUsernameTaken(username);
      if (isUsernameTaken) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Username is already taken.'), backgroundColor: kErrorColor),
        );
        return;
      }

      // Check whether the email is already registered.
      final isEmailTaken = await DatabaseHelper.instance.isEmailTaken(email);
      if (isEmailTaken) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email is already registered.'), backgroundColor: kErrorColor),
        );
        return;
      }

      // Build the user map to save in the database.
      final user = {
        'username': username,
        'name': _nameController.text,
        'email': email,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'dob': _dobController.text,
      };

      final id = await DatabaseHelper.instance.insertUser(user);

      if (id != 0) {
        // Account created — redirect to login.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account created! Please sign in.'),
              backgroundColor: kSuccessColor),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginUserPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kSecondaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ── Page title ────────────────────────────────
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join Ali Grandsons for premium parts',
                  style: TextStyle(color: kTextSecondary, fontSize: 16),
                ),

                const SizedBox(height: 40),

                // ── Username ──────────────────────────────────
                _buildFieldTitle('Username'),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'Choose a unique username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Username is required' : null,
                ),

                const SizedBox(height: 20),

                // ── Full Name ─────────────────────────────────
                _buildFieldTitle('Full Name'),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Email ─────────────────────────────────────
                _buildFieldTitle('Email Address'),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'email@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email is required';
                    // Simple regex check for a valid email format.
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                      return 'Invalid email';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Phone Number ──────────────────────────────
                _buildFieldTitle('Phone Number'),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    hintText: '+968 XXXX XXXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Phone is required' : null,
                ),

                const SizedBox(height: 20),

                // ── Password ──────────────────────────────────
                _buildFieldTitle('Password'),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Minimum 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 8) return 'Minimum 8 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Date of Birth ─────────────────────────────
                _buildFieldTitle('Date of Birth'),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  readOnly: true, // User must pick from the calendar dialog
                  onTap: () async {
                    // Show a date picker dialog when the field is tapped.
                    DateTime? dob = await showDatePicker(
                      context: context,
                      // Default to 18 years ago (6570 days).
                      initialDate:
                          DateTime.now().subtract(const Duration(days: 6570)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (dob != null) {
                      // Store only the date part (e.g. "1995-08-15").
                      setState(() => _dobController.text = dob.toString().split(' ')[0]);
                    }
                  },
                ),

                const SizedBox(height: 40),

                // ── Submit button ─────────────────────────────
                ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    shadowColor: kPrimaryColor.withOpacity(0.4),
                    elevation: 8,
                  ),
                  child: const Text('CREATE ACCOUNT'),
                ),

                const SizedBox(height: 24),

                // ── Link to login ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style: TextStyle(color: kTextSecondary)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginUserPage()),
                      ),
                      child: const Text('Sign In',
                          style: TextStyle(
                              color: kPrimaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper that renders a bold label above each form field.
  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: kSecondaryColor),
      ),
    );
  }
}
