class UbicacionTecnica {
  const UbicacionTecnica({
    required this.id,
    required this.sector,
    this.subsector,
    this.sistema,
    this.subsistema,
  });

  final String id;
  final String sector;
  final String? subsector;
  final String? sistema;
  final String? subsistema;

  List<String> get niveles => [sector, subsector, sistema, subsistema]
      .whereType<String>()
      .where((n) => n.isNotEmpty)
      .toList();

  /// "Embotellado / Area 1 / Llenadora / Sistema de Dosificacion"
  String get ruta => niveles.join(' / ');

  /// El nivel mas especifico, para las tarjetas donde no entra la ruta completa.
  String get nombreCorto => niveles.last;

  /// Los dos niveles mas especificos: "Etiquetadora · Aplicador de Etiquetas".
  String get resumen => niveles.skip(niveles.length > 1 ? niveles.length - 2 : 0).join(' · ');
}

/// Cierre registrado por el Tecnico sobre un paso PM01.
class CierrePaso {
  const CierrePaso({
    required this.id,
    required this.fechaHoraNotificacion,
    required this.tiempoRealTrabajado,
    required this.trabajoFinalizado,
    required this.sinTrabajoRealizado,
    required this.resultadoTrabajo,
    required this.descripcionTrabajoRealizado,
  });

  final String id;
  final DateTime fechaHoraNotificacion;
  final double tiempoRealTrabajado;
  final bool trabajoFinalizado;
  final bool sinTrabajoRealizado;
  final String resultadoTrabajo; // 'ejecutado' | 'no_ejecutado'
  final String descripcionTrabajoRealizado;
}

class PasoOt {
  const PasoOt({
    required this.id,
    required this.numeroPaso,
    required this.descripcion,
    required this.claveControl,
    this.horasPlanificadas,
    this.cierre,
  });

  final String id;
  final int numeroPaso;
  final String descripcion;
  final String claveControl; // 'PM01' | 'PMNN'
  final double? horasPlanificadas;
  final CierrePaso? cierre; // null = sin cerrar (los PMNN nunca se cierran)

  bool get esPm01 => claveControl == 'PM01';
  bool get cerrado => cierre != null;
}

class OrdenTrabajo {
  const OrdenTrabajo({
    required this.id,
    required this.titulo,
    required this.tipoDeOrden,
    required this.tecnicoAsignadoId,
    required this.descripcion,
    required this.prioridad,
    required this.estatus,
    required this.estatusEquipo,
    required this.fechaInicPlanif,
    required this.fechaFinPlanif,
    required this.pasos,
    this.ubicacion,
    this.fechaCierre,
  });

  final String id;
  final String titulo;
  final String tipoDeOrden;
  final String tecnicoAsignadoId;
  final String descripcion;
  final int prioridad; // 1 = Urgente ... 4 = Baja
  final String estatus; // 'asignada' | 'en_progreso' | 'cerrada'
  final bool estatusEquipo; // true = en funcionamiento, false = detenido
  final DateTime fechaInicPlanif;
  final DateTime fechaFinPlanif;
  final DateTime? fechaCierre;
  final UbicacionTecnica? ubicacion;
  final List<PasoOt> pasos;

  /// Suma de las horas planificadas de los pasos PM01 (los PMNN no llevan horas).
  double get horasPlanificadas => pasos
      .where((p) => p.esPm01)
      .fold(0, (total, p) => total + (p.horasPlanificadas ?? 0));

  /// Avance = pasos PM01 cerrados / total de PM01 (los PMNN son informativos).
  int get pm01Total => pasos.where((p) => p.esPm01).length;
  int get pm01Cerrados => pasos.where((p) => p.esPm01 && p.cerrado).length;
}

/// Paso que el Supervisor agrega al crear la OT (todavia sin id ni numero).
class PasoNuevo {
  const PasoNuevo({
    required this.descripcion,
    required this.claveControl,
    this.horasPlanificadas,
  });

  final String descripcion;
  final String claveControl;
  final double? horasPlanificadas;
}
