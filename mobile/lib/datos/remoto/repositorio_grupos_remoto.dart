import 'package:dio/dio.dart';

import '../../dominio/modelos/grupo.dart';
import '../../dominio/repositorios/repositorio_grupos.dart';
import 'mapeo_json.dart';
import 'traducir_errores.dart';

class RepositorioGruposRemoto implements RepositorioGrupos {
  RepositorioGruposRemoto(this._dio);
  final Dio _dio;

  @override
  Future<List<Grupo>> listar() {
    return traducirErrores(() async {
      final respuesta = await _dio.get('/grupos');
      return (respuesta.data as List).map((e) => grupoDesdeJson(e as Json)).toList();
    });
  }

  @override
  Future<void> crear({required String nombreDeGrupo, required String supervisorId}) {
    return traducirErrores(() async {
      await _dio.post('/grupos', data: {'nombre_de_grupo': nombreDeGrupo, 'supervisor_id': supervisorId});
    });
  }

  @override
  Future<void> asignarSupervisor(String grupoId, String supervisorId) {
    return traducirErrores(() async {
      await _dio.patch('/grupos/$grupoId/supervisor', data: {'supervisor_id': supervisorId});
    });
  }
}
