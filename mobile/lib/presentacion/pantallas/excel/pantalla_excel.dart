import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/di.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/fechas.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/ubicaciones_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import '../ordenes_trabajo/componentes_ot.dart';
import '../ordenes_trabajo/formato_ot.dart';

const _tipoExcel = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Importar y exportar a Excel (solo supervisor)
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
      final bytes = await ref.read(repositorioExcelProvider).exportarOts(desde: _desde, hasta: _hasta, ubicacionTecnicaId: _ubicacionId);
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

  @override
  Widget build(BuildContext context) {
    final ubicaciones = ref.watch(ubicacionesViewModelProvider).value ?? [];

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EncabezadoOts(titulo: 'Excel'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  _Tarjeta(
                    titulo: 'Exportar órdenes de trabajo',
                    detalle: 'Una fila por cada paso PM01 de las OT de tu grupo, con los datos de su cierre.',
                    children: [
                      Row(
                        children: [
                          Expanded(child: _BotonFecha(etiqueta: 'Desde', fecha: _desde, onTap: () => _elegirFecha(esDesde: true))),
                          const SizedBox(width: 12),
                          Expanded(child: _BotonFecha(etiqueta: 'Hasta', fecha: _hasta, onTap: () => _elegirFecha(esDesde: false))),
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
                            DropdownMenuItem(value: u.id, child: Text(u.ruta, overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (id) => setState(() => _ubicacionId = id),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _exportando ? null : _exportar,
                        style: FilledButton.styleFrom(backgroundColor: ColoresApp.principal, minimumSize: const Size.fromHeight(48)),
                        icon: _exportando
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.download),
                        label: const Text('Exportar a Excel'),
                      ),
                    ],
                  ),
                  const _Tarjeta(
                    titulo: 'Importar desde Excel',
                    detalle: 'Próximamente: técnicos y ubicaciones técnicas desde la plantilla de SAP.',
                    children: [],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.ordenesTrabajo),
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
          Text(titulo, style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 16, fontWeight: FontWeight.bold)),
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
          Text(formatoFecha(fecha), style: const TextStyle(color: ColoresApp.textoOscuro, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
