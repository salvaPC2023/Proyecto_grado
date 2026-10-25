import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../dominio/errores.dart';
import '../../dominio/modelos/cierre_pendiente.dart';
import '../../dominio/modelos/orden_trabajo.dart';
import '../../nucleo/di.dart';
import '../../nucleo/fechas.dart';
import '../../nucleo/sesion.dart';
import 'cola_cierres_vm.dart';

class NuevaOtViewModel extends AsyncNotifier<List<UbicacionTecnica>> {
  @override
  Future<List<UbicacionTecnica>> build() {
    return ref.read(repositorioOrdenesTrabajoProvider).listarUbicaciones();
  }

  Future<void> recargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(repositorioOrdenesTrabajoProvider).listarUbicaciones(),
    );
  }

  Future<OrdenTrabajo> crear({
    required String titulo,
    required String tipoDeOrden,
    required String ubicacionTecnicaId,
    required String tecnicoAsignadoId,
    required String descripcion,
    required int prioridad,
    required bool estatusEquipo,
    required DateTime fechaInicPlanif,
    required DateTime fechaFinPlanif,
    required List<PasoNuevo> pasos,
  }) {
    return ref.read(repositorioOrdenesTrabajoProvider).crear(
          titulo: titulo,
          tipoDeOrden: tipoDeOrden,
          ubicacionTecnicaId: ubicacionTecnicaId,
          tecnicoAsignadoId: tecnicoAsignadoId,
          descripcion: descripcion,
          prioridad: prioridad,
          estatusEquipo: estatusEquipo,
          fechaInicPlanif: fechaInicPlanif,
          fechaFinPlanif: fechaFinPlanif,
          pasos: pasos,
        );
  }
}

final nuevaOtViewModelProvider =
    AsyncNotifierProvider.autoDispose<NuevaOtViewModel, List<UbicacionTecnica>>(
  NuevaOtViewModel.new,
);

class MisOtsViewModel extends AsyncNotifier<List<OrdenTrabajo>> {
  DateTime fecha = hoySinHora();

  @override
  Future<List<OrdenTrabajo>> build() {
    return ref.read(repositorioOrdenesTrabajoProvider).listarMisOts(fecha: fecha);
  }

  Future<void> filtrarPorFecha(DateTime nuevaFecha) async {
    fecha = nuevaFecha;
    await recargar();
  }

  Future<void> recargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(repositorioOrdenesTrabajoProvider).listarMisOts(fecha: fecha),
    );
  }
}

final misOtsViewModelProvider =
    AsyncNotifierProvider.autoDispose<MisOtsViewModel, List<OrdenTrabajo>>(
  MisOtsViewModel.new,
);

final detalleOtProvider = FutureProvider.autoDispose.family<OrdenTrabajo, String>(
  (ref, otId) => ref.read(repositorioOrdenesTrabajoProvider).obtenerDetalle(otId),
);

class OtsGrupoViewModel extends AsyncNotifier<List<OrdenTrabajo>> {
  DateTime fecha = hoySinHora();

  @override
  Future<List<OrdenTrabajo>> build() {
    return ref.read(repositorioOrdenesTrabajoProvider).listarOtsGrupo(fecha: fecha);
  }

  Future<void> filtrarPorFecha(DateTime nuevaFecha) async {
    fecha = nuevaFecha;
    await recargar();
  }

  Future<void> recargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(repositorioOrdenesTrabajoProvider).listarOtsGrupo(fecha: fecha),
    );
  }
}

final otsGrupoViewModelProvider =
    AsyncNotifierProvider.autoDispose<OtsGrupoViewModel, List<OrdenTrabajo>>(
  OtsGrupoViewModel.new,
);

enum ResultadoCierre { registrado, pendienteDeEnvio, fallo }

class CierrePasoViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Intenta enviarlo; sin conexión lo guarda en la cola del celular para enviarlo cuando vuelva la señal
  Future<ResultadoCierre> registrar({
    required String otId,
    required String pasoId,
    required bool ejecutado,
    required double tiempoRealTrabajado,
    required String descripcion,
    String tituloOt = '',
    String descripcionPaso = '',
  }) async {
    state = const AsyncValue.loading();
    // id y hora se fijan aquí, al cerrar el paso: son los mismos en cada reintento
    final cierre = CierrePendiente(
      id: const Uuid().v4(),
      usuarioId: ref.read(sesionProvider)?.id ?? '',
      otId: otId,
      pasoId: pasoId,
      ejecutado: ejecutado,
      tiempoRealTrabajado: tiempoRealTrabajado,
      descripcion: descripcion,
      fechaHora: DateTime.now(),
      tituloOt: tituloOt,
      descripcionPaso: descripcionPaso,
    );
    try {
      await enviarCierre(ref.read(repositorioOrdenesTrabajoProvider), cierre);
      ref.invalidate(detalleOtProvider(otId)); // el detalle se vuelve a pedir con el cierre nuevo
      state = const AsyncValue.data(null);
      return ResultadoCierre.registrado;
    } on ErrorSinConexion {
      await ref.read(colaCierresViewModelProvider.notifier).agregar(cierre);
      state = const AsyncValue.data(null);
      return ResultadoCierre.pendienteDeEnvio;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return ResultadoCierre.fallo;
    }
  }
}

final cierrePasoViewModelProvider =
    NotifierProvider.autoDispose<CierrePasoViewModel, AsyncValue<void>>(CierrePasoViewModel.new);
