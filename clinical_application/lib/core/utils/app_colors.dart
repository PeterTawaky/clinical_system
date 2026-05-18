import 'package:flutter/material.dart';

/// AppColors — Clinical Management System
/// Palette philosophy: Trust · Clarity · Calm Authority
///
/// Primary   → Deep Teal-Navy   (medical authority & professionalism)
/// Secondary → Soft Cyan-Steel  (supportive actions & highlights)
/// Neutral   → Cool Blue-Grays  (backgrounds, borders, text hierarchy)
/// Semantic  → Precise status colors (success, warning, error, info)
class AppColors {
  AppColors._(); // Prevent instantiation

  // ─────────────────────────────────────────
  // PRIMARY — Deep Clinical Teal
  // ─────────────────────────────────────────
  static const Color primary          = Color(0xFF0A5C73); // Deep teal — main brand
  static const Color primaryLight     = Color(0xFF1A7A95); // Lighter teal — hover/active
  static const Color primaryDark      = Color(0xFF063D4E); // Darker teal — pressed states
  static const Color primaryContainer = Color(0xFFD6EEF4); // Tint — chips, badges, backgrounds
  static const Color onPrimary        = Color(0xFFFFFFFF); // Text/icons on primary

  // ─────────────────────────────────────────
  // SECONDARY — Soft Steel Blue
  // ─────────────────────────────────────────
  static const Color secondary          = Color(0xFF3A7CA5); // Steel blue — secondary actions
  static const Color secondaryLight     = Color(0xFF5A99C2); // Lighter steel blue
  static const Color secondaryDark      = Color(0xFF255E82); // Darker steel blue
  static const Color secondaryContainer = Color(0xFFDCEDF8); // Soft tint
  static const Color onSecondary        = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────
  // ACCENT — Clinical Indigo
  // ─────────────────────────────────────────
  static const Color accent          = Color(0xFF4F6FA0); // Muted indigo — tabs, icons
  static const Color accentLight     = Color(0xFF7492BC);
  static const Color accentContainer = Color(0xFFE3EAF5);

  // ─────────────────────────────────────────
  // SEMANTIC — Status Colors
  // ─────────────────────────────────────────

  // Success — Confirmed, Completed, Stable
  static const Color success          = Color(0xFF1A8A5A);
  static const Color successLight     = Color(0xFF2DAE72);
  static const Color successContainer = Color(0xFFD4F0E4);
  static const Color onSuccess        = Color(0xFFFFFFFF);

  // Warning — Pending, Attention Needed
  static const Color warning          = Color(0xFFD4860A);
  static const Color warningLight     = Color(0xFFF0A730);
  static const Color warningContainer = Color(0xFFFFF0D6);
  static const Color onWarning        = Color(0xFFFFFFFF);

  // Error / Critical — Urgent, Failed, Critical
  static const Color error          = Color(0xFFBF2A2A);
  static const Color errorLight     = Color(0xFFD94F4F);
  static const Color errorContainer = Color(0xFFF9DEDE);
  static const Color onError        = Color(0xFFFFFFFF);

  // Info — Informational, Notes, In-Progress
  static const Color info          = Color(0xFF1A6FA8);
  static const Color infoLight     = Color(0xFF3A8DC8);
  static const Color infoContainer = Color(0xFFD6EAFA);
  static const Color onInfo        = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────
  // NEUTRAL — Cool Blue-Grays
  // ─────────────────────────────────────────
  static const Color neutral900 = Color(0xFF0F1B24); // Near black — primary text
  static const Color neutral800 = Color(0xFF1E2E3A); // Dark — headings
  static const Color neutral700 = Color(0xFF2F4457); // Dark gray — subheadings
  static const Color neutral600 = Color(0xFF445E75); // Medium — body text
  static const Color neutral500 = Color(0xFF607D94); // Muted — secondary text
  static const Color neutral400 = Color(0xFF8FA8BC); // Light — placeholder, hints
  static const Color neutral300 = Color(0xFFB8CDD9); // Lighter — disabled text
  static const Color neutral200 = Color(0xFFD8E5ED); // Border — dividers, strokes
  static const Color neutral100 = Color(0xFFECF2F6); // Surface — input backgrounds
  static const Color neutral50  = Color(0xFFF5F9FB); // Near white — card backgrounds

  // ─────────────────────────────────────────
  // BACKGROUNDS & SURFACES
  // ─────────────────────────────────────────
  static const Color background        = Color(0xFFF2F7FA); // App background
  static const Color surface           = Color(0xFFFFFFFF); // Cards, sheets, dialogs
  static const Color surfaceVariant    = Color(0xFFECF2F6); // Alternate surface
  static const Color surfaceOverlay    = Color(0xFFF5F9FB); // Subtle hover overlay
  static const Color inverseSurface    = Color(0xFF1E2E3A); // Dark surface (tooltips, snackbars)
  static const Color onInverseSurface  = Color(0xFFECF2F6);

  // ─────────────────────────────────────────
  // TEXT
  // ─────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF0F1B24); // Main content text
  static const Color textSecondary  = Color(0xFF445E75); // Supporting text
  static const Color textMuted      = Color(0xFF8FA8BC); // Hints, placeholders
  static const Color textDisabled   = Color(0xFFB8CDD9); // Disabled state
  static const Color textOnDark     = Color(0xFFFFFFFF); // Text on dark backgrounds
  static const Color textLink       = Color(0xFF1A7A95); // Hyperlinks

  // ─────────────────────────────────────────
  // BORDERS & DIVIDERS
  // ─────────────────────────────────────────
  static const Color border        = Color(0xFFD8E5ED); // Default borders
  static const Color borderFocus   = Color(0xFF0A5C73); // Input focus ring
  static const Color borderError   = Color(0xFFBF2A2A); // Error border
  static const Color divider       = Color(0xFFECF2F6); // Section dividers

  // ─────────────────────────────────────────
  // CLINICAL-SPECIFIC STATUS CHIPS
  // (Patient status, appointment tags, etc.)
  // ─────────────────────────────────────────
  static const Color statusActive     = Color(0xFF1A8A5A); // Active / Admitted
  static const Color statusScheduled  = Color(0xFF1A6FA8); // Scheduled
  static const Color statusPending    = Color(0xFFD4860A); // Pending / Waiting
  static const Color statusCritical   = Color(0xFFBF2A2A); // Critical / Emergency
  static const Color statusDischarged = Color(0xFF607D94); // Discharged / Closed
  static const Color statusCancelled  = Color(0xFF8FA8BC); // Cancelled / No-show

  // ─────────────────────────────────────────
  // OVERLAY & SHADOW
  // ─────────────────────────────────────────
  static const Color scrim           = Color(0x80000000); // Modal backdrop (50% black)
  static const Color shadowSoft      = Color(0x14445E75); // Soft shadow (~8% neutral700)
  static const Color shadowMedium    = Color(0x22445E75); // Card shadow (~13%)

  // ─────────────────────────────────────────
  // CONVENIENCE: MaterialColor swatch for ThemeData
  // ─────────────────────────────────────────
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF0A5C73,
    <int, Color>{
      50:  Color(0xFFD6EEF4),
      100: Color(0xFFADD9E8),
      200: Color(0xFF7DC1D8),
      300: Color(0xFF4DA8C8),
      400: Color(0xFF2990B0),
      500: Color(0xFF0A5C73), // primary
      600: Color(0xFF084F64),
      700: Color(0xFF064051),
      800: Color(0xFF04303E),
      900: Color(0xFF021F29),
    },
  );
}