import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/orden_trabajo.dart';
import '../../../nucleo/sesion.dart';
import '../../../nucleo/tema.dart';
import '../../widgets/avisos_conexion.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import '../../viewmodels/ordenes_trabajo_vm.dart';
import '../../widgets/encabezado_usuario.dart';
import '../comunicados/secciones_comunicados.dart';
import '../ordenes_trabajo/pantalla_mis_ots.dart';
import '../ordenes_trabajo/pantalla_ots_grupo.dart';

class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final esSupervisor = sesion?.esSupervisor == true;
    // las mismas OTs de hoy que se ven al tocar "Ver Órdenes de Trabajo"
    final otsDeHoy = esSupervisor ? ref.watch(otsGrupoViewModelProvider) : ref.watch(misOtsViewModelProvider);

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EncabezadoUsuario(),
              const SizedBox(height: 20),
              // los cierres se registran solo como técnico; el supervisor no tiene cola
              if (!esSupervisor) const AvisoCierresPendientes(),
              _TarjetaProgreso(
                textoBoton: 'Ver Órdenes de Trabajo',
                esSupervisor: esSupervisor,
                ots: otsDeHoy.value ?? const [],
                cargando: otsDeHoy.isLoading,
                onVerOts: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => esSupervisor ? const PantallaOtsGrupo() : const PantallaMisOts(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SeccionTablon(),
              const SizedBox(height: 20),
              const SeccionComunicadosPersonales(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.inicio),
    );
  }
}

class _TarjetaProgreso extends StatelessWidget {
  const _TarjetaProgreso({
    this.onVerOts,
    required this.textoBoton,
    required this.esSupervisor,
    required this.ots,
    required this.cargando,
  });
  final VoidCallback? onVerOts;
  final String textoBoton;
  final bool esSupervisor;
  final List<OrdenTrabajo> ots;
  final bool cargando;

  // fold suma sobre la lista, como sum() en Python
  int get _pasosTotales => ots.fold(0, (total, ot) => total + ot.pm01Total);
  int get _pasosCerrados => ots.fold(0, (total, ot) => total + ot.pm01Cerrados);
  double get _fraccion => _pasosTotales == 0 ? 0 : _pasosCerrados / _pasosTotales;

  String get _mensaje {
    if (cargando) return 'Cargando tus órdenes de hoy...';
    final pendientes = _pasosTotales - _pasosCerrados;
    if (_pasosTotales == 0) return esSupervisor ? 'Tu grupo no tiene órdenes para hoy' : 'No tienes órdenes para hoy';
    if (pendientes == 0) return esSupervisor ? '¡El grupo completó la jornada!' : '¡Completaste tu jornada!';
    if (_fraccion >= 0.75) return esSupervisor ? '¡La jornada del grupo está casi completa!' : '¡Tu jornada está casi completa!';
    if (pendientes == 1) return esSupervisor ? 'Al grupo le queda 1 paso por cerrar' : 'Te queda 1 paso por cerrar';
    return esSupervisor ? 'Al grupo le quedan $pendientes pasos por cerrar' : 'Te quedan $pendientes pasos por cerrar';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColoresApp.principal,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x261E3A8A), blurRadius: 25, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esSupervisor ? 'PROGRESO DEL GRUPO HOY' : 'PROGRESO DE HOY',
                  style: const TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _mensaje,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onVerOts,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        textoBoton,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: _fraccion, // nunca null: un indicador sin valor gira sin parar
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Text(
                  '${(_fraccion * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
