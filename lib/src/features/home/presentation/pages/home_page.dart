// ============================================================
// home_page.dart — Landing / Splash Screen
// ============================================================
// This is the first screen a brand-new (logged-out) visitor sees.
// It shows the company logo and three action buttons:
//   • Customer Login  → goes to the user login screen
//   • Create Account  → goes to the sign-up screen
//   • Admin Access    → goes to the admin-only login screen
//
// On page load it also silently checks whether a session was
// saved from a previous run.  If someone is already logged in it
// redirects them to the correct dashboard automatically.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';

/// The landing page shown to users who are not yet logged in.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Check for a saved login session as soon as this screen is built.
    _checkSession();
  }

  /// Redirects to the appropriate dashboard if a session already exists.
  /// `mounted` checks ensure navigation only happens while this widget is alive.
  Future<void> _checkSession() async {
    if (await SessionManager.isAdminLoggedIn()) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else if (await SessionManager.isUserLoggedIn()) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/user_dashboard');
    }
    // If nobody is logged in, stay on this screen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // Subtle gradient from white at the top to light grey at the bottom.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kSurfaceColor, kBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),

                // ── Logo ──────────────────────────────────────
                // Hero widget enables a smooth animation when navigating to
                // the login screen (the logo "flies" to its new position).
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'logo', // Must match the Hero tag on the login screen
                    child: CircleAvatar(
                      radius: 90,
                      backgroundColor: kSurfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Image.asset('lib/assets/Imgs/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // ── App Name & Tagline ─────────────────────────
                const Text(
                  'ALI GRANDSONS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                    letterSpacing: 2.0,
                  ),
                ),
                const Text(
                  'Premium Spare Parts',
                  style: TextStyle(
                    fontSize: 16,
                    color: kTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),

                const Spacer(flex: 3),

                // ── Primary Action: Customer Login ─────────────
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login_user'),
                  child: const Text('CUSTOMER LOGIN'),
                ),

                const SizedBox(height: 16),

                // ── Secondary Action: Create Account ──────────
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup_user'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: kPrimaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: kPrimaryColor,
                  ),
                  child: const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 24),

                // ── Tertiary Action: Admin Access (subtle) ─────
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login_admin'),
                  child: Text(
                    'ADMIN ACCESS',
                    style: TextStyle(
                      color: kSecondaryColor.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
