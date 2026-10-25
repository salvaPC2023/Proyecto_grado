import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nucleo/tema.dart';
import 'presentacion/pantallas/autenticacion/pantalla_arranque.dart';
import 'presentacion/widgets/sincronizador_cierres.dart';

void main() {
  runApp(const ProviderScope(child: AplicacionMantenimiento()));
}

class AplicacionMantenimiento extends StatelessWidget {
  const AplicacionMantenimiento({super.key});

  // para avisar desde el sincronizador, que está por encima de todas las pantallas
  static final _mensajero = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maintenance App',
      debugShowCheckedModeBanner: false,
      theme: temaClaro,
      scaffoldMessengerKey: _mensajero,
      // recupera la sesión guardada o pide iniciar sesión
      home: const PantallaArranque(),
      // la cola de cierres sin conexión se envía sola desde cualquier pantalla
      builder: (context, child) => SincronizadorCierres(mensajero: _mensajero, child: child!),
    );
  }
}
