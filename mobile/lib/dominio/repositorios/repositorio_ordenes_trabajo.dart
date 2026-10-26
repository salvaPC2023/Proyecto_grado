import '../modelos/orden_trabajo.dart';

abstract interface class RepositorioOrdenesTrabajo {
  Future<List<UbicacionTecnica>> listarUbicaciones();

  Future<OrdenTrabajo> crear({
    required String titulo,
    required String tipoDeOrden,
    required String ubicacionTecnicaId,
    required String tecnicoAsignadoId,
    required int prioridad,
    required bool estatusEquipo,
    required DateTime fechaInicPlanif,
    required DateTime fechaFinPlanif,
    required List<PasoNuevo> pasos,
  });

  Future<OrdenTrabajo> obtenerDetalle(String otId);

  Future<List<OrdenTrabajo>> listarMisOts({DateTime? fecha});

  Future<List<OrdenTrabajo>> listarOtsGrupo({DateTime? fecha});

  /// Registra el cierre de un paso PM01 y devuelve la OT actualizada.
  /// [cierreId] y [fechaHora] se generan en el celular: un reenvío con el mismo id no se duplica
  Future<OrdenTrabajo> registrarCierre({
    required String cierreId,
    required String otId,
    required String pasoId,
    required bool ejecutado,
    required double tiempoRealTrabajado,
    required String descripcion,
    required DateTime fechaHora,
  });
}
