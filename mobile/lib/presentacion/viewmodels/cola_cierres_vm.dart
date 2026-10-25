import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/errores.dart';
import '../../dominio/modelos/cierre_pendiente.dart';
import '../../dominio/repositorios/repositorio_ordenes_trabajo.dart';
import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';
import 'ordenes_trabajo_vm.dart';

/// Envía un cierre (nuevo o de la cola) con su id y su hora; un reenvío con el mismo id no se duplica
Future<void> enviarCierre(RepositorioOrdenesTrabajo repositorio, CierrePendiente cierre) {
  return repositorio.registrarCierre(
    cierreId: cierre.id,
    otId: cierre.otId,
    pasoId: cierre.pasoId,
    ejecutado: cierre.ejecutado,
    tiempoRealTrabajado: cierre.tiempoRealTrabajado,
    descripcion: cierre.descripcion,
    fechaHora: cierre.fechaHora,
  );
}

/// Cierres registrados sin conexión que esperan enviarse. Vive en el celular: sobrevive a cerrar la app
class ColaCierresViewModel extends AsyncNotifier<List<CierrePendiente>> {
  bool _enviando = false;

  @override
  Future<List<CierrePendiente>> build() => ref.read(repositorioColaCierresProvider).leer();

  Future<void> agregar(CierrePendiente cierre) async {
    await _guardar([...await future, cierre]);
  }

  /// Quita un cierre rechazado por el servidor, después de que el técnico vio el motivo
  Future<void> descartar(String cierreId) async {
    await _guardar([for (final c in await future) if (c.id != cierreId) c]);
  }

  /// Envía en orden los cierres de quien tiene la sesión. Se detiene si no hay conexión o si la sesión
  /// venció (se reintenta después); si el servidor rechaza uno, lo marca con el motivo y sigue con el resto.
  /// Devuelve cuántos se enviaron
  Future<int> enviarPendientes() async {
    final sesion = ref.read(sesionProvider);
    if (_enviando || sesion == null || sesion.id.isEmpty) return 0;
    _enviando = true;
    var enviados = 0;
    try {
      for (final cierre in await future) {
        if (cierre.rechazado || cierre.usuarioId != sesion.id) continue;
        try {
          await enviarCierre(ref.read(repositorioOrdenesTrabajoProvider), cierre);
          await _guardar([for (final c in await future) if (c.id != cierre.id) c]);
          ref.invalidate(detalleOtProvider(cierre.otId));
          enviados++;
        } on ErrorSinConexion {
          break; // sigue sin señal: se intenta de nuevo más tarde
        } on ErrorSesionVencida {
          break; // se envía después de volver a iniciar sesión
        } on ErrorDeAplicacion catch (error) {
          // por ejemplo, la OT ya estaba cerrada: reintentarlo no cambiaría la respuesta
          await _guardar([for (final c in await future) c.id == cierre.id ? c.rechazar(error.mensaje) : c]);
        }
      }
      if (enviados > 0) ref.invalidate(misOtsViewModelProvider);
    } finally {
      _enviando = false;
    }
    return enviados;
  }

  Future<void> _guardar(List<CierrePendiente> cierres) async {
    await ref.read(repositorioColaCierresProvider).guardar(cierres);
    state = AsyncValue.data(cierres);
  }
}

final colaCierresViewModelProvider =
    AsyncNotifierProvider<ColaCierresViewModel, List<CierrePendiente>>(ColaCierresViewModel.new);

/// Solo los cierres de quien tiene la sesión: en un celular compartido no se mezclan con los de otro técnico
final misCierresEnColaProvider = Provider<List<CierrePendiente>>((ref) {
  final usuarioId = ref.watch(sesionProvider.select((s) => s?.id));
  final cola = ref.watch(colaCierresViewModelProvider).value ?? const [];
  return [for (final c in cola) if (c.usuarioId == usuarioId) c];
});
