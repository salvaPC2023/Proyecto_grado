import '../../dominio/modelos/orden_trabajo.dart';
import '../../dominio/modelos/perfil.dart';
import '../../dominio/modelos/supervisor.dart';
import '../../dominio/modelos/tecnico.dart';


typedef Json = Map<String, dynamic>;

Supervisor supervisorDesdeJson(Json json) {
  return Supervisor(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    apellidoPaterno: json['apellido_paterno'] as String,
    apellidoMaterno: json['apellido_materno'] as String?,
    nombreUsuario: json['nombre_usuario'] as String,
    activo: json['activo'] as bool,
    horarioEntrada: json['horario_entrada'] as String,
    horarioSalida: json['horario_salida'] as String,
    grupoNombre: json['grupo_nombre'] as String?,
  );
}

Tecnico tecnicoDesdeJson(Json json) {
  return Tecnico(
    id: json['id'] as String,
    usuarioId: json['usuario_id'] as String,
    grupoId: json['grupo_id'] as String,
    profesion: json['profesion'] as String,
    nombre: json['nombre'] as String,
    apellidoPaterno: json['apellido_paterno'] as String,
    apellidoMaterno: json['apellido_materno'] as String?,
    nombreUsuario: json['nombre_usuario'] as String,
    activo: json['activo'] as bool,
  );
}

Perfil perfilDesdeJson(Json json) {
  return Perfil(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    apellidoPaterno: json['apellido_paterno'] as String,
    apellidoMaterno: json['apellido_materno'] as String?,
    nombreUsuario: json['nombre_usuario'] as String,
    rol: json['rol'] as String?,
    profesion: json['profesion'] as String?,
    grupoNombre: json['grupo_nombre'] as String?,
    horarioEntrada: json['horario_entrada'] as String?,
    horarioSalida: json['horario_salida'] as String?,
    areaDesignada: json['area_designada'] as String?,
  );
}

UbicacionTecnica ubicacionDesdeJson(Json json) {
  return UbicacionTecnica(
    id: json['id'] as String,
    sector: json['sector'] as String,
    subsector: json['subsector'] as String?,
    sistema: json['sistema'] as String?,
    subsistema: json['subsistema'] as String?,
  );
}

CierrePaso cierreDesdeJson(Json json) {
  return CierrePaso(
    id: json['id'] as String,
    fechaHoraNotificacion: DateTime.parse(json['fecha_hora_notificacion'] as String),
    tiempoRealTrabajado: _aDouble(json['tiempo_real_trabajado'])!,
    trabajoFinalizado: json['trabajo_finalizado'] as bool,
    sinTrabajoRealizado: json['sin_trabajo_realizado'] as bool,
    resultadoTrabajo: json['resultado_trabajo'] as String,
    descripcionTrabajoRealizado: json['descripcion_trabajo_realizado'] as String,
  );
}

PasoOt pasoDesdeJson(Json json) {
  final cierre = json['cierre'];
  return PasoOt(
    id: json['id'] as String,
    numeroPaso: json['numero_paso'] as int,
    descripcion: json['descripcion'] as String,
    claveControl: json['clave_control'] as String,
    horasPlanificadas: _aDouble(json['horas_planificadas']),
    cierre: cierre == null ? null : cierreDesdeJson(cierre as Json),
  );
}

OrdenTrabajo ordenTrabajoDesdeJson(Json json) {
  final ubicacion = json['ubicacion'];
  final fechaCierre = json['fecha_cierre'];
  return OrdenTrabajo(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    tipoDeOrden: json['tipo_de_orden'] as String,
    tecnicoAsignadoId: json['tecnico_asignado_id'] as String,
    descripcion: json['descripcion'] as String,
    prioridad: json['prioridad'] as int,
    estatus: json['estatus'] as String,
    estatusEquipo: json['estatus_equipo'] as bool,
    fechaInicPlanif: DateTime.parse(json['fecha_inic_planif'] as String),
    fechaFinPlanif: DateTime.parse(json['fecha_fin_planif'] as String),
    fechaCierre: fechaCierre == null ? null : DateTime.parse(fechaCierre as String),
    ubicacion: ubicacion == null ? null : ubicacionDesdeJson(ubicacion as Json),
    pasos: (json['pasos'] as List).map((p) => pasoDesdeJson(p as Json)).toList(),
  );
}

Json pasoNuevoAJson(PasoNuevo paso) => {
      'descripcion': paso.descripcion,
      'clave_control': paso.claveControl,
      if (paso.horasPlanificadas != null) 'horas_planificadas': paso.horasPlanificadas,
    };

double? _aDouble(Object? valor) => switch (valor) {
      null => null,
      num n => n.toDouble(),
      String s => double.parse(s),
      _ => null,
    };
