import 'package:flutter/material.dart';

class CardColorHelper {
  static const List<Color> _colors = [
    Color(0xFFEDFCEC),
    Color(0xFFFEF8E0),
    Color(0xFFDFF0FE),
    Color(0xFFFFF0E1),
    Color(0xFFFFE7E1),
    Color(0xFFE1E0FE),
  ];

  static Color getColor(int index) {
    return _colors[index % _colors.length];
  }
}
