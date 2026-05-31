// ============================================================
// session_manager.dart — Login Session Storage
// ============================================================
// When a user or admin successfully logs in, we save a small flag
// in SharedPreferences (think of it as a tiny key-value store on
// the device) so that the app "remembers" they are signed in even
// after it is closed and reopened.
//
// When the app starts, main.dart reads these flags to decide which
// screen to show first.  When the user logs out, clearSession()
// removes all saved values.
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

/// Manages login sessions for both customers and the admin.
/// All methods are static — call them without creating an instance:
///   `await SessionManager.setUserSession(...)`
class SessionManager {
  // ── Storage Keys ──────────────────────────────────────────────
  // These string constants are the keys used to read/write values
  // in SharedPreferences.  Keeping them here avoids typos.

  static const String _adminKey = 'admin_logged_in';       // bool flag
  static const String _userKey = 'user_logged_in';         // bool flag
  static const String _userEmailKey = 'user_email';        // user's email string
  static const String _userUsernameKey = 'user_username';  // user's username string
  static const String _adminEmailKey = 'admin_email';      // admin's email string

  // ── Write Methods ─────────────────────────────────────────────

  /// Saves a customer session.
  /// Also removes any admin session to prevent being logged in as both.
  static Future<void> setUserSession(String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userKey, true);
    await prefs.setString(_userUsernameKey, username);
    await prefs.setString(_userEmailKey, email);
    await prefs.remove(_adminKey); // Ensure admin flag is cleared
  }

  /// Saves an admin session.
  /// Also removes any user session.
  static Future<void> setAdminSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminKey, true);
    await prefs.setString(_adminEmailKey, email);
    await prefs.remove(_userKey); // Ensure user flag is cleared
  }

  // ── Read Methods ──────────────────────────────────────────────

  /// Returns true if an admin is currently logged in.
  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adminKey) ?? false; // Default to false if not set
  }

  /// Returns true if a customer is currently logged in.
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userKey) ?? false;
  }

  // ── Clear ─────────────────────────────────────────────────────

  /// Removes all session data — effectively logs out whoever is signed in.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
