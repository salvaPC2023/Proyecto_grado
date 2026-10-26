import 'package:dio/dio.dart';

import '../../dominio/modelos/orden_trabajo.dart';
import '../../dominio/errores.dart';
import '../../dominio/repositorios/repositorio_almacen_local.dart';
import '../../dominio/repositorios/repositorio_ordenes_trabajo.dart';
import 'mapeo_json.dart';
import 'traducir_errores.dart';

class RepositorioOrdenesTrabajoRemoto implements RepositorioOrdenesTrabajo {
  RepositorioOrdenesTrabajoRemoto(this._dio, {this.respaldo, this.alCambiarConexion});
  final Dio _dio;
  // sin conexión, las OT del técnico y su detalle se muestran con lo último que respondió el servidor
  final RepositorioRespaldoLocal? respaldo;
  // avisa si se están mostrando datos guardados (con su hora) o datos recién traídos del servidor (null)
  final void Function(DateTime? datosDe)? alCambiarConexion;

  /// Pide al servidor y guarda una copia; si no hay conexión, devuelve la copia guardada
  Future<T> _conRespaldo<T>(String clave, Future<Response<dynamic>> Function() pedir, T Function(Object? json) convertir) async {
    try {
      final respuesta = await traducirErrores(pedir);
      await respaldo?.guardar(clave, respuesta.data);
      alCambiarConexion?.call(null);
      return convertir(respuesta.data);
    } on ErrorSinConexion {
      final guardado = await respaldo?.leer(clave);
      if (guardado == null) rethrow;
      final (json, guardadoEn) = guardado;
      alCambiarConexion?.call(guardadoEn);
      return convertir(json);
    }
  }

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
    return _conRespaldo('ot_$otId', () => _dio.get('/ordenes-trabajo/$otId'), (json) => ordenTrabajoDesdeJson(json as Json));
  }

  @override
  Future<List<OrdenTrabajo>> listarMisOts({DateTime? fecha}) {
    return _conRespaldo(
      'mis_ots_${fecha == null ? 'todas' : _soloFecha(fecha)}',
      () => _dio.get('/ordenes-trabajo/mis-ots', queryParameters: {if (fecha != null) 'fecha': _soloFecha(fecha)}),
      (json) => (json as List).map((e) => ordenTrabajoDesdeJson(e as Json)).toList(),
    );
  }

  @override
  Future<List<OrdenTrabajo>> listarOtsGrupo({DateTime? fecha}) {
    return _listar('/ordenes-trabajo/grupo', fecha);
  }

  @override
  Future<OrdenTrabajo> registrarCierre({
    required String cierreId,
    required String otId,
    required String pasoId,
    required bool ejecutado,
    required double tiempoRealTrabajado,
    required String descripcion,
    required DateTime fechaHora,
  }) {
    return traducirErrores(() async {
      final respuesta = await _dio.post('/ordenes-trabajo/$otId/pasos/$pasoId/cierre', data: {
        'id': cierreId,
        'resultado_trabajo': ejecutado ? 'ejecutado' : 'no_ejecutado',
        'tiempo_real_trabajado': tiempoRealTrabajado,
        'descripcion_trabajo_realizado': descripcion,
        'fecha_hora_notificacion': fechaHora.toIso8601String(),
      });
      // el detalle guardado se actualiza con el cierre, para verlo bien si luego se pierde la señal
      await respaldo?.guardar('ot_$otId', respuesta.data);
      return ordenTrabajoDesdeJson(respuesta.data as Json);
    });
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
