import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/orden_trabajo.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/ordenes_trabajo_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import 'componentes_ot.dart';
import 'pantalla_detalle_ot.dart';
import 'tira_de_dias.dart';

/// OTs asignadas al Tecnico para un dia (hoy +-2), filtrables por estado.
class PantallaMisOts extends ConsumerStatefulWidget {
  const PantallaMisOts({super.key});

  @override
  ConsumerState<PantallaMisOts> createState() => _PantallaMisOtsState();
}

enum _FiltroEstado { todos, asignada, enProgreso, cerrada }

extension on _FiltroEstado {
  String get etiqueta => switch (this) {
        _FiltroEstado.todos => 'Todos',
        _FiltroEstado.asignada => 'Asignadas',
        _FiltroEstado.enProgreso => 'En proceso',
        _FiltroEstado.cerrada => 'Finalizadas',
      };

  bool incluye(OrdenTrabajo ot) => switch (this) {
        _FiltroEstado.todos => true,
        _FiltroEstado.asignada => ot.estatus == 'asignada',
        _FiltroEstado.enProgreso => ot.estatus == 'en_progreso',
        _FiltroEstado.cerrada => ot.estatus == 'cerrada',
      };
}

class _PantallaMisOtsState extends ConsumerState<PantallaMisOts> {
  _FiltroEstado _filtroEstado = _FiltroEstado.todos;

  Future<void> _abrirDetalle(OrdenTrabajo ot) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PantallaDetalleOt(otId: ot.id)),
    );
    // Al abrirla, la OT pudo pasar de "Asignada" a "En proceso".
    if (mounted) ref.read(misOtsViewModelProvider.notifier).recargar();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(misOtsViewModelProvider);
    final viewModel = ref.read(misOtsViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EncabezadoOts(titulo: 'Órdenes de Trabajo'),
            TiraDeDias(
              seleccionada: viewModel.fecha,
              onSeleccionar: viewModel.filtrarPorFecha,
            ),
            const SizedBox(height: 12),
            _PestanasEstado(
              seleccionado: _filtroEstado,
              onSeleccionar: (f) => setState(() => _filtroEstado = f),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: estado.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => MensajeCentrado(
                  icono: Icons.cloud_off,
                  texto: mensajeDeError(error),
                  accion: 'Reintentar',
                  onAccion: viewModel.recargar,
                ),
                data: (ots) {
                  final visibles = ots.where(_filtroEstado.incluye).toList();
                  if (visibles.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: viewModel.recargar,
                      child: ListView(
                        children: [
                          const SizedBox(height: 60),
                          MensajeCentrado(
                            icono: Icons.assignment_turned_in_outlined,
                            texto: ots.isEmpty
                                ? 'No tienes órdenes de trabajo para este día'
                                : 'No hay órdenes en este estado',
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: viewModel.recargar,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      itemCount: visibles.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => TarjetaOt(
                        ot: visibles[i],
                        onTap: () => _abrirDetalle(visibles[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.agenda),
    );
  }
}

class _PestanasEstado extends StatelessWidget {
  const _PestanasEstado({required this.seleccionado, required this.onSeleccionar});
  final _FiltroEstado seleccionado;
  final ValueChanged<_FiltroEstado> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final filtro in _FiltroEstado.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filtro.etiqueta),
                selected: filtro == seleccionado,
                onSelected: (_) => onSeleccionar(filtro),
                showCheckmark: false,
                selectedColor: ColoresApp.principal,
                backgroundColor: ColoresApp.badgeFondo,
                side: const BorderSide(color: ColoresApp.badgeBorde),
                labelStyle: TextStyle(
                  color: filtro == seleccionado ? Colors.white : ColoresApp.principal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
