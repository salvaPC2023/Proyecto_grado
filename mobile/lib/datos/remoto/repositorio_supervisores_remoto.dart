import 'package:dio/dio.dart';

import '../../dominio/modelos/supervisor.dart';
import '../../dominio/repositorios/repositorio_supervisores.dart';
import 'mapeo_json.dart';
import 'traducir_errores.dart';

class RepositorioSupervisoresRemoto implements RepositorioSupervisores {
  RepositorioSupervisoresRemoto(this._dio);
  final Dio _dio;

  @override
  Future<List<Supervisor>> listar() {
    return traducirErrores(() async {
      final respuesta = await _dio.get('/supervisores');
      return (respuesta.data as List).map((e) => supervisorDesdeJson(e as Json)).toList();
    });
  }

  @override
  Future<Supervisor> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String nombreDeGrupo,
    required String horarioEntrada,
    required String horarioSalida,
  }) {
    return traducirErrores(() async {
      final respuesta = await _dio.post('/supervisores', data: {
        'nombre': nombre,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'nombre_de_grupo': nombreDeGrupo,
        'horario_entrada': horarioEntrada,
        'horario_salida': horarioSalida,
      });
      return supervisorDesdeJson(respuesta.data as Json);
    });
  }

  @override
  Future<void> cambiarEstado(String supervisorId, bool activo) {
    return traducirErrores(() async {
      await _dio.patch('/supervisores/$supervisorId/estado', data: {'activo': activo});
    });
  }

  @override
  Future<Supervisor> editar({
    required String supervisorId,
    required String horarioEntrada,
    required String horarioSalida,
    String? areaDesignada,
    String? grupoId,
  }) {
    return traducirErrores(() async {
      final respuesta = await _dio.patch('/supervisores/$supervisorId', data: {
        'horario_entrada': horarioEntrada,
        'horario_salida': horarioSalida,
        'area_designada': areaDesignada,
        // el ? solo agrega la clave si grupoId no es null: sin grupo nuevo, se queda en el suyo
        'grupo_id': ?grupoId,
      });
      return supervisorDesdeJson(respuesta.data as Json);
    });
  }
}
