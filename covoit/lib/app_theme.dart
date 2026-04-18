import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const green        = Color(0xFF1D9E75);
  static const greenLight   = Color(0xFFE1F5EE);
  static const greenDark    = Color(0xFF0F6E56);
  static const greenDeep    = Color(0xFF085041);
  static const prime        = Color(0xFFEF9F27);
  static const primeBg      = Color(0xFFFAEEDA);
  static const primeDark    = Color(0xFF854F0B);
  static const coral        = Color(0xFFD85A30);
  static const coralLight   = Color(0xFFFAECE7);
  static const gray50       = Color(0xFFF1EFE8);
  static const gray100      = Color(0xFFD3D1C7);
  static const gray400      = Color(0xFF888780);
  static const gray600      = Color(0xFF5F5E5A);
  static const gray800      = Color(0xFF444441);
  static const gray900      = Color(0xFF2C2C2A);
  static const dark900      = Color(0xFF111110);
  static const dark800      = Color(0xFF1A1A18);
  static const dark700      = Color(0xFF242422);
  static const dark600      = Color(0xFF2E2E2C);
  static const dark500      = Color(0xFF3A3A38);
}

TextTheme _outfit(TextTheme base) => GoogleFonts.outfitTextTheme(base);

TextStyle _btn() =>
    GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600);

class AppTheme {
  // ──────────────────────────────────────── LIGHT ──
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      textTheme: _outfit(base.textTheme),
      scaffoldBackgroundColor: AppColors.gray50,
      colorScheme: const ColorScheme.light(
        primary:                 AppColors.green,
        primaryContainer:        AppColors.greenLight,
        secondary:               AppColors.prime,
        secondaryContainer:      AppColors.primeBg,
        surface:                 Colors.white,
        surfaceContainerHighest: AppColors.gray50,
        onPrimary:               Colors.white,
        onSecondary:             AppColors.primeDark,
        onSurface:               AppColors.gray900,
        onSurfaceVariant:        AppColors.gray600,
        error:                   AppColors.coral,
        outline:                 AppColors.gray100,
        outlineVariant:          Color(0x1A000000),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1A000000), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1A000000), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1A000000), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _btn(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green,
          side: const BorderSide(color: AppColors.green, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _btn(),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.green,
        unselectedItemColor: AppColors.gray400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1A000000), thickness: 0.5, space: 0),
    );
  }

  // ──────────────────────────────────────── DARK ──
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      textTheme: _outfit(base.textTheme),
      scaffoldBackgroundColor: AppColors.dark900,
      colorScheme: const ColorScheme.dark(
        primary:                 AppColors.green,
        primaryContainer:        AppColors.greenDeep,
        secondary:               AppColors.prime,
        secondaryContainer:      Color(0xFF3A2800),
        surface:                 AppColors.dark800,
        surfaceContainerHighest: AppColors.dark700,
        onPrimary:               Colors.white,
        onSecondary:             AppColors.prime,
        onSurface:               Color(0xFFF0EFE8),
        onSurfaceVariant:        AppColors.gray100,
        error:                   Color(0xFFFF7B6B),
        outline:                 AppColors.dark500,
        outlineVariant:          Color(0x33FFFFFF),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dark800,
        foregroundColor: const Color(0xFFF0EFE8),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: const Color(0xFFF0EFE8)),
        iconTheme: const IconThemeData(color: Color(0xFFF0EFE8)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.dark800,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33FFFFFF), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark700,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x33FFFFFF), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x33FFFFFF), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _btn(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green,
          side: const BorderSide(color: AppColors.green, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _btn(),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.dark800,
        selectedItemColor: AppColors.green,
        unselectedItemColor: AppColors.gray400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x33FFFFFF), thickness: 0.5, space: 0),
    );
  }
}
