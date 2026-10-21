import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/comunicado.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/comunicados_vm.dart';
import '../../viewmodels/tecnicos_vm.dart';
import '../ordenes_trabajo/formato_ot.dart';
import 'componentes_comunicados.dart';

const _tamanoMaximoImagen = 2 * 1024 * 1024; // el mismo límite que el backend

/// Redactar un comunicado general (para todo el grupo) o personal (para un técnico del grupo)
class PantallaNuevoComunicado extends ConsumerStatefulWidget {
  const PantallaNuevoComunicado({super.key, required this.personal});
  final bool personal;

  @override
  ConsumerState<PantallaNuevoComunicado> createState() => _PantallaNuevoComunicadoState();
}

class _PantallaNuevoComunicadoState extends ConsumerState<PantallaNuevoComunicado> {
  final _titulo = TextEditingController();
  final _texto = TextEditingController();
  CategoriaComunicado _categoria = CategoriaComunicado.general;
  // por defecto vence en una semana, al final del día
  DateTime _expiracion = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 7, hours: 23, minutes: 59));
  String? _tecnicoId;
  Uint8List? _imagen;
  String? _nombreImagen;
  bool _publicando = false;

  @override
  void dispose() {
    _titulo.dispose();
    _texto.dispose();
    super.dispose();
  }

  void _avisar(String mensaje) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(_expiracion),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 90)),
      helpText: 'Visible hasta el',
    );
    if (fecha != null) setState(() => _expiracion = fecha.add(const Duration(hours: 23, minutes: 59)));
  }

  Future<void> _elegirImagen() async {
    final archivos = await FilePicker.pickFiles(type: FileType.image);
    if (archivos.isEmpty || !mounted) return;
    final archivo = archivos.first;
    final bytes = await archivo.readAsBytes();
    if (bytes.length > _tamanoMaximoImagen) return _avisar('La imagen no puede pasar de 2 MB');
    setState(() {
      _imagen = bytes;
      _nombreImagen = archivo.name;
    });
  }

  Future<void> _publicar() async {
    final titulo = _titulo.text.trim();
    final texto = _texto.text.trim();
    if (widget.personal && _tecnicoId == null) return _avisar('Elige el técnico');
    if (titulo.isEmpty) return _avisar('Escribe un título');
    if (texto.isEmpty && _imagen == null) return _avisar('Escribe un texto o adjunta una imagen');

    setState(() => _publicando = true);
    try {
      await ref.read(comunicadosViewModelProvider.notifier).publicar(ComunicadoNuevo(
            titulo: titulo,
            categoria: _categoria,
            fechaExpiracion: _expiracion,
            texto: texto.isEmpty ? null : texto,
            tecnicoId: widget.personal ? _tecnicoId : null,
            imagen: _imagen,
            nombreImagen: _nombreImagen,
          ));
      if (!mounted) return;
      Navigator.of(context).pop();
      _avisar('Comunicado publicado');
    } catch (e) {
      if (mounted) _avisar(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: ColoresApp.textoOscuro),
                  ),
                  Expanded(
                    child: Text(
                      widget.personal ? 'Comunicado personal' : 'Comunicado para el grupo',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (widget.personal) ...[
                    const _Etiqueta('Para'),
                    _SelectorTecnico(seleccionado: _tecnicoId, alCambiar: (id) => setState(() => _tecnicoId = id)),
                    const SizedBox(height: 16),
                  ],
                  const _Etiqueta('Título'),
                  _Campo(controlador: _titulo, indicativo: 'Ej. Uso obligatorio de EPP', maximo: 100),
                  const SizedBox(height: 16),
                  const _Etiqueta('Categoría'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final categoria in CategoriaComunicado.values)
                        ChoiceChip(
                          label: Text(categoria.etiqueta),
                          avatar: Icon(categoria.icono, size: 16, color: categoria.color),
                          selected: _categoria == categoria,
                          onSelected: (_) => setState(() => _categoria = categoria),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _Etiqueta('Mensaje'),
                  _Campo(controlador: _texto, indicativo: 'Escribe el comunicado', maximo: 2000, lineas: 5),
                  const SizedBox(height: 16),
                  const _Etiqueta('Imagen'),
                  if (_imagen == null)
                    OutlinedButton.icon(
                      onPressed: _publicando ? null : _elegirImagen,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Adjuntar imagen (JPG o PNG, hasta 2 MB)'),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imagen!, height: 160, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: IconButton.filledTonal(
                            tooltip: 'Quitar imagen',
                            onPressed: () => setState(() => _imagen = _nombreImagen = null),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const _Etiqueta('Visible hasta'),
                  OutlinedButton.icon(
                    onPressed: _publicando ? null : _elegirFecha,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(formatoFecha(_expiracion)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _publicando ? null : _publicar,
                      style: FilledButton.styleFrom(
                        backgroundColor: ColoresApp.principal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _publicando
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorTecnico extends ConsumerWidget {
  const _SelectorTecnico({required this.seleccionado, required this.alCambiar});
  final String? seleccionado;
  final ValueChanged<String?> alCambiar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // solo técnicos activos del grupo del supervisor
    final tecnicos = (ref.watch(tecnicosViewModelProvider).value ?? const []).where((t) => t.activo).toList();
    return DropdownButtonFormField<String>(
      initialValue: seleccionado,
      isExpanded: true,
      hint: Text(tecnicos.isEmpty ? 'No hay técnicos activos en tu grupo' : 'Elige un técnico'),
      decoration: _decoracion(),
      items: [for (final t in tecnicos) DropdownMenuItem(value: t.id, child: Text(t.nombreCompleto))],
      onChanged: alCambiar,
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(texto, style: const TextStyle(color: ColoresApp.textoLabel, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({required this.controlador, required this.indicativo, required this.maximo, this.lineas = 1});
  final TextEditingController controlador;
  final String indicativo;
  final int maximo;
  final int lineas;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      maxLength: maximo,
      minLines: lineas,
      maxLines: lineas == 1 ? 1 : lineas + 5,
      style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 14),
      decoration: _decoracion(indicativo: indicativo),
    );
  }
}

InputDecoration _decoracion({String? indicativo}) {
  final borde = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: ColoresApp.campoBorde),
  );
  return InputDecoration(
    hintText: indicativo,
    hintStyle: const TextStyle(color: ColoresApp.textoPlaceholder),
    filled: true,
    fillColor: ColoresApp.campoFondo,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: borde,
    enabledBorder: borde,
    focusedBorder: borde.copyWith(borderSide: const BorderSide(color: ColoresApp.principal, width: 1.5)),
  );
}
