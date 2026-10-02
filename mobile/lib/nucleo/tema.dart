import 'package:flutter/material.dart';

/// Paleta extraida del diseno de Figma ("interfaz nueva"), ajustada para
/// usar solo tonos azules (#131D8C como principal) — sin morados, por
/// seriedad de marca.
class ColoresApp {
  static const fondo = Color(0xFFEDF0FF);
  static const principal = Color(0xFF131D8C);
  static const gradienteInicio = Color(0xFF2563EB);
  static const gradienteFin = Color(0xFF131D8C);
  static const textoOscuro = Color(0xFF1E293B);
  static const textoLabel = Color(0xFF334155);
  static const textoSuave = Color(0xFF475569);
  static const textoPlaceholder = Color(0xFF94A3B8);
  static const superficie = Color(0xFFFFFFFF);
  static const campoFondo = Color(0xCCF8FAFC);
  static const campoBloqueadoFondo = Color(0xE6F1F5F9);
  static const campoBorde = Color(0xFFE2E8F0);
  static const badgeFondo = Color(0xFFEFF6FF);
  static const badgeBorde = Color(0xFFDBEAFE);
  static const chipProfesionFondo = Color(0x99EFF6FF);
  static const chipProfesionBorde = Color(0xFFBFDBFE);
  static const navFondo = Color(0xE6DBEAFE);
  static const navBorde = Color(0x80BFDBFE);
}

final temaClaro = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: ColoresApp.fondo,
  colorScheme: ColorScheme.light(
    primary: ColoresApp.principal,
    onPrimary: Colors.white,
    secondary: ColoresApp.gradienteInicio,
    onSecondary: Colors.white,
    surface: ColoresApp.superficie,
    onSurface: ColoresApp.textoOscuro,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: ColoresApp.textoOscuro,
    elevation: 0,
  ),
  textTheme: const TextTheme().apply(
    bodyColor: ColoresApp.textoOscuro,
    displayColor: ColoresApp.textoOscuro,
  ),
);
