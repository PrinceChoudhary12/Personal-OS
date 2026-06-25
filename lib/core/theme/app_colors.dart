// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── Brand Colors ─────────────────────────────────────────────────────────
  static const Color primary   = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Purple
  static const Color accent    = Color(0xFF06B6D4); // Cyan
  static const Color success   = Color(0xFF22C55E); // Green
  static const Color warning   = Color(0xFFF59E0B); // Amber
  static const Color error     = Color(0xFFEF4444); // Red

  // ── Dark Palette ─────────────────────────────────────────────────────────
  static const Color darkBackground  = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface     = Color(0xFF111827); // Gray 900
  static const Color darkSurfaceCard = Color(0xFF1E293B); // Slate 800
  static const Color darkSidebar     = Color(0xFF0B1220); // Deeper slate
  static const Color darkBorder      = Color(0xFF334155); // Slate 600
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400

  // ── Light Palette ─────────────────────────────────────────────────────────
  static const Color lightBackground  = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface     = Color(0xFFFFFFFF); // White
  static const Color lightCard        = Color(0xFFFFFFFF); // White
  static const Color lightSidebar     = Color(0xFFEEF2FF); // Indigo 50
  static const Color lightBorder      = Color(0xFFE2E8F0); // Slate 200
  static const Color lightTextPrimary   = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Game / Module Colors ──────────────────────────────────────────────────
  static const Color gameMemory   = Color(0xFF06B6D4); // Cyan
  static const Color gameReaction = Color(0xFF8B5CF6); // Purple
  static const Color gameMath     = Color(0xFFF59E0B); // Orange
  static const Color gameSequence = Color(0xFF22C55E); // Green
  static const Color gameRecall   = Color(0xFF6366F1); // Indigo

  static const Color subjectIndigo = Color(0xFF6366F1);
  static const Color subjectGreen  = Color(0xFF22C55E);
  static const Color subjectOrange = Color(0xFFF59E0B);
  static const Color subjectPurple = Color(0xFF8B5CF6);

  // ── Shadow ────────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.25),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
}
