import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';

/// Tarjeta 23: registra el celular en el backend al iniciar sesión, para que lleguen los avisos de pasos sin
/// cerrar antes del fin del turno, y lo da de baja al cerrar sesión. Con la app abierta, Android no muestra la
/// notificación, así que se avisa en la parte de abajo de la pantalla
class RegistroNotificaciones extends ConsumerStatefulWidget {
  const RegistroNotificaciones({super.key, required this.child, required this.mensajero});
  final Widget child;
  final GlobalKey<ScaffoldMessengerState> mensajero;

  @override
  ConsumerState<RegistroNotificaciones> createState() => _RegistroNotificacionesState();
}

class _RegistroNotificacionesState extends ConsumerState<RegistroNotificaciones> {
  final List<StreamSubscription<Object>> _suscripciones = [];

  bool get _conSesion => (ref.read(sesionProvider)?.id ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    final push = ref.read(servicioPushProvider);
    _suscripciones
      ..add(push.tokensNuevos.listen((token) {
        if (_conSesion) _registrar(token);
      }))
      ..add(push.enPrimerPlano.listen((notificacion) {
        widget.mensajero.currentState?.showSnackBar(SnackBar(
          content: Text('${notificacion.titulo}: ${notificacion.cuerpo}'),
          duration: const Duration(seconds: 8),
        ));
      }));
    // si la sesión se recuperó antes de montar este widget
    if (_conSesion) _registrarEsteCelular();
  }

  @override
  void dispose() {
    for (final suscripcion in _suscripciones) {
      suscripcion.cancel();
    }
    super.dispose();
  }

  Future<void> _registrarEsteCelular() async {
    try {
      final token = await ref.read(servicioPushProvider).obtenerToken();
      if (token != null) await _registrar(token);
    } catch (_) {
      // sin notificaciones la app funciona igual; se vuelve a intentar en el próximo inicio de sesión
    }
  }

  Future<void> _registrar(String token) async {
    try {
      await ref.read(repositorioNotificacionesProvider).registrarDispositivo(token);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sesionProvider.select((s) => s?.id), (anterior, actual) {
      if (actual != null && actual.isNotEmpty && actual != anterior) {
        _registrarEsteCelular();
      } else if (actual == null && anterior != null) {
        // otra persona puede iniciar sesión en este celular: no debe recibir los avisos de quien salió
        ref.read(servicioPushProvider).borrarToken().catchError((Object _) {});
      }
    });
    return widget.child;
  }
}
