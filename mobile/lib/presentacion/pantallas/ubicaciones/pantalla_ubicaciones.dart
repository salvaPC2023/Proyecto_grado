import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/orden_trabajo.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/ubicaciones_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import '../../widgets/encabezado_administrador.dart';

const _niveles = ['Sector *', 'Subsector', 'Sistema', 'Subsistema'];

class PantallaUbicaciones extends ConsumerWidget {
  const PantallaUbicaciones({super.key});

  Future<void> _ejecutar(BuildContext context, Future<void> Function() accion, String mensaje) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await accion();
      mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
  }

  /// Formulario para registrar (sin ubicación) o editar
  Future<void> _formulario(BuildContext context, WidgetRef ref, [UbicacionTecnica? ubicacion]) async {
    final textos = await showDialog<List<String?>>(
      context: context,
      builder: (_) => _FormularioUbicacion(ubicacion: ubicacion),
    );
    if (textos == null || !context.mounted) return;
    if (textos[0] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El sector es obligatorio')));
      return;
    }
    await _ejecutar(
      context,
      () => ref.read(ubicacionesViewModelProvider.notifier).guardar(
            id: ubicacion?.id,
            sector: textos[0]!,
            subsector: textos[1],
            sistema: textos[2],
            subsistema: textos[3],
          ),
      ubicacion == null ? 'Ubicación registrada' : 'Ubicación actualizada',
    );
  }

  Future<void> _borrar(BuildContext context, WidgetRef ref, UbicacionTecnica ubicacion) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Borrar ubicación'),
        content: Text('¿Borrar ${ubicacion.ruta}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    await _ejecutar(context, () => ref.read(ubicacionesViewModelProvider.notifier).borrar(ubicacion.id), 'Ubicación borrada');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(ubicacionesViewModelProvider);

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            EncabezadoAdministrador(
              titulo: 'Ubicaciones técnicas',
              iconoAccion: Icons.add_location_alt_outlined,
              textoAccion: 'Nueva ubicación',
              onAccion: () => _formulario(context, ref),
            ),
            Expanded(
              child: estado.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(mensajeDeError(error), textAlign: TextAlign.center)),
                data: (ubicaciones) => ubicaciones.isEmpty
                    ? const Center(child: Text('No hay ubicaciones registradas'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: ubicaciones.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final ubicacion = ubicaciones[i];
                          return TarjetaAdministrador(
                            titulo: ubicacion.nombreCorto,
                            detalle: ubicacion.ruta,
                            onTap: () => _formulario(context, ref, ubicacion),
                            acciones: [
                              IconButton(
                                tooltip: 'Borrar',
                                onPressed: () => _borrar(context, ref, ubicacion),
                                icon: const Icon(Icons.delete_outline, color: ColoresApp.textoSuave),
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
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.ubicaciones),
    );
  }
}

/// Devuelve los cuatro niveles; los vacíos como null (el backend revisa que no se salte un nivel)
class _FormularioUbicacion extends StatefulWidget {
  const _FormularioUbicacion({this.ubicacion});
  final UbicacionTecnica? ubicacion;

  @override
  State<_FormularioUbicacion> createState() => _FormularioUbicacionState();
}

class _FormularioUbicacionState extends State<_FormularioUbicacion> {
  late final _campos = [
    for (final v in [widget.ubicacion?.sector, widget.ubicacion?.subsector, widget.ubicacion?.sistema, widget.ubicacion?.subsistema])
      TextEditingController(text: v ?? ''),
  ];

  @override
  void dispose() {
    for (final c in _campos) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ubicacion == null ? 'Nueva ubicación' : 'Editar ubicación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 4; i++)
              TextField(controller: _campos[i], decoration: InputDecoration(labelText: _niveles[i])),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, [for (final c in _campos) c.text.trim().isEmpty ? null : c.text.trim()]),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
