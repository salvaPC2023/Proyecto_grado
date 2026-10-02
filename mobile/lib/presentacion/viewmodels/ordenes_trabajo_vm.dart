import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelos/orden_trabajo.dart';
import '../../nucleo/di.dart';
import '../../nucleo/fechas.dart';

/// Pantalla "Nueva OT" (Supervisor): su estado es el catalogo de
/// ubicaciones tecnicas para elegir una; `crear` registra la OT.
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

  /// Lanza si el backend la rechaza (ej. 400 sin PM01) — la pantalla lo
  /// atrapa con try/catch para mostrar el mensaje.
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

/// Lista "Mis OTs" (Tecnico): siempre las OTs de un dia; por defecto, hoy.
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

/// Detalle de una OT. Una instancia por id; se descarta al salir de la pantalla.
final detalleOtProvider = FutureProvider.autoDispose.family<OrdenTrabajo, String>(
  (ref, otId) => ref.read(repositorioOrdenesTrabajoProvider).obtenerDetalle(otId),
);

/// "Ordenes de Trabajo" del Supervisor: las OTs de su grupo en un dia.
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
