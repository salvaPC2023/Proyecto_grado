import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/sesion.dart';
import '../../../nucleo/tema.dart';
import '../inicio/pantalla_inicio.dart';
import '../supervisores/pantalla_lista_supervisores.dart';
import 'pantalla_inicio_sesion.dart';

/// Primera pantalla de cada rol después de iniciar sesión (el administrador no tiene pantalla de inicio)
Widget pantallaPrincipal(SesionUsuario? sesion) =>
    sesion?.esAdministrador ?? false ? const PantallaListaSupervisores() : const PantallaInicio();

/// Al abrir la app: si hay una sesión guardada y vigente se entra directo; si no, se pide iniciar sesión.
/// Así un técnico que cerró la app con cierres pendientes los envía al volver, sin escribir su contraseña
class PantallaArranque extends ConsumerStatefulWidget {
  const PantallaArranque({super.key});

  @override
  ConsumerState<PantallaArranque> createState() => _PantallaArranqueState();
}

class _PantallaArranqueState extends ConsumerState<PantallaArranque> {
  @override
  void initState() {
    super.initState();
    _decidir();
  }

  Future<void> _decidir() async {
    final recuperada = await ref.read(sesionProvider.notifier).restaurar();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => recuperada ? pantallaPrincipal(ref.read(sesionProvider)) : const PantallaInicioSesion(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
