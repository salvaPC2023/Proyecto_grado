import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/supervisor.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/supervisores_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import 'pantalla_registrar_supervisor.dart';

class PantallaListaSupervisores extends ConsumerWidget {
  const PantallaListaSupervisores({super.key});

  Future<void> _alternarEstado(BuildContext context, WidgetRef ref, Supervisor supervisor) async {
    final accion = supervisor.activo ? 'Deshabilitar' : 'Habilitar';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text('$accion cuenta'),
        content: Text(supervisor.activo
            ? '¿Deshabilitar la cuenta de ${supervisor.nombreCompleto}? No podrá iniciar sesión.'
            : '¿Habilitar la cuenta de ${supervisor.nombreCompleto}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: Text(accion)),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final mensajero = ScaffoldMessenger.of(context);
    try {
      await ref.read(supervisoresViewModelProvider.notifier).cambiarEstado(supervisor.id, !supervisor.activo);
      mensajero.showSnackBar(SnackBar(
        content: Text(supervisor.activo ? 'Cuenta deshabilitada' : 'Cuenta habilitada'),
      ));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(supervisoresViewModelProvider);

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            _Encabezado(
              onVolver: () => Navigator.of(context).maybePop(),
              onRegistrar: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PantallaRegistrarSupervisor()),
              ),
            ),
            Expanded(
              child: estado.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(mensajeDeError(error), textAlign: TextAlign.center),
                  ),
                ),
                data: (supervisores) => supervisores.isEmpty
                    ? const Center(child: Text('No hay supervisores registrados'))
                    : RefreshIndicator(
                        onRefresh: () => ref.read(supervisoresViewModelProvider.notifier).recargar(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: supervisores.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _TarjetaSupervisor(
                            supervisor: supervisores[i],
                            onAlternarEstado: () => _alternarEstado(context, ref, supervisores[i]),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.equipoTrabajo),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.onVolver, required this.onRegistrar});
  final VoidCallback onVolver;
  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          _BotonCircular(icono: Icons.arrow_back, tooltip: 'Volver', onPressed: onVolver),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Supervisores',
              style: TextStyle(color: ColoresApp.textoOscuro, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _BotonCircular(icono: Icons.person_add, tooltip: 'Registrar supervisor', onPressed: onRegistrar),
        ],
      ),
    );
  }
}

class _BotonCircular extends StatelessWidget {
  const _BotonCircular({required this.icono, required this.tooltip, required this.onPressed});
  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFFF1F5F9))),
      elevation: 2,
      shadowColor: Colors.black12,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icono, size: 20, color: ColoresApp.textoOscuro),
      ),
    );
  }
}

class _TarjetaSupervisor extends StatelessWidget {
  const _TarjetaSupervisor({required this.supervisor, required this.onAlternarEstado});
  final Supervisor supervisor;
  final VoidCallback onAlternarEstado;

  @override
  Widget build(BuildContext context) {
    final activo = supervisor.activo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supervisor.nombreCompleto,
                  style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${supervisor.grupoNombre ?? 'Sin grupo'} · ${supervisor.horario}',
                  style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: activo ? const Color(0xFF059669) : ColoresApp.textoPlaceholder,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAlternarEstado,
            child: Text(activo ? 'Deshabilitar' : 'Habilitar'),
          ),
        ],
      ),
    );
  }
}
