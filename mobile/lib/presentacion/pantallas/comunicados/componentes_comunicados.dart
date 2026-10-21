import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/comunicado.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/sesion.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/comunicados_vm.dart';
import '../ordenes_trabajo/formato_ot.dart';

/// Nombre, color e ícono de cada categoría; el color identifica la tarjeta en el tablón
extension EstiloCategoria on CategoriaComunicado {
  String get etiqueta => switch (this) {
        CategoriaComunicado.seguridad => 'Seguridad',
        CategoriaComunicado.mantenimiento => 'Mantenimiento',
        CategoriaComunicado.produccion => 'Producción',
        CategoriaComunicado.general => 'General',
      };

  Color get color => switch (this) {
        CategoriaComunicado.seguridad => const Color(0xFFF59E0B),
        CategoriaComunicado.mantenimiento => const Color(0xFF0284C7),
        CategoriaComunicado.produccion => const Color(0xFF059669),
        CategoriaComunicado.general => const Color(0xFF64748B),
      };

  IconData get icono => switch (this) {
        CategoriaComunicado.seguridad => Icons.health_and_safety_outlined,
        CategoriaComunicado.mantenimiento => Icons.build_outlined,
        CategoriaComunicado.produccion => Icons.factory_outlined,
        CategoriaComunicado.general => Icons.campaign_outlined,
      };
}

/// "Hoy 09:15", "Ayer 18:20" o "15 Oct"
String cuandoSeEnvio(DateTime fecha) {
  final hoy = DateUtils.dateOnly(DateTime.now());
  final dia = DateUtils.dateOnly(fecha);
  if (dia == hoy) return 'Hoy ${formatoHora(fecha)}';
  if (dia == hoy.subtract(const Duration(days: 1))) return 'Ayer ${formatoHora(fecha)}';
  return '${dosDigitos(fecha.day)} ${nombreMes(fecha)}';
}

String venceEl(DateTime fecha) => 'Vence ${dosDigitos(fecha.day)} ${nombreMes(fecha)}';

/// Botón "+" junto al título de una sección; solo lo ve el supervisor
class BotonNuevoComunicado extends StatelessWidget {
  const BotonNuevoComunicado({super.key, required this.onTap, required this.descripcion});
  final VoidCallback onTap;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: descripcion,
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(9999)),
          child: const Text('+', style: TextStyle(color: ColoresApp.principal, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

/// Imagen del comunicado, descargada con la sesión del usuario
class ImagenComunicado extends ConsumerWidget {
  const ImagenComunicado({super.key, required this.comunicadoId, this.ajuste = BoxFit.cover});
  final String comunicadoId;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(imagenComunicadoProvider(comunicadoId)).when(
          data: (bytes) => Image.memory(bytes, fit: ajuste, width: double.infinity),
          // sin indicador que gire: la tarjeta muestra un fondo liso mientras llega
          loading: () => const ColoredBox(color: Color(0xFFF1F5F9)),
          error: (_, _) => const ColoredBox(
            color: Color(0xFFF1F5F9),
            child: Center(child: Icon(Icons.broken_image_outlined, color: ColoresApp.textoPlaceholder)),
          ),
        );
  }
}

/// Comunicado completo en una hoja inferior; el supervisor puede retirarlo desde aquí
Future<void> mostrarDetalleComunicado(BuildContext context, Comunicado comunicado) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _DetalleComunicado(comunicado: comunicado),
  );
}

class _DetalleComunicado extends ConsumerStatefulWidget {
  const _DetalleComunicado({required this.comunicado});
  final Comunicado comunicado;

  @override
  ConsumerState<_DetalleComunicado> createState() => _DetalleComunicadoState();
}

class _DetalleComunicadoState extends ConsumerState<_DetalleComunicado> {
  bool _retirando = false;

  Future<void> _retirar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Retirar comunicado'),
        content: const Text('Dejará de verse para los técnicos. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(contexto).pop(true), child: const Text('Retirar')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final mensajero = ScaffoldMessenger.of(context);
    setState(() => _retirando = true);
    try {
      await ref.read(comunicadosViewModelProvider.notifier).retirar(widget.comunicado.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      mensajero.showSnackBar(const SnackBar(content: Text('Comunicado retirado')));
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
      if (mounted) setState(() => _retirando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comunicado;
    final esSupervisor = ref.watch(sesionProvider)?.esSupervisor ?? false;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(c.categoria.icono, size: 18, color: c.categoria.color),
                const SizedBox(width: 6),
                Text(c.categoria.etiqueta, style: TextStyle(color: c.categoria.color, fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                Text(venceEl(c.fechaExpiracion), style: const TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Text(c.titulo, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              esSupervisor
                  ? (c.personal ? 'Para ${c.destinatarioNombre ?? ''} · ${cuandoSeEnvio(c.fechaEnvio)}' : 'Para todo el grupo · ${cuandoSeEnvio(c.fechaEnvio)}')
                  : 'De ${c.autorNombre} · ${cuandoSeEnvio(c.fechaEnvio)}',
              style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
            ),
            if (c.tieneImagen) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ImagenComunicado(comunicadoId: c.id, ajuste: BoxFit.contain),
                ),
              ),
            ],
            if (c.texto != null) ...[
              const SizedBox(height: 14),
              Text(c.texto!, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, height: 1.5)),
            ],
            if (esSupervisor) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _retirando ? null : _retirar,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Retirar comunicado'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
