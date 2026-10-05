import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/dominio/modelos/orden_trabajo.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_ordenes_trabajo.dart';

// Implementaciones en memoria, no se llama a la API real

const ubicacionTransformador = UbicacionTecnica(
  id: 'ub1',
  sector: 'Planta Norte',
  subsector: 'Subestación A',
  sistema: 'Transformadores',
  subsistema: 'TR-01',
);

const ubicacionAlmacen = UbicacionTecnica(id: 'ub2', sector: 'Almacén');

final cierreEjecutado = CierrePaso(
  id: 'c1',
  fechaHoraNotificacion: DateTime(2026, 10, 5, 11, 30),
  tiempoRealTrabajado: 1.5,
  trabajoFinalizado: true,
  sinTrabajoRealizado: false,
  resultadoTrabajo: 'ejecutado',
  descripcionTrabajoRealizado: 'Se cambió el filtro',
);

/// Crea una OT de ejemplo
OrdenTrabajo crearOt({
  String id = 'ot1',
  String titulo = 'Revisar transformador',
  String estatus = 'asignada',
  String tecnicoId = 't1',
  List<PasoOt>? pasos,
  DateTime? fechaCierre,
}) {
  return OrdenTrabajo(
    id: id,
    titulo: titulo,
    tipoDeOrden: 'OE01',
    tecnicoAsignadoId: tecnicoId,
    descripcion: 'Descripción de $titulo',
    prioridad: 2,
    estatus: estatus,
    estatusEquipo: false,
    fechaInicPlanif: DateTime(2026, 10, 5, 8),
    fechaFinPlanif: DateTime(2026, 10, 5, 12),
    fechaCierre: fechaCierre,
    ubicacion: ubicacionTransformador,
    pasos: pasos ??
        const [
          PasoOt(id: 'p1', numeroPaso: 1, descripcion: 'Usar EPP', claveControl: 'PMNN'),
          PasoOt(
            id: 'p2',
            numeroPaso: 2,
            descripcion: 'Cambiar filtro',
            claveControl: 'PM01',
            horasPlanificadas: 2,
          ),
        ],
  );
}

class RepositorioOrdenesTrabajoFalso implements RepositorioOrdenesTrabajo {
  RepositorioOrdenesTrabajoFalso({List<OrdenTrabajo>? ots, this.error, this.errorAlCerrar})
      : ots = ots ?? [crearOt()];

  final List<OrdenTrabajo> ots;
  final ErrorDeAplicacion? error;
  final ErrorDeAplicacion? errorAlCerrar;

  DateTime? fechaConsultada;
  String? tituloCreado;
  String? pasoCerrado;
  bool? cierreEjecutado;
  double? horasDelCierre;

  @override
  Future<List<UbicacionTecnica>> listarUbicaciones() async {
    if (error != null) throw error!;
    return const [ubicacionTransformador, ubicacionAlmacen];
  }

  @override
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
  }) async {
    tituloCreado = titulo;
    return crearOt(titulo: titulo);
  }

  @override
  Future<OrdenTrabajo> obtenerDetalle(String otId) async {
    if (error != null) throw error!;
    return ots.firstWhere((ot) => ot.id == otId);
  }

  @override
  Future<List<OrdenTrabajo>> listarMisOts({DateTime? fecha}) async {
    if (error != null) throw error!;
    fechaConsultada = fecha;
    return ots;
  }

  @override
  Future<List<OrdenTrabajo>> listarOtsGrupo({DateTime? fecha}) async {
    if (error != null) throw error!;
    fechaConsultada = fecha;
    return ots;
  }

  @override
  Future<OrdenTrabajo> registrarCierre({
    required String otId,
    required String pasoId,
    required bool ejecutado,
    required double tiempoRealTrabajado,
    required String descripcion,
  }) async {
    if (errorAlCerrar != null) throw errorAlCerrar!;
    pasoCerrado = pasoId;
    cierreEjecutado = ejecutado;
    horasDelCierre = tiempoRealTrabajado;
    return ots.firstWhere((ot) => ot.id == otId);
  }
}
