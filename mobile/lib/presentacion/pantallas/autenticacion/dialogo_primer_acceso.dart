import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../../nucleo/validacion_password.dart';
import '../../viewmodels/auth_vm.dart';
import '../../widgets/checklist_password.dart';

// misma regla que el backend: 4 a 8 letras minúsculas o números
final _reglaUsuario = RegExp(r'^[a-z0-9]{4,8}$');

const _verde = Color(0xFF059669);
const _rojo = Color(0xFFF43F5E);

/// Primer ingreso de un usuario recién creado: elige su usuario y una contraseña propia.
/// Devuelve el usuario nuevo si los cambió, o null si canceló
Future<String?> mostrarDialogoPrimerAcceso(
  BuildContext context, {
  required String nombreUsuarioActual,
  required String passwordInicial,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false, // solo se sale con Guardar o Cancelar
    builder: (_) => _DialogoPrimerAcceso(
      nombreUsuarioActual: nombreUsuarioActual,
      passwordInicial: passwordInicial,
    ),
  );
}

class _DialogoPrimerAcceso extends ConsumerStatefulWidget {
  const _DialogoPrimerAcceso({required this.nombreUsuarioActual, required this.passwordInicial});
  final String nombreUsuarioActual;
  final String passwordInicial;

  @override
  ConsumerState<_DialogoPrimerAcceso> createState() => _DialogoPrimerAccesoState();
}

class _DialogoPrimerAccesoState extends ConsumerState<_DialogoPrimerAcceso> {
  late final _usuario = TextEditingController(text: widget.nombreUsuarioActual);
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _ocultar = true;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_usuario, _password, _confirmacion]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _problema(String usuario, String password) {
    if (!_reglaUsuario.hasMatch(usuario)) {
      return 'El usuario debe tener entre 4 y 8 caracteres, solo letras y números';
    }
    if (password == widget.passwordInicial) return 'La nueva contraseña debe ser distinta de la inicial';
    if (!passwordEsValida(password)) return 'La nueva contraseña no cumple los requisitos';
    if (password != _confirmacion.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _guardar() async {
    final usuario = _usuario.text.trim().toLowerCase();
    final password = _password.text;
    final problema = _problema(usuario, password);
    if (problema != null) return setState(() => _error = problema);

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(authViewModelProvider.notifier)
          .completarPrimerAcceso(nombreUsuario: usuario, passwordNueva: password);
      if (mounted) Navigator.of(context).pop(usuario);
    } catch (e) {
      // por ejemplo "Ese usuario ya está en uso": se muestra dentro del diálogo para corregirlo
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _cancelar() {
    ref.read(authViewModelProvider.notifier).cancelarPrimerAcceso();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final iconoOjo = IconButton(
      tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
      icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
      color: ColoresApp.textoPlaceholder,
      onPressed: () => setState(() => _ocultar = !_ocultar),
    );

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        // en pantallas pequeñas el teclado no tapa los campos
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Primer ingreso',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Antes de entrar al sistema elige tu usuario y una contraseña propia. '
              'Puedes conservar el usuario que te asignaron.',
              style: TextStyle(color: ColoresApp.textoSuave, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),

            const _Etiqueta('Nombre de usuario'),
            // el check verde aparece solo cuando el usuario cumple la regla
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _usuario,
              builder: (context, valor, _) => _Campo(
                key: const Key('primer_acceso_usuario'),
                controlador: _usuario,
                habilitado: !_guardando,
                icono: Icons.person_outline,
                indicativo: 'Nombre de usuario',
                formateadores: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(8),
                ],
                sufijo: _reglaUsuario.hasMatch(valor.text.toLowerCase())
                    ? const Icon(Icons.check_circle, size: 18, color: _verde)
                    : null,
              ),
            ),
            const _Ayuda('De 4 a 8 letras o números'),
            const SizedBox(height: 14),

            const _Etiqueta('Nueva contraseña'),
            _Campo(
              key: const Key('primer_acceso_password'),
              controlador: _password,
              habilitado: !_guardando,
              icono: Icons.lock_outline,
              indicativo: 'Ingresa al menos 8 caracteres',
              ocultar: _ocultar,
              sufijo: iconoOjo,
            ),
            ChecklistPassword(controlador: _password),
            const SizedBox(height: 14),

            const _Etiqueta('Confirmar contraseña'),
            _Campo(
              key: const Key('primer_acceso_confirmacion'),
              controlador: _confirmacion,
              habilitado: !_guardando,
              icono: Icons.task_alt,
              indicativo: 'Repite la nueva contraseña',
              ocultar: _ocultar,
              sufijo: iconoOjo,
              alEnviar: (_) => _guardar(),
            ),
            // se actualiza al escribir en cualquiera de los dos campos
            ListenableBuilder(
              listenable: Listenable.merge([_password, _confirmacion]),
              builder: (context, _) {
                if (_confirmacion.text.isEmpty) return const SizedBox.shrink();
                final coinciden = _confirmacion.text == _password.text;
                return Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    coinciden ? '✓ Las contraseñas coinciden' : '✕ Las contraseñas aún no coinciden',
                    style: TextStyle(color: coinciden ? _verde : _rojo, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColoresApp.campoBorde),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: ColoresApp.principal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este cambio es obligatorio para tu primer acceso. '
                      'Después inicia sesión con tus nuevos datos.',
                      style: TextStyle(color: ColoresApp.textoSuave, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: _rojo, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextButton(
                      onPressed: _guardando ? null : _cancelar,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: ColoresApp.textoSuave,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2, // Guardar ocupa el doble que Cancelar
                  child: SizedBox(
                    height: 46,
                    child: FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      style: FilledButton.styleFrom(
                        backgroundColor: ColoresApp.principal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        texto,
        style: const TextStyle(color: ColoresApp.textoLabel, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Ayuda extends StatelessWidget {
  const _Ayuda(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(texto, style: const TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 11)),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    super.key,
    required this.controlador,
    required this.habilitado,
    required this.icono,
    required this.indicativo,
    this.ocultar = false,
    this.sufijo,
    this.formateadores,
    this.alEnviar,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final IconData icono;
  final String indicativo;
  final bool ocultar;
  final Widget? sufijo;
  final List<TextInputFormatter>? formateadores;
  final ValueChanged<String>? alEnviar;

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColoresApp.campoBorde),
    );
    return TextField(
      controller: controlador,
      enabled: habilitado,
      obscureText: ocultar,
      inputFormatters: formateadores,
      onSubmitted: alEnviar,
      style: const TextStyle(color: ColoresApp.textoOscuro, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: indicativo,
        hintStyle: const TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 13),
        prefixIcon: Icon(icono, size: 18, color: ColoresApp.textoPlaceholder),
        suffixIcon: sufijo,
        filled: true,
        fillColor: ColoresApp.campoFondo,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: borde,
        enabledBorder: borde,
        disabledBorder: borde,
        focusedBorder: borde.copyWith(borderSide: const BorderSide(color: ColoresApp.principal, width: 1.5)),
      ),
    );
  }
}
