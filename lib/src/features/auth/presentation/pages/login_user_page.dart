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
//
// Forgot Password flow:
//   1. User taps "Forgot Password?" and enters their email.
//   2. App looks up the email in the database.
//   3a. Email found → generate a random 8-char temp password,
//       update the DB, send it via email, show success message.
//   3b. Email not found → show "no account" error.
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/pages/user_dashboard_page.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';
import 'package:alis_grandson_app/src/shared/services/email_service.dart';
import 'package:alis_grandson_app/src/shared/utils/email_templates.dart';

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

  /// Generates a random 8-character alphanumeric password for temporary use.
  String _generateTempPassword() {
    // Mix of uppercase letters, lowercase letters, and digits.
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Shows a dialog where the customer enters their email to receive a
  /// temporary password.  The flow:
  ///   1. Validate the email field (not empty).
  ///   2. Look up the email in the database.
  ///   3. If found: generate temp password → update DB → send email → confirm.
  ///   4. If not found: show "no account found" message.
  void _showForgotPasswordDialog() {
    // Separate controller/key scoped to this dialog only.
    final emailController = TextEditingController();
    final formKey         = GlobalKey<FormState>();

    // Tracks whether the async work is in progress (shows a spinner).
    bool isLoading = false;

    showDialog(
      context: context,
      // Prevent dismissal by tapping outside while loading.
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: kPrimaryColor, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kSecondaryColor,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter the email address linked to your account. We will send you a temporary password.',
                      style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      // Disable input while sending.
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        // Basic email format check.
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    // Show a centred loading indicator while the email is being sent.
                    if (isLoading) ...[
                      const SizedBox(height: 20),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: kPrimaryColor),
                            SizedBox(height: 10),
                            Text(
                              'Sending password...',
                              style: TextStyle(color: kTextSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                ),
              ),
              actions: [
                // Cancel button — disabled while loading.
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
                ),
                // Send button.
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Validate the email field first.
                          if (!formKey.currentState!.validate()) return;

                          // Capture messenger before any async gap so it is
                          // safe to use after the awaits complete.
                          final messenger = ScaffoldMessenger.of(context);

                          setDialogState(() => isLoading = true);

                          final email = emailController.text.trim();

                          // Step 1 — look up the account.
                          final user = await DatabaseHelper.instance.getUserByEmail(email);

                          if (user == null) {
                            // No account with this email.
                            setDialogState(() => isLoading = false);
                            if (!ctx.mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('No account found with that email address.'),
                                backgroundColor: kErrorColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.pop(dialogContext);
                            return;
                          }

                          // Step 2 — generate a temp password and update the DB.
                          final tempPassword = _generateTempPassword();
                          await DatabaseHelper.instance
                              .updateUserPassword(user['username'] as String, tempPassword);

                          // Step 3 — email the temp password to the customer.
                          final customerName = user['name'] as String;
                          final result = await EmailService().sendGoogleEmail(
                            recipientEmails: email,
                            subject: 'Your Temporary Password — Ali Grandson Spare Parts',
                            htmlBody: await EmailTemplates.forgotPasswordEmail(customerName, tempPassword),
                          );

                          setDialogState(() => isLoading = false);
                          if (!ctx.mounted) return;
                          Navigator.pop(dialogContext);

                          // Step 4 — show the outcome to the user.
                          final bool emailSent = result['success'] == true;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                emailSent
                                    ? 'Temporary password sent to $email. Check your inbox.'
                                    : 'Password reset, but email could not be sent. Contact support.',
                              ),
                              backgroundColor: emailSent ? kSuccessColor : kWarningColor,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
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

                  // ── Forgot password ────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
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
