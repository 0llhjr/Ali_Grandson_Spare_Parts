// ============================================================
// app_colors.dart — Colour Palette
// ============================================================
// All colours used across the app are defined here in one place.
// Centralising colours means:
//   • Changing the brand colour only requires editing this file.
//   • Widgets stay consistent because they all pull from the same source.
//
// Two patterns are provided:
//   1. Top-level constants (e.g. kPrimaryColor) — used directly in widgets.
//   2. AppColors class (e.g. AppColors.primary) — object-oriented style.
// Both refer to the same colours; pick whichever style feels natural.
// ============================================================

import 'package:flutter/material.dart';

// ── Brand Colours ─────────────────────────────────────────────

/// Deep maroon — the main brand colour used on buttons, the app bar, etc.
const Color kPrimaryColor = Color(0xFF800000);

/// Lighter maroon shade for hover states or gradients.
const Color kPrimaryLight = Color(0xFFA52A2A);

/// Darker maroon shade for gradient bottoms or pressed states.
const Color kPrimaryDark = Color(0xFF5D0000);

/// Almost-black — used for headings and secondary elements.
const Color kSecondaryColor = Color(0xFF1A1A1A);

/// Gold/amber — used for accent badges and highlights.
const Color kAccentColor = Color(0xFFD4AF37);

/// Blue for clickable links.
const Color kLinkColor = Color(0xFF0056B3);

// ── Background & Surface ──────────────────────────────────────

/// Light grey page background — gives screens a gentle off-white look.
const Color kBackgroundColor = Color(0xFFF4F7F6);

/// Pure white — used for cards, input fields, modals.
const Color kSurfaceColor = Color(0xFFFFFFFF);

// ── Status Colours ────────────────────────────────────────────

/// Green — success messages, "In Stock" badges.
const Color kSuccessColor = Color(0xFF28A745);

/// Teal — informational banners.
const Color kInfoColor = Color(0xFF17A2B8);

/// Amber — warnings, low-stock alerts.
const Color kWarningColor = Color(0xFFFFC107);

/// Red — errors, "Out of Stock", delete actions.
const Color kErrorColor = Color(0xFFDC3545);

// ── Text Colours ──────────────────────────────────────────────

/// Near-black for main body text and headings.
const Color kTextPrimary = Color(0xFF212529);

/// Medium grey for hints, labels, and secondary information.
const Color kTextSecondary = Color(0xFF6C757D);

// ── Grey Scale ────────────────────────────────────────────────
// Nine grey shades from lightest (100) to darkest (900).

const Color kGrey100 = Color(0xFFF8F9FA);
const Color kGrey200 = Color(0xFFE9ECEF);
const Color kGrey300 = Color(0xFFDEE2E6);
const Color kGrey400 = Color(0xFFCED4DA);
const Color kGrey500 = Color(0xFFADB5BD);
const Color kGrey600 = Color(0xFF6C757D);
const Color kGrey700 = Color(0xFF495057);
const Color kGrey800 = Color(0xFF343A40);
const Color kGrey900 = Color(0xFF212529);

// Semantic aliases for common grey use cases.
const Color kGreyLight  = kGrey200; // Borders, dividers, field backgrounds
const Color kGreyMedium = kGrey500; // Placeholder icons, subtle text
const Color kGreyDark   = kGrey700; // Disabled labels

// ── Legacy Aliases ────────────────────────────────────────────
// Kept for backward compatibility with older widget code.

const Color maroon = kPrimaryColor;
const Color silver = kGreyMedium;

// ── AppColors Class ───────────────────────────────────────────
// Provides the same colours as static properties on a class.
// Useful when you prefer `AppColors.primary` over `kPrimaryColor`.

class AppColors {
  static const Color primary      = kPrimaryColor;
  static const Color primaryLight = kPrimaryLight;
  static const Color primaryDark  = kPrimaryDark;
  static const Color secondary    = kSecondaryColor;
  static const Color accent       = kAccentColor;
  static const Color background   = kBackgroundColor;
  static const Color surface      = kSurfaceColor;
  static const Color success      = kSuccessColor;
  static const Color info         = kInfoColor;
  static const Color warning      = kWarningColor;
  static const Color error        = kErrorColor;
  static const Color textPrimary  = kTextPrimary;
  static const Color textSecondary = kTextSecondary;
  static const Color grey100 = kGrey100;
  static const Color grey200 = kGrey200;
  static const Color grey300 = kGrey300;
  static const Color grey400 = kGrey400;
  static const Color grey500 = kGrey500;
  static const Color grey600 = kGrey600;
  static const Color grey700 = kGrey700;
  static const Color grey800 = kGrey800;
  static const Color grey900 = kGrey900;

  /// Maroon gradient used on the admin dashboard revenue card and drawer header.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [kPrimaryColor, kPrimaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
