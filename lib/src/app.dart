// ============================================================
// app.dart — Root Widget and App Configuration
// ============================================================
// MyApp is the top-level widget of the entire application.
// It sets up:
//   • The global colour theme (maroon, dark, gold).
//   • Text styles used across every screen.
//   • Named routes so any screen can navigate to another by name.
//   • The very first screen shown based on the login state passed
//     from main.dart.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/features/home/presentation/pages/home_page.dart';
import 'package:alis_grandson_app/src/features/auth/presentation/pages/login_user_page.dart';
import 'package:alis_grandson_app/src/features/auth/presentation/pages/login_admin_page.dart';
import 'package:alis_grandson_app/src/features/auth/presentation/pages/signup_user_page.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:alis_grandson_app/src/features/dashboard/presentation/pages/user_dashboard_page.dart';
import 'package:alis_grandson_app/src/features/misc/presentation/pages/misc_page.dart';
import 'package:alis_grandson_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:alis_grandson_app/src/features/orders/presentation/pages/user_orders_page.dart';
import 'package:alis_grandson_app/src/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:alis_grandson_app/src/features/cart/presentation/pages/cart_page.dart';
import 'package:alis_grandson_app/src/features/support/presentation/pages/faq_page.dart';

/// MyApp is a StatelessWidget because the app-level theme never changes at runtime.
/// It receives two boolean flags from main.dart to decide which screen to open first.
class MyApp extends StatelessWidget {
  /// True if an admin was already signed in when the app launched.
  final bool isAdminLoggedIn;

  /// True if a regular customer was already signed in when the app launched.
  final bool isUserLoggedIn;

  const MyApp({super.key, required this.isAdminLoggedIn, required this.isUserLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ali Grandsons',

      // Hide the red "DEBUG" banner shown in the top-right corner during development.
      debugShowCheckedModeBanner: false,

      // Apply the global Material 3 theme to every widget in the app.
      theme: ThemeData(
        useMaterial3: true,

        // Build a colour scheme from the primary maroon colour.
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          surface: kSurfaceColor,
          background: kBackgroundColor,
          error: kErrorColor,
        ),

        scaffoldBackgroundColor: kBackgroundColor,

        // Default text styles used throughout the app.
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kTextPrimary),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kTextPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: kTextPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: kTextSecondary),
        ),

        // Default style for the top app bar on every screen.
        appBarTheme: const AppBarTheme(
          backgroundColor: kSurfaceColor,
          foregroundColor: kPrimaryColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: kPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: kPrimaryColor),
        ),

        // Default style for all ElevatedButton widgets.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 54), // Full-width, tall button
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Default style for all TextField / TextFormField widgets.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurfaceColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kGreyLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kGreyLight),
          ),
          // Highlight the border in maroon when the user taps a field.
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          ),
          labelStyle: const TextStyle(color: kTextSecondary),
          floatingLabelStyle: const TextStyle(color: kPrimaryColor),
        ),

        // Default style for all Card widgets.
        cardTheme: CardThemeData(
          color: kSurfaceColor,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      // Decide which screen to show first based on who is already logged in.
      home: _getInitialScreen(),

      // Named routes allow screens to navigate to each other using a string name.
      routes: {
        '/home':            (context) => const HomePage(),
        '/login_user':      (context) => const LoginUserPage(),
        '/login_admin':     (context) => const LoginAdminPage(),
        '/signup_user':     (context) => const SignupUserPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        '/user_dashboard':  (context) => const UserDashboardPage(),
        '/misc':            (context) => const MiscPage(),
        '/profile':         (context) => const ProfilePage(),
        '/my_orders':       (context) => const UserOrdersPage(),
        '/wishlist':        (context) => const WishlistPage(),
        '/cart':            (context) => const CartPage(),
        '/chat':            (context) => const FAQPage(),
      },
    );
  }

  /// Returns the correct first screen based on the saved login state.
  /// Priority: Admin > User > Home (landing page).
  Widget _getInitialScreen() {
    if (isAdminLoggedIn) return const AdminDashboardPage();
    if (isUserLoggedIn) return const UserDashboardPage();
    return const HomePage();
  }
}
