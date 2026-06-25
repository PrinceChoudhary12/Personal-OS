// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get displayXL => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -2.0,
        height: 1.0,
      );

  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.2,
      );

  // ── Headings ──────────────────────────────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.3,
      );

  static TextStyle get headingMedium => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.3,
      );

  static TextStyle get headingSmall => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.4,
      );

  // ── Legacy aliases ────────────────────────────────────────────────────────
  static TextStyle get titleLarge => headingLarge;

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
      );

  // ── Labels ────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      );

  // ── Caption ───────────────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.4,
      );

  // ── Numeric / Mono ────────────────────────────────────────────────────────
  static TextStyle get numericDisplay => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        height: 1.0,
      );

  static TextStyle get numericLarge => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
      );
}
