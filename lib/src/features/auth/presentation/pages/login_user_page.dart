// ============================================================
// login_user_page.dart — Customer Login Screen
// ============================================================
// Lets a registered customer sign in with their email and password.
//
// Flow:
//   1. On open, check if the user is already logged in → skip to dashboard.
//   2. User fills in the form and taps SIGN IN.
//   3. Validate inputs (not empty).
//   4. Query the database for a matching email + password.
//   5a. Match found → save session, go to UserDashboardPage.
//   5b. No match    → show an error snack bar.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/pages/user_dashboard_page.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';

/// Login form for regular customers.
class LoginUserPage extends StatefulWidget {
  const LoginUserPage({super.key});

  @override
  State<LoginUserPage> createState() => _LoginUserPageState();
}

class _LoginUserPageState extends State<LoginUserPage> {
  // _formKey lets us validate all fields at once when the user taps submit.
  final _formKey = GlobalKey<FormState>();

  // Controllers hold the text typed into each input field.
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  // Tracks whether the password dots should be shown as plain text.
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Skip the login screen if the user is already signed in.
    _checkExistingSession();
  }

  /// If a valid session exists, navigate directly to the dashboard.
  Future<void> _checkExistingSession() async {
    if (await SessionManager.isUserLoggedIn()) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserDashboardPage()),
      );
    }
  }

  /// Validates the form, queries the database, and handles the result.
  void _login() async {
    if (_formKey.currentState!.validate()) {
      final email    = _emailController.text;
      final password = _passwordController.text;

      // Ask the database for a user with this email + password combination.
      final user = await DatabaseHelper.instance.getUser(email, password);

      if (user != null) {
        // Credentials matched — save the session and go to the dashboard.
        await SessionManager.setUserSession(user['username'], email);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UserDashboardPage()),
        );
      } else {
        // No match — show a red error message at the bottom of the screen.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
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
      backgroundColor: kSurfaceColor,
      // Transparent app bar just provides the back button.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kSecondaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Logo with Hero animation (matches the tag on HomePage).
                  Hero(
                    tag: 'logo',
                    child: Center(
                      child: Image.asset(
                        'lib/assets/Imgs/logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Header text ────────────────────────────
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kSecondaryColor,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue shopping',
                    style: TextStyle(color: kTextSecondary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // ── Email field ────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, size: 22),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    // Validator returns an error string or null (null = valid).
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please enter your email' : null,
                  ),

                  const SizedBox(height: 20),

                  // ── Password field ─────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 22),
                      // Eye icon toggles password visibility.
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () =>
                            setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    // obscureText hides the characters as dots when true.
                    obscureText: !_isPasswordVisible,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please enter your password' : null,
                  ),

                  const SizedBox(height: 12),

                  // ── Forgot password placeholder ────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {}, // Feature not yet implemented
                      child: const Text('Forgot Password?',
                          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Sign In button ─────────────────────────
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      shadowColor: kPrimaryColor.withOpacity(0.4),
                      elevation: 8,
                    ),
                    child: const Text('SIGN IN'),
                  ),

                  const SizedBox(height: 24),

                  // ── Link to sign-up ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                          style: TextStyle(color: kTextSecondary)),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/signup_user'),
                        child: const Text('Sign Up',
                            style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
