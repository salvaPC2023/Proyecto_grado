import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/grupo.dart';
import '../../../dominio/modelos/supervisor.dart';
import '../../../dominio/modelos/tecnico.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/grupos_vm.dart';
import '../../viewmodels/supervisores_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import '../../widgets/dialogo_datos_acceso.dart';
import '../../widgets/encabezado_seccion.dart';

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

  Future<void> _borrar(BuildContext context, WidgetRef ref, Grupo grupo) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text('Borrar ${grupo.nombreDeGrupo}'),
        content: Text(
          grupo.supervisorNombre == null
              ? '¿Borrar este grupo? No tiene técnicos.'
              : '¿Borrar este grupo? No tiene técnicos. ${grupo.supervisorNombre} quedará sin grupo hasta que le asignes otro.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    await _ejecutar(context, () => ref.read(gruposViewModelProvider.notifier).eliminar(grupo.id), 'Grupo borrado');
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

  Future<void> _verTecnicos(BuildContext context, Grupo grupo) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TecnicosDelGrupo(grupo: grupo),
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
            EncabezadoSeccion(
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
                              // solo se borra un grupo vacío (el backend también lo exige)
                              if (grupo.cantidadTecnicos == 0)
                                TextButton(
                                  onPressed: () => _borrar(context, ref, grupo),
                                  child: const Text('Borrar'),
                                )
                              else
                                TextButton(
                                  onPressed: () => _verTecnicos(context, grupo),
                                  child: const Text('Técnicos'),
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


/// Técnicos de un grupo, para que el administrador restablezca la contraseña de quien la olvidó
class _TecnicosDelGrupo extends ConsumerStatefulWidget {
  const _TecnicosDelGrupo({required this.grupo});
  final Grupo grupo;

  @override
  ConsumerState<_TecnicosDelGrupo> createState() => _TecnicosDelGrupoState();
}

class _TecnicosDelGrupoState extends ConsumerState<_TecnicosDelGrupo> {
  late final Future<List<Tecnico>> _tecnicos =
      ref.read(gruposViewModelProvider.notifier).listarTecnicos(widget.grupo.id);

  Future<void> _restablecer(Tecnico tecnico) async {
    if (!await confirmarRestablecerPassword(context, tecnico.nombreCompleto) || !mounted) return;
    try {
      final datos = await ref.read(gruposViewModelProvider.notifier).restablecerPasswordTecnico(tecnico.id);
      if (!mounted) return;
      await mostrarDatosDeAcceso(
        context,
        titulo: 'Contraseña restablecida',
        nombreUsuario: datos.nombreUsuario,
        passwordInicial: datos.passwordInicial,
        mensaje: mensajeRestablecida,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Técnicos de ${widget.grupo.nombreDeGrupo}',
                style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Si alguien olvidó su contraseña, restablécela y entrégale sus datos de acceso.',
                style: TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: FutureBuilder<List<Tecnico>>(
                  future: _tecnicos,
                  builder: (context, resultado) {
                    if (resultado.hasError) {
                      return Text(mensajeDeError(resultado.error!), textAlign: TextAlign.center);
                    }
                    if (!resultado.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        for (final tecnico in resultado.data!)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tecnico.nombreCompleto, style: const TextStyle(fontSize: 14)),
                            subtitle: Text(
                              tecnico.activo ? tecnico.nombreUsuario : '${tecnico.nombreUsuario} · Inactivo',
                              style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
                            ),
                            trailing: TextButton(
                              onPressed: () => _restablecer(tecnico),
                              child: const Text('Restablecer'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
