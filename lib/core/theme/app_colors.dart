import 'package:flutter/material.dart';

/// Centralized color palette for the Melody app.
/// Dark theme with fresh, vibrant accents that break the darkness.
class AppColors {
  AppColors._();

  // Primary palette — fresh & modern
  static const Color primary = Color(0xFFFFD93D); // Vert émeraude / menthe vif
  static const Color primaryLight = Color(0xFF5DFFC2); // Menthe clair
  static const Color secondary = Color(0xFF7C5CFC); // Violet électrique
  static const Color accent = Color(0xFF00E09E); // Doré / Ambre chaud

  // Background & Surfaces
  static const Color background = Color(0xFF0D0D12); // Noir profond
  static const Color surface = Color(0xFF16161F); // Surface sombre
  static const Color surfaceLight = Color(0xFF1F1F2E); // Cards, bottom sheets
  static const Color surfaceVariant = Color(0xFF2A2A3C); // Éléments surélevés

  // Text
  static const Color textPrimary = Color(0xFFF5F5F7); // Blanc pur
  static const Color textSecondary = Color(0xFFA0A0B2); // Gris lavande
  static const Color textTertiary = Color(0xFF6C6C80); // Gris foncé

  // Utility
  static const Color error = Color(0xFFFF4757);
  static const Color success = Color(0xFF2ED573);

  // Gradients — le punch visuel de l'app
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E09E), Color(0xFF7C5CFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF7C5CFC), Color(0xFF44B4E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF16161F), Color(0xFF0D0D12)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
