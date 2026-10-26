import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nucleo/tema.dart';
import 'presentacion/pantallas/autenticacion/pantalla_arranque.dart';
import 'presentacion/widgets/registro_notificaciones.dart';
import 'presentacion/widgets/sincronizador_cierres.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // lee google-services.json; sin Firebase la app funciona igual, solo sin notificaciones
    await Firebase.initializeApp();
  } catch (_) {}
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
      // la cola de cierres sin conexión se envía sola y las notificaciones se registran desde cualquier pantalla
      builder: (context, child) => SincronizadorCierres(
        mensajero: _mensajero,
        child: RegistroNotificaciones(mensajero: _mensajero, child: child!),
      ),
    );
  }
}
