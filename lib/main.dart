// ============================================================
// main.dart — Application Entry Point
// ============================================================
// This is the very first file that runs when the app starts.
// It does three things before showing any screen:
//   1. Loads secret settings from the .env file (like email keys).
//   2. Seeds the database with sample spare parts if it is empty.
//   3. Checks whether a user or admin is already logged in, so
//      the app can open the correct screen directly.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:alis_grandson_app/src/app.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';
import 'package:alis_grandson_app/src/features/catalog/data/product_data.dart';

/// The main() function is the starting point of every Dart/Flutter app.
/// The `async` keyword means it can wait for tasks to finish before moving on.
void main() async {
  // Tell Flutter to finish setting up its engine before we run any async code.
  WidgetsFlutterBinding.ensureInitialized();

  // Try to read the .env file that holds private configuration values
  // (e.g. the Google Script URL used for sending emails).
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment variables loaded successfully");
  } catch (e) {
    // If the file is missing, print the error but continue — the app still works.
    debugPrint("Error loading .env file: $e");
  }

  // Fill the database with 5 default spare-part products the first time the app runs.
  await ProductData.seedDatabase();

  // Check whether someone is already signed in (session was saved from a previous run).
  final isAdminLoggedIn = await SessionManager.isAdminLoggedIn();
  final isUserLoggedIn = await SessionManager.isUserLoggedIn();

  // Start the Flutter app and pass the session flags so it opens the right screen.
  runApp(MyApp(
    isAdminLoggedIn: isAdminLoggedIn,
    isUserLoggedIn: isUserLoggedIn,
  ));
}
