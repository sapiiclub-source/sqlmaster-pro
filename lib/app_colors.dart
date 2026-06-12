import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF141824);
  static const Color surfaceVariant = Color(0xFF1E2235);
  static const Color primary = Color(0xFF00BCD4);
  static const Color primaryDark = Color(0xFF0097A7);
  static const Color accent = Color(0xFFFF6B35);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color xpColor = Color(0xFFFFD700);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textHint = Color(0xFF607D8B);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color secondary = Color(0xFFB0BEC5);
  static const Color gold = Color(0xFFFFD700);
  static const Color orange = Color(0xFFFF6B35);

  static const List<Color> worldColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFFC62828),
  ];

  static const List<String> worldNames = [
    'Mundo 1: SELECT Básico',
    'Mundo 2: Filtros y Orden',
    'Mundo 3: Joins y Relaciones',
    'Mundo 4: Agregación y Grupos',
    'Mundo 5: Subconsultas y Avanzado',
  ];

  static const List<String> levelNames = [
    'Estudiante SQL',
    'Aprendiz de Datos',
    'Consultor Junior',
    'Analista SQL',
    'Desarrollador de BD',
    'Arquitecto de Datos',
    'Experto en Consultas',
    'Maestro SQL',
    'Elite DBA',
    'Grand Master DBA',
  ];

  static Color worldColor(int world) {
    if (world < 0 || world >= worldColors.length) return primary;
    return worldColors[world];
  }

  static String levelName(int xp) {
    if (xp < 100) return levelNames[0];
    if (xp < 300) return levelNames[1];
    if (xp < 600) return levelNames[2];
    if (xp < 1000) return levelNames[3];
    if (xp < 1500) return levelNames[4];
    if (xp < 2200) return levelNames[5];
    if (xp < 3000) return levelNames[6];
    if (xp < 4000) return levelNames[7];
    if (xp < 5500) return levelNames[8];
    return levelNames[9];
  }
}