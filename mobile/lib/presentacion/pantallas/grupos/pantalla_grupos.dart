import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/grupo.dart';
import '../../../dominio/modelos/supervisor.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/grupos_vm.dart';
import '../../viewmodels/supervisores_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import '../../widgets/encabezado_administrador.dart';

class PantallaGrupos extends ConsumerWidget {
  const PantallaGrupos({super.key});

  Future<void> _ejecutar(BuildContext context, Future<void> Function() accion, String mensaje) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await accion();
      mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
  }

  Future<void> _cambiarSupervisor(BuildContext context, WidgetRef ref, Grupo grupo) async {
    final supervisores = await ref.read(supervisoresViewModelProvider.future);
    if (!context.mounted) return;
    final elegido = await showDialog<Supervisor>(
      context: context,
      builder: (dialogo) => SimpleDialog(
        title: Text('Supervisor de ${grupo.nombreDeGrupo}'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Si el supervisor ya tiene un grupo, los grupos se intercambian.',
              style: TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
            ),
          ),
          for (final s in supervisores.where((s) => s.id != grupo.supervisorId))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogo, s),
              child: Text('${s.nombreCompleto} · ${s.grupoNombre ?? 'Sin grupo'}'),
            ),
        ],
      ),
    );
    if (elegido == null || !context.mounted) return;
    await _ejecutar(
      context,
      () => ref.read(gruposViewModelProvider.notifier).asignarSupervisor(grupo.id, elegido.id),
      'Supervisor asignado',
    );
  }

  Future<void> _nuevoGrupo(BuildContext context, WidgetRef ref) async {
    final supervisores = await ref.read(supervisoresViewModelProvider.future);
    if (!context.mounted) return;
    final datos = await showDialog<(String, String?)>(
      context: context,
      builder: (_) => _DialogoNuevoGrupo(supervisores: supervisores),
    );
    if (datos == null || !context.mounted) return;
    final (nombreDeGrupo, supervisorId) = datos;
    if (nombreDeGrupo.isEmpty || supervisorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe el nombre y elige un supervisor')));
      return;
    }
    await _ejecutar(
      context,
      () => ref.read(gruposViewModelProvider.notifier).crear(nombreDeGrupo: nombreDeGrupo, supervisorId: supervisorId),
      'Grupo creado',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(gruposViewModelProvider);

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            EncabezadoAdministrador(
              titulo: 'Grupos',
              iconoAccion: Icons.group_add,
              textoAccion: 'Nuevo grupo',
              onAccion: () => _nuevoGrupo(context, ref),
            ),
            Expanded(
              child: estado.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(mensajeDeError(error), textAlign: TextAlign.center)),
                data: (grupos) => grupos.isEmpty
                    ? const Center(child: Text('No hay grupos registrados'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: grupos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final grupo = grupos[i];
                          return TarjetaAdministrador(
                            titulo: grupo.nombreDeGrupo,
                            detalle: '${grupo.supervisorNombre ?? 'Sin supervisor'} · ${grupo.cantidadTecnicos} técnicos',
                            acciones: [
                              TextButton(
                                onPressed: () => _cambiarSupervisor(context, ref, grupo),
                                child: const Text('Cambiar supervisor'),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.grupos),
    );
  }
}

/// Devuelve el nombre del grupo y el supervisor elegido
class _DialogoNuevoGrupo extends StatefulWidget {
  const _DialogoNuevoGrupo({required this.supervisores});
  final List<Supervisor> supervisores;

  @override
  State<_DialogoNuevoGrupo> createState() => _DialogoNuevoGrupoState();
}

class _DialogoNuevoGrupoState extends State<_DialogoNuevoGrupo> {
  final _nombre = TextEditingController();
  String? _supervisorId;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo grupo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre del grupo')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _supervisorId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Supervisor'),
            items: [for (final s in widget.supervisores) DropdownMenuItem(value: s.id, child: Text(s.nombreCompleto))],
            onChanged: (id) => setState(() => _supervisorId = id),
          ),
          const SizedBox(height: 12),
          const Text(
            'El grupo que tenía el supervisor quedará sin supervisor.',
            style: TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, (_nombre.text.trim(), _supervisorId)), child: const Text('Crear')),
      ],
    );
  }
}
