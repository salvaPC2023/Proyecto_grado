import 'package:dio/dio.dart';

import '../../dominio/modelos/orden_trabajo.dart';
import '../../dominio/repositorios/repositorio_ordenes_trabajo.dart';
import 'mapeo_json.dart';
import 'traducir_errores.dart';

class RepositorioOrdenesTrabajoRemoto implements RepositorioOrdenesTrabajo {
  RepositorioOrdenesTrabajoRemoto(this._dio);
  final Dio _dio;

  @override
  Future<List<UbicacionTecnica>> listarUbicaciones() {
    return traducirErrores(() async {
      final respuesta = await _dio.get('/ubicaciones-tecnicas');
      return (respuesta.data as List).map((e) => ubicacionDesdeJson(e as Json)).toList();
    });
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
  }) {
    return traducirErrores(() async {
      final respuesta = await _dio.post('/ordenes-trabajo', data: {
        'titulo': titulo,
        'tipo_de_orden': tipoDeOrden,
        'ubicacion_tecnica_id': ubicacionTecnicaId,
        'tecnico_asignado_id': tecnicoAsignadoId,
        'descripcion': descripcion,
        'prioridad': prioridad,
        'estatus_equipo': estatusEquipo,
        'fecha_inic_planif': fechaInicPlanif.toIso8601String(),
        'fecha_fin_planif': fechaFinPlanif.toIso8601String(),
        'pasos': pasos.map(pasoNuevoAJson).toList(),
      });
      return ordenTrabajoDesdeJson(respuesta.data as Json);
    });
  }

  @override
  Future<OrdenTrabajo> obtenerDetalle(String otId) {
    return traducirErrores(() async {
      final respuesta = await _dio.get('/ordenes-trabajo/$otId');
      return ordenTrabajoDesdeJson(respuesta.data as Json);
    });
  }

  @override
  Future<List<OrdenTrabajo>> listarMisOts({DateTime? fecha}) {
    return _listar('/ordenes-trabajo/mis-ots', fecha);
  }

  @override
  Future<List<OrdenTrabajo>> listarOtsGrupo({DateTime? fecha}) {
    return _listar('/ordenes-trabajo/grupo', fecha);
  }

  Future<List<OrdenTrabajo>> _listar(String ruta, DateTime? fecha) {
    return traducirErrores(() async {
      final respuesta = await _dio.get(
        ruta,
        queryParameters: {if (fecha != null) 'fecha': _soloFecha(fecha)},
      );
      return (respuesta.data as List).map((e) => ordenTrabajoDesdeJson(e as Json)).toList();
    });
  }
}

String _soloFecha(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
