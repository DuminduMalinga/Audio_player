import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  List<Color> _primaryGradient = [Colors.deepPurple, Colors.pinkAccent];

  List<Color> get primaryGradient => _primaryGradient;

  void setGradient(List<Color> gradient) {
    _primaryGradient = gradient;
    notifyListeners();
  }
}
