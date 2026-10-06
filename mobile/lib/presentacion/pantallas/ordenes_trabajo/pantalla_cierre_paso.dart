import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/orden_trabajo.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/estandarizacion_vm.dart';
import '../../viewmodels/ordenes_trabajo_vm.dart';
import 'componentes_ot.dart';
import 'formato_ot.dart';

/// Formulario de cierre de un paso PM01; al volver devuelve true si se registró
class PantallaCierrePaso extends ConsumerStatefulWidget {
  const PantallaCierrePaso({super.key, required this.otId, required this.paso});
  final String otId;
  final PasoOt paso;

  @override
  ConsumerState<PantallaCierrePaso> createState() => _PantallaCierrePasoState();
}

class _PantallaCierrePasoState extends ConsumerState<PantallaCierrePaso> {
  final _controladorHoras = TextEditingController();
  final _controladorDescripcion = TextEditingController();
  final _controladorRevision = TextEditingController();
  bool _ejecutado = true;
  bool _revisando = false;
  bool _estandarizado = false;
  String? _errorEstandarizacion;

  @override
  void dispose() {
    _controladorHoras.dispose();
    _controladorDescripcion.dispose();
    _controladorRevision.dispose();
    super.dispose();
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  double? _horasValidas() {
    // si no se ejecutó, el tiempo es 0
    final horas = _ejecutado ? double.tryParse(_controladorHoras.text.trim().replaceAll(',', '.')) : 0.0;
    if (horas == null || (_ejecutado && horas <= 0)) {
      _avisar('Ingresa las horas trabajadas (mayores a 0)');
      return null;
    }
    return horas;
  }

  Future<void> _estandarizar() async {
    final descripcion = _controladorDescripcion.text.trim();
    if (_horasValidas() == null) return;
    if (descripcion.isEmpty) return _avisar('Describe el trabajo realizado');

    setState(() => _errorEstandarizacion = null);
    final resultado = await ref.read(estandarizacionViewModelProvider.notifier).estandarizar(descripcion);
    if (!mounted) return;
    if (resultado != null) {
      setState(() {
        _controladorRevision.text = resultado;
        _estandarizado = true;
        _revisando = true;
      });
    } else {
      setState(() => _errorEstandarizacion = mensajeDeError(ref.read(estandarizacionViewModelProvider).error!));
    }
  }

  void _continuarConOriginal() {
    setState(() {
      _controladorRevision.text = _controladorDescripcion.text.trim();
      _estandarizado = false;
      _errorEstandarizacion = null;
      _revisando = true;
    });
  }

  void _volverARedactar() {
    ref.read(estandarizacionViewModelProvider.notifier).reiniciar();
    setState(() => _revisando = false);
  }

  Future<void> _registrar() async {
    final descripcion = _controladorRevision.text.trim();
    final horas = _horasValidas();
    if (horas == null) return;
    if (descripcion.isEmpty) return _avisar('La descripción no puede quedar vacía');

    final exito = await ref.read(cierrePasoViewModelProvider.notifier).registrar(
          otId: widget.otId,
          pasoId: widget.paso.id,
          ejecutado: _ejecutado,
          tiempoRealTrabajado: horas,
          descripcion: descripcion,
        );
    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop(true);
    } else {
      _avisar(mensajeDeError(ref.read(cierrePasoViewModelProvider).error!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardando = ref.watch(cierrePasoViewModelProvider).isLoading;
    final estandarizando = ref.watch(estandarizacionViewModelProvider).isLoading;
    final paso = widget.paso;

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EncabezadoOts(titulo: 'Registrar cierre'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  _Tarjeta(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paso ${paso.numeroPaso} · PM01',
                          style: const TextStyle(color: ColoresApp.principal, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          paso.descripcion,
                          style: const TextStyle(
                            color: ColoresApp.textoOscuro,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (paso.horasPlanificadas != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Planificado: ${formatoHoras(paso.horasPlanificadas!)}',
                            style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _Tarjeta(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Etiqueta('Resultado del trabajo'),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Ejecutado'), icon: Icon(Icons.check_circle_outline)),
                            ButtonSegment(value: false, label: Text('No ejecutado'), icon: Icon(Icons.block_outlined)),
                          ],
                          selected: {_ejecutado},
                          onSelectionChanged: (s) => setState(() => _ejecutado = s.first),
                        ),
                        const SizedBox(height: 16),
                        const _Etiqueta('Horas trabajadas'),
                        TextField(
                          controller: _controladorHoras,
                          enabled: _ejecutado,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _decoracion(_ejecutado ? 'Ej. 1.5' : '0 (no se ejecutó)'),
                        ),
                        const SizedBox(height: 16),
                        const _Etiqueta('Descripción del trabajo realizado'),
                        TextField(
                          controller: _controladorDescripcion,
                          enabled: !_revisando && !estandarizando,
                          minLines: 4,
                          maxLines: 6,
                          decoration: _decoracion('Qué se hizo, mediciones y observaciones'),
                        ),
                      ],
                    ),
                  ),
                  if (_errorEstandarizacion != null && !_revisando)
                    _Tarjeta(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _errorEstandarizacion!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: estandarizando ? null : _estandarizar, child: const Text('Reintentar')),
                          const SizedBox(height: 8),
                          TextButton(onPressed: estandarizando ? null : _continuarConOriginal, child: const Text('Continuar con el texto original')),
                        ],
                      ),
                    ),
                  if (_revisando)
                    _Tarjeta(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Etiqueta(_estandarizado ? 'Descripción estandarizada (puedes editarla)' : 'Descripción sin estandarizar'),
                          TextField(
                            controller: _controladorRevision,
                            enabled: !guardando,
                            minLines: 8,
                            maxLines: 16,
                            decoration: _decoracion(''),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: guardando ? null : _volverARedactar,
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Volver a redactar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: (guardando || estandarizando) ? null : (_revisando ? _registrar : _estandarizar),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColoresApp.principal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: (guardando || estandarizando)
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              _revisando ? 'Registrar cierre' : 'Estandarizar y revisar',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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

InputDecoration _decoracion(String indicativo) => InputDecoration(
      hintText: indicativo,
      hintStyle: const TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 14),
      filled: true,
      fillColor: ColoresApp.campoFondo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ColoresApp.campoBorde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ColoresApp.campoBorde),
      ),
    );

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: ColoresApp.textoSuave,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
