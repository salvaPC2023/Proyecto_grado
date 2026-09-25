import 'package:flutter/material.dart';

class ColoresApp {
  static const fondo = Color(0xFF0F172A);
  static const principal = Color(0xFF0EA5A4);
  static const secundario = Color(0xFF38BDF8);
  static const texto = Color(0xFFF8FAFC);
}

final temaOscuro = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: ColoresApp.fondo,
  colorScheme: ColorScheme.dark(
    primary: ColoresApp.principal,
    onPrimary: ColoresApp.texto,
    secondary: ColoresApp.secundario,
    onSecondary: ColoresApp.fondo,
    surface: ColoresApp.fondo,
    onSurface: ColoresApp.texto,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: ColoresApp.fondo,
    foregroundColor: ColoresApp.texto,
    elevation: 0,
  ),
  textTheme: const TextTheme().apply(
    bodyColor: ColoresApp.texto,
    displayColor: ColoresApp.texto,
  ),
);
