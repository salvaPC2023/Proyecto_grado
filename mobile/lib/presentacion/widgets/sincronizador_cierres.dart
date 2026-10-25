import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/sesion.dart';
import '../viewmodels/cola_cierres_vm.dart';

/// Envía la cola de cierres sin que el técnico haga nada: cuando vuelve la conexión, cuando vuelve a la app,
/// cuando inicia sesión y, mientras queden pendientes, cada 30 segundos (la red puede volver sin aviso).
/// Envuelve toda la app, por eso funciona en cualquier pantalla
class SincronizadorCierres extends ConsumerStatefulWidget {
  const SincronizadorCierres({super.key, required this.child, required this.mensajero});
  final Widget child;
  final GlobalKey<ScaffoldMessengerState> mensajero;

  static const intervalo = Duration(seconds: 30);

  @override
  ConsumerState<SincronizadorCierres> createState() => _SincronizadorCierresState();
}

class _SincronizadorCierresState extends ConsumerState<SincronizadorCierres> with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _conexion;
  Timer? _reintento;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _conexion = Connectivity().onConnectivityChanged.listen((resultado) {
      if (!resultado.contains(ConnectivityResult.none)) _enviar();
    });
    _reintento = Timer.periodic(SincronizadorCierres.intervalo, (_) => _enviar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conexion?.cancel();
    _reintento?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _enviar();
  }

  Future<void> _enviar() async {
    // sin pendientes no se llama al servidor
    if (ref.read(misCierresEnColaProvider).every((c) => c.rechazado)) return;
    final enviados = await ref.read(colaCierresViewModelProvider.notifier).enviarPendientes();
    if (enviados > 0 && mounted) {
      widget.mensajero.currentState?.showSnackBar(SnackBar(
        content: Text(enviados == 1 ? 'Se envió 1 cierre guardado sin conexión' : 'Se enviaron $enviados cierres guardados sin conexión'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // al iniciar sesión (o recuperarla al abrir la app) se envía lo que quedó pendiente
    ref.listen(sesionProvider.select((s) => s?.id), (anterior, actual) {
      if (actual != null && actual.isNotEmpty) _enviar();
    });
    return widget.child;
  }
}
