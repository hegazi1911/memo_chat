import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  String _activeThemeName = 'Cyberpunk Dusk';

  String get activeThemeName => _activeThemeName;

  void setTheme(String themeName) {
    _activeThemeName = themeName;
    notifyListeners();
  }

  // Define HSL-tailored harmonious premium palettes

  // 1. Cyberpunk Dusk
  static final cyberpunkDarkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0B1E), // Extremely deep dark violet
    primaryColor: const Color(0xFFFF2E93), // Vibrant neon magenta
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF2E93),
      secondary: Color(0xFF00F0FF), // Radiant cyan
      surface: Color(0xFF191332), // Deep violet card
      error: Color(0xFFFF3838),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFFE2DDF7), // Soft lilac text
    ),
    cardColor: const Color(0xFF1A1435),
    dividerColor: const Color(0xFF2C2258),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF140F27),
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Color(0xFFE2DDF7)),
      bodyMedium: const TextStyle(color: Color(0xFFAAA3CD)),
    ),
  );

  // 2. Emerald Forest
  static final emeraldDarkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B1412), // Deep charcoal obsidian
    primaryColor: const Color(0xFF10B981), // Vivid emerald green
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF10B981),
      secondary: Color(0xFF34D399), // Refreshing mint
      surface: const Color(0xFF12221E), // Dark forest card
      error: Color(0xFFF87171),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Color(0xFFE6F4F1),
    ),
    cardColor: const Color(0xFF142722),
    dividerColor: const Color(0xFF1D3E35),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0E1A17),
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Color(0xFFE6F4F1)),
      bodyMedium: const TextStyle(color: Color(0xFF9EBFB8)),
    ),
  );

  // 3. Sunset Ember
  static final sunsetDarkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F1A), // Deep evening navy
    primaryColor: const Color(0xFFF97316), // Blazing orange
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF97316),
      secondary: Color(0xFFFBBF24), // Rich gold amber
      surface: Color(0xFF1A1A2E), // Evening violet card
      error: Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFFFFF7ED),
    ),
    cardColor: const Color(0xFF1C1C32),
    dividerColor: const Color(0xFF2E2E50),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF141426),
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Color(0xFFFFF7ED)),
      bodyMedium: const TextStyle(color: Color(0xFFC7BCAE)),
    ),
  );

  // 4. Midnight Stealth
  static final midnightDarkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF030303), // Absolute pure dark pitch black
    primaryColor: const Color(0xFFFFFFFF), // Radiant platinum white
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFF2563EB), // Electric blue accent
      surface: Color(0xFF121212), // Dark slate gray card
      error: Color(0xFFDC2626),
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF3F4F6),
    ),
    cardColor: const Color(0xFF151515),
    dividerColor: const Color(0xFF262626),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0A0A),
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Color(0xFFF3F4F6)),
      bodyMedium: const TextStyle(color: Color(0xFF9CA3AF)),
    ),
  );

  ThemeData get currentThemeData {
    ThemeData baseTheme;
    switch (_activeThemeName) {
      case 'Emerald Forest':
        baseTheme = emeraldDarkTheme;
        break;
      case 'Sunset Ember':
        baseTheme = sunsetDarkTheme;
        break;
      case 'Midnight Stealth':
        baseTheme = midnightDarkTheme;
        break;
      case 'Cyberpunk Dusk':
      default:
        baseTheme = cyberpunkDarkTheme;
        break;
    }

    // Wrap the selected theme in customized modern Google Fonts (Outfit or Inter)
    final textTheme = GoogleFonts.outfitTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      textTheme: textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.5, letterSpacing: 0.1),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 13.5, height: 1.45, letterSpacing: 0.1),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseTheme.colorScheme.surface.withOpacity(0.4),
        hintStyle: TextStyle(color: baseTheme.colorScheme.onSurface.withOpacity(0.35), fontSize: 14),
        labelStyle: TextStyle(color: baseTheme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseTheme.dividerColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseTheme.dividerColor.withOpacity(0.6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseTheme.colorScheme.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseTheme.colorScheme.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseTheme.colorScheme.primary,
          foregroundColor: baseTheme.colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: baseTheme.colorScheme.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.2),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(baseTheme.colorScheme.secondary.withOpacity(0.3)),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}
