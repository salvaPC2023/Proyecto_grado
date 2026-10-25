import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/estado_conexion.dart';
import '../../nucleo/tema.dart';
import '../pantallas/ordenes_trabajo/formato_ot.dart';
import '../viewmodels/cola_cierres_vm.dart';

const _ambarFondo = Color(0xFFFEF3C7);
const _ambarTexto = Color(0xFF92400E);
const _rojoFondo = Color(0xFFFEE2E2);
const _rojoTexto = Color(0xFF991B1B);

/// "Sin conexión · datos de las 10:32": se muestran las OT guardadas en el celular
class AvisoDatosSinConexion extends ConsumerWidget {
  const AvisoDatosSinConexion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datosDe = ref.watch(datosSinConexionProvider);
    if (datosDe == null) return const SizedBox.shrink();
    return _Tarjeta(
      fondo: _ambarFondo,
      icono: Icons.cloud_off,
      color: _ambarTexto,
      texto: 'Sin conexión · mostrando los datos de las ${formatoHora(datosDe)}',
    );
  }
}

/// Cierres guardados sin conexión: cuántos faltan enviar y los que el servidor rechazó, con su motivo
class AvisoCierresPendientes extends ConsumerStatefulWidget {
  const AvisoCierresPendientes({super.key});

  @override
  ConsumerState<AvisoCierresPendientes> createState() => _AvisoCierresPendientesState();
}

class _AvisoCierresPendientesState extends ConsumerState<AvisoCierresPendientes> {
  bool _enviando = false;

  Future<void> _enviarAhora() async {
    final mensajero = ScaffoldMessenger.of(context);
    setState(() => _enviando = true);
    final enviados = await ref.read(colaCierresViewModelProvider.notifier).enviarPendientes();
    if (!mounted) return;
    setState(() => _enviando = false);
    mensajero.showSnackBar(SnackBar(
      content: Text(enviados > 0 ? 'Cierres enviados: $enviados' : 'Todavía no hay conexión con el servidor'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cierres = ref.watch(misCierresEnColaProvider);
    final pendientes = cierres.where((c) => !c.rechazado).length;
    final rechazados = cierres.where((c) => c.rechazado).toList();
    if (cierres.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        if (pendientes > 0)
          _Tarjeta(
            fondo: _ambarFondo,
            icono: Icons.cloud_upload_outlined,
            color: _ambarTexto,
            texto: pendientes == 1
                ? '1 cierre pendiente de envío. Se enviará solo cuando vuelva la señal.'
                : '$pendientes cierres pendientes de envío. Se enviarán solos cuando vuelva la señal.',
            accion: TextButton(
              onPressed: _enviando ? null : _enviarAhora,
              child: _enviando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enviar ahora'),
            ),
          ),
        for (final cierre in rechazados)
          _Tarjeta(
            fondo: _rojoFondo,
            icono: Icons.error_outline,
            color: _rojoTexto,
            texto: 'No se registró el cierre de "${cierre.descripcionPaso}"'
                '${cierre.tituloOt.isEmpty ? '' : ' (${cierre.tituloOt})'}: ${cierre.motivoRechazo}',
            accion: TextButton(
              onPressed: () => ref.read(colaCierresViewModelProvider.notifier).descartar(cierre.id),
              child: const Text('Descartar'),
            ),
          ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.fondo, required this.icono, required this.color, required this.texto, this.accion});
  final Color fondo;
  final IconData icono;
  final Color color;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
          ),
          ?accion,
        ],
      ),
    );
  }
}

/// Insignia para un paso cerrado en el celular que aún no llegó al servidor
class InsigniaPendienteDeEnvio extends StatelessWidget {
  const InsigniaPendienteDeEnvio({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _ambarFondo, borderRadius: BorderRadius.circular(9999)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 13, color: _ambarTexto),
          SizedBox(width: 4),
          Text('Pendiente de envío', style: TextStyle(color: _ambarTexto, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Texto suave para aclarar debajo de un botón; se usa en el cierre sin conexión
class NotaSinConexion extends StatelessWidget {
  const NotaSinConexion({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        'Sin conexión: el cierre se guardará en el celular y se enviará solo cuando vuelva la señal.',
        textAlign: TextAlign.center,
        style: TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
      ),
    );
  }
}
