import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Core colours of the redesign.
const Color kInk = Color(0xFF141414);
const Color kMuted = Color(0xFF6B6B6B);
const Color kOnGround = Color(0xFF3A3214);
const Color kSurface = Color(0xFFF5F5F5);
const Color kField = Color(0xFFF7F7F7);
const Color kHairline = Color(0xFFF0F0F0);

/// Barlow Condensed headline style used for screen titles.
TextStyle displayStyle(double size, {Color color = kInk}) =>
    GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1,
      color: color,
    );

/// Manrope body style.
TextStyle bodyStyle(
  double size, {
  FontWeight weight = FontWeight.w600,
  Color color = kInk,
  double? height,
  double? letterSpacing,
}) => GoogleFonts.manrope(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

/// One selectable colour theme: a flat ground colour plus its accent tints.
class AppPalette {
  final String name;
  final Color ground; // full-bleed screen colour
  final Color accent; // buttons, progress, active states
  final Color soft; // pale tint for chips / selected nav
  final Color second; // second half of the theme swatch

  const AppPalette(this.name, this.ground, this.accent, this.soft, this.second);
}

class ThemeProvider extends ChangeNotifier {
  static const List<AppPalette> palettes = [
    AppPalette(
      'Sunshine',
      Color(0xFFFFC727),
      Color(0xFFFFB81C),
      Color(0xFFFFF1C2),
      Color(0xFFFF9F43),
    ),
    AppPalette(
      'Tangerine',
      Color(0xFFFF9F43),
      Color(0xFFFF8A1F),
      Color(0xFFFFE3C2),
      Color(0xFFFF6B4A),
    ),
    AppPalette(
      'Mint',
      Color(0xFF8BD3B5),
      Color(0xFF5CC29C),
      Color(0xFFDDF3E9),
      Color(0xFF3FA98A),
    ),
    AppPalette(
      'Lilac',
      Color(0xFFB8A9FF),
      Color(0xFF9886F5),
      Color(0xFFE6E0FF),
      Color(0xFF7A68E8),
    ),
    AppPalette(
      'Rose',
      Color(0xFFFF9DB8),
      Color(0xFFFF7A9C),
      Color(0xFFFFDDE6),
      Color(0xFFE85D8A),
    ),
  ];

  static const _prefsKey = 'themeIndex';

  int _index = 0;

  int get index => _index;
  AppPalette get palette => palettes[_index];
  Color get ground => palette.ground;
  Color get accent => palette.accent;
  Color get soft => palette.soft;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefsKey) ?? 0;
    if (saved >= 0 && saved < palettes.length && saved != _index) {
      _index = saved;
      notifyListeners();
    }
  }

  Future<void> select(int index) async {
    if (index < 0 || index >= palettes.length || index == _index) return;
    _index = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, index);
  }
}
