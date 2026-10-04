import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/tecnico.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/ordenes_trabajo_vm.dart';
import '../../viewmodels/tecnicos_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import 'componentes_ot.dart';
import 'pantalla_detalle_ot.dart';
import 'tira_de_dias.dart';

class PantallaOtsGrupo extends ConsumerStatefulWidget {
  const PantallaOtsGrupo({super.key});

  @override
  ConsumerState<PantallaOtsGrupo> createState() => _PantallaOtsGrupoState();
}

class _PantallaOtsGrupoState extends ConsumerState<PantallaOtsGrupo> {
  String? _tecnicoId;

  Future<void> _abrirDetalle(String otId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PantallaDetalleOt(otId: otId)),
    );
    if (mounted) ref.read(otsGrupoViewModelProvider.notifier).recargar();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(otsGrupoViewModelProvider);
    final viewModel = ref.read(otsGrupoViewModelProvider.notifier);
    final tecnicos = ref.watch(tecnicosViewModelProvider).value ?? const <Tecnico>[];
    final nombres = {for (final t in tecnicos) t.id: t.nombreCompleto};

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
            _FiltroTecnico(
              tecnicos: tecnicos,
              seleccionado: _tecnicoId,
              onCambiar: (id) => setState(() => _tecnicoId = id),
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
                  final visibles = ots
                      .where((ot) => _tecnicoId == null || ot.tecnicoAsignadoId == _tecnicoId)
                      .toList();
                  if (visibles.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: viewModel.recargar,
                      child: ListView(
                        children: [
                          const SizedBox(height: 60),
                          MensajeCentrado(
                            icono: Icons.assignment_outlined,
                            texto: ots.isEmpty
                                ? 'Tu grupo no tiene órdenes de trabajo para este día'
                                : 'Este técnico no tiene órdenes de trabajo para este día',
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
                        nombreTecnico: nombres[visibles[i].tecnicoAsignadoId] ?? 'Técnico',
                        onTap: () => _abrirDetalle(visibles[i].id),
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

class _FiltroTecnico extends StatelessWidget {
  const _FiltroTecnico({
    required this.tecnicos,
    required this.seleccionado,
    required this.onCambiar,
  });
  final List<Tecnico> tecnicos;
  final String? seleccionado;
  final ValueChanged<String?> onCambiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20, color: ColoresApp.textoOscuro),
          const SizedBox(width: 6),
          const Text(
            'Filtrar por:',
            style: TextStyle(
              color: ColoresApp.textoOscuro,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: tecnicos.any((t) => t.id == seleccionado) ? seleccionado : null,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos los técnicos')),
                    for (final t in tecnicos)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.nombreCompleto, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: onCambiar,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
