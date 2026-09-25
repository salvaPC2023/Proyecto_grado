import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nucleo/tema.dart';
import 'presentacion/pantallas/autenticacion/pantalla_inicio_sesion.dart';

void main() {
  runApp(const ProviderScope(child: AplicacionMantenimiento()));
}

class AplicacionMantenimiento extends StatelessWidget {
  const AplicacionMantenimiento({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maintenance App',
      theme: temaOscuro,
      home: const PantallaInicioSesion(),
    );
  }
}
