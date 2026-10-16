import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../nucleo/tema.dart';

/// Muestra el usuario generado por el backend para entregárselo a la persona registrada
Future<void> mostrarDatosDeAcceso(
  BuildContext context, {
  required String titulo,
  required String nombreUsuario,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // obliga a tocar "Entendido": el usuario no se puede adivinar
    builder: (_) => _DialogoDatosAcceso(titulo: titulo, nombreUsuario: nombreUsuario),
  );
}

class _DialogoDatosAcceso extends StatelessWidget {
  const _DialogoDatosAcceso({required this.titulo, required this.nombreUsuario});
  final String titulo;
  final String nombreUsuario;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, // el diálogo ocupa solo lo necesario
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD1FAE5), width: 4),
              ),
              child: const Icon(Icons.check_rounded, size: 32, color: Color(0xFF059669)),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Entrega estas credenciales para que pueda acceder por primera vez al sistema:',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColoresApp.textoSuave, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColoresApp.campoBorde),
              ),
              child: Column(
                children: [
                  _FilaCredencial(
                    icono: Icons.person_outline,
                    colorIcono: const Color(0xFF2563EB),
                    fondoIcono: const Color(0xFFEFF6FF),
                    etiqueta: 'USUARIO',
                    valor: nombreUsuario,
                  ),
                  const SizedBox(height: 10),
                  const _FilaCredencial(
                    icono: Icons.lock_outline,
                    colorIcono: Color(0xFF4F46E5),
                    fondoIcono: Color(0xFFEEF2FF),
                    etiqueta: 'CONTRASEÑA TEMPORAL',
                    valor: 'ESPODI2026',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: ColoresApp.principal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una credencial con su botón para copiarla; al copiar, el ícono cambia a un check un momento
class _FilaCredencial extends StatefulWidget {
  const _FilaCredencial({
    required this.icono,
    required this.colorIcono,
    required this.fondoIcono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final Color colorIcono;
  final Color fondoIcono;
  final String etiqueta;
  final String valor;

  @override
  State<_FilaCredencial> createState() => _FilaCredencialState();
}

class _FilaCredencialState extends State<_FilaCredencial> {
  bool _copiado = false;

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: widget.valor));
    if (!mounted) return;
    setState(() => _copiado = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copiado = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x99E2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: widget.fondoIcono, borderRadius: BorderRadius.circular(8)),
            child: Icon(widget.icono, size: 16, color: widget.colorIcono),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.etiqueta,
                  style: const TextStyle(
                    color: ColoresApp.textoSuave,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  widget.valor,
                  style: const TextStyle(
                    color: ColoresApp.textoOscuro,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace', // letras de igual ancho: se distingue mejor al dictarlo
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            onPressed: _copiar,
            icon: Icon(
              _copiado ? Icons.check_rounded : Icons.copy_rounded,
              size: 18,
              color: _copiado ? const Color(0xFF059669) : ColoresApp.textoSuave,
            ),
          ),
        ],
      ),
    );
  }
}
