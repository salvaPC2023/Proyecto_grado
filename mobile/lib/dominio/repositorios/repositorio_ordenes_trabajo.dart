import '../modelos/orden_trabajo.dart';

abstract interface class RepositorioOrdenesTrabajo {
  Future<List<UbicacionTecnica>> listarUbicaciones();

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
  });

  Future<OrdenTrabajo> obtenerDetalle(String otId);

  /// Con [fecha], solo las OTs vigentes ese dia.
  Future<List<OrdenTrabajo>> listarMisOts({DateTime? fecha});

  /// OTs de los tecnicos del grupo del Supervisor; con [fecha], las vigentes ese dia.
  Future<List<OrdenTrabajo>> listarOtsGrupo({DateTime? fecha});
}
