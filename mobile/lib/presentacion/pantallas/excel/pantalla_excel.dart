import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/orden_trabajo.dart';
import '../../../dominio/modelos/resultado_importacion.dart';
import '../../../nucleo/di.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/fechas.dart';
import '../../../nucleo/sesion.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/grupos_vm.dart';
import '../../viewmodels/supervisores_vm.dart';
import '../../viewmodels/tecnicos_vm.dart';
import '../../viewmodels/ubicaciones_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import '../../widgets/encabezado_administrador.dart';
import '../ordenes_trabajo/componentes_ot.dart';
import '../ordenes_trabajo/formato_ot.dart';

const _tipoExcel = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Excel: el supervisor exporta OT e importa para su grupo; el administrador importa el personal
class PantallaExcel extends ConsumerStatefulWidget {
  const PantallaExcel({super.key});

  @override
  ConsumerState<PantallaExcel> createState() => _PantallaExcelState();
}

class _PantallaExcelState extends ConsumerState<PantallaExcel> {
  // por defecto, el mes en curso
  DateTime _desde = DateTime(hoySinHora().year, hoySinHora().month);
  DateTime _hasta = hoySinHora();
  String? _ubicacionId;
  bool _exportando = false;
  bool _importando = false;

  Future<void> _elegirFecha({required bool esDesde}) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esDesde ? _desde : _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (fecha == null) return;
    setState(() => esDesde ? _desde = fecha : _hasta = fecha);
  }

  Future<void> _exportar() async {
    final mensajero = ScaffoldMessenger.of(context);
    if (_desde.isAfter(_hasta)) {
      mensajero.showSnackBar(const SnackBar(content: Text('La fecha inicial no puede ser posterior a la final')));
      return;
    }
    setState(() => _exportando = true);
    try {
      final bytes = await ref
          .read(repositorioExcelProvider)
          .exportarOts(desde: _desde, hasta: _hasta, ubicacionTecnicaId: _ubicacionId);
      String dia(DateTime f) => f.toIso8601String().substring(0, 10);
      // en Android abre "Guardar como"; en el navegador lo descarga
      final guardado = await FilePicker.saveFile(
        fileName: 'ordenes_de_trabajo_${dia(_desde)}_${dia(_hasta)}.xlsx',
        bytes: bytes,
        mimeType: _tipoExcel,
      );
      if (guardado != null) mensajero.showSnackBar(const SnackBar(content: Text('Archivo de Excel guardado')));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _importar() async {
    final mensajero = ScaffoldMessenger.of(context);
    final archivos = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (archivos.isEmpty || !mounted) return;

    setState(() => _importando = true);
    try {
      final archivo = archivos.first;
      final bytes = await archivo.readAsBytes();
      final repositorio = ref.read(repositorioExcelProvider);
      final resultado = _esAdministrador
          ? await repositorio.importarCargaInicial(bytes, archivo.name)
          : await repositorio.importarParaMiGrupo(bytes, archivo.name);
      // las listas que pudieron cambiar se vuelven a cargar
      if (_esAdministrador) {
        ref.invalidate(supervisoresViewModelProvider);
        ref.invalidate(gruposViewModelProvider);
        ref.invalidate(ubicacionesViewModelProvider);
      } else {
        ref.invalidate(ubicacionesViewModelProvider);
        ref.invalidate(tecnicosViewModelProvider);
      }
      if (mounted) {
        await showDialog<void>(context: context, builder: (_) => _DialogoResultado(resultado: resultado));
      }
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  bool get _esAdministrador => ref.read(sesionProvider)?.esAdministrador ?? false;

  @override
  Widget build(BuildContext context) {
    final esAdministrador = ref.watch(sesionProvider)?.esAdministrador ?? false;
    final ubicaciones = esAdministrador
        ? const <UbicacionTecnica>[]
        : ref.watch(ubicacionesViewModelProvider).value ?? [];

    final tarjetaImportar = _Tarjeta(
      titulo: esAdministrador ? 'Carga inicial desde Excel' : 'Importar desde Excel',
      detalle: esAdministrador
          ? 'Registra las ubicaciones técnicas, los supervisores (con su grupo) y los técnicos de todos los grupos '
                'de la plantilla de SAP. Lo ya registrado se omite.'
          : 'Registra las ubicaciones técnicas y los técnicos de tu grupo de la plantilla de SAP. '
                'Lo ya registrado y los técnicos de otros grupos se omiten.',
      children: [
        OutlinedButton.icon(
          onPressed: _importando ? null : _importar,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: _importando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_file),
          label: const Text('Elegir archivo .xlsx'),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            esAdministrador ? const EncabezadoAdministrador(titulo: 'Excel') : const EncabezadoOts(titulo: 'Excel'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  if (esAdministrador)
                    tarjetaImportar
                  else ...[
                    _Tarjeta(
                      titulo: 'Exportar órdenes de trabajo',
                      detalle: 'Una fila por cada paso PM01 de las OT de tu grupo, con los datos de su cierre.',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _BotonFecha(
                                etiqueta: 'Desde',
                                fecha: _desde,
                                onTap: () => _elegirFecha(esDesde: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _BotonFecha(
                                etiqueta: 'Hasta',
                                fecha: _hasta,
                                onTap: () => _elegirFecha(esDesde: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: _ubicacionId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Ubicación técnica'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todas las ubicaciones')),
                            for (final u in ubicaciones)
                              DropdownMenuItem(
                                value: u.id,
                                child: Text(u.ruta, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (id) => setState(() => _ubicacionId = id),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _exportando ? null : _exportar,
                          style: FilledButton.styleFrom(
                            backgroundColor: ColoresApp.principal,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: _exportando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.download),
                          label: const Text('Exportar a Excel'),
                        ),
                      ],
                    ),
                    tarjetaImportar,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.excel),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.detalle, required this.children});
  final String titulo;
  final String detalle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(detalle, style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 12)),
          if (children.isNotEmpty) const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _BotonFecha extends StatelessWidget {
  const _BotonFecha({required this.etiqueta, required this.fecha, required this.onTap});
  final String etiqueta;
  final DateTime fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
      child: Column(
        children: [
          Text(etiqueta, style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 11)),
          Text(
            formatoFecha(fecha),
            style: const TextStyle(color: ColoresApp.textoOscuro, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Resumen de la importación: usuarios creados (con su nombre de usuario), omitidos y errores por fila
class _DialogoResultado extends StatelessWidget {
  const _DialogoResultado({required this.resultado});
  final ResultadoImportacion resultado;

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    Widget seccion(String titulo, List<String> lineas, {Color? color}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          titulo,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        for (final l in lineas) Text(l, style: const TextStyle(fontSize: 12)),
      ],
    );

    return AlertDialog(
      title: const Text('Resultado de la importación'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuarios creados: ${r.usuariosCreados.length} · Ubicaciones nuevas: ${r.ubicacionesCreadas}'),
              Text('Omitidos: ${r.omitidos.length} · Con error: ${r.errores.length}'),
              if (r.usuariosCreados.isNotEmpty)
                seccion('Usuarios creados (contraseña inicial del sistema)', [
                  for (final u in r.usuariosCreados) '${u.nombreCompleto} → ${u.nombreUsuario} (${u.rol})',
                ]),
              if (r.errores.isNotEmpty)
                seccion('Errores', [
                  for (final a in r.errores) 'Fila ${a.fila}: ${a.dato} — ${a.motivo}',
                ], color: Theme.of(context).colorScheme.error),
              if (r.omitidos.isNotEmpty)
                seccion('Omitidos', [for (final a in r.omitidos) 'Fila ${a.fila}: ${a.dato} — ${a.motivo}']),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    );
  }
}
