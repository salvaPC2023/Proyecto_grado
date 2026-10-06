import 'package:dio/dio.dart';

import '../../dominio/modelos/orden_trabajo.dart';
import '../../dominio/repositorios/repositorio_ubicaciones.dart';
import 'mapeo_json.dart';
import 'traducir_errores.dart';

class RepositorioUbicacionesRemoto implements RepositorioUbicaciones {
  RepositorioUbicacionesRemoto(this._dio);
  final Dio _dio;

  @override
  Future<List<UbicacionTecnica>> listar() {
    return traducirErrores(() async {
      final respuesta = await _dio.get('/ubicaciones-tecnicas');
      return (respuesta.data as List).map((e) => ubicacionDesdeJson(e as Json)).toList();
    });
  }

  @override
  Future<void> guardar({String? id, required String sector, String? subsector, String? sistema, String? subsistema}) {
    final datos = {'sector': sector, 'subsector': subsector, 'sistema': sistema, 'subsistema': subsistema};
    return traducirErrores(() async {
      if (id == null) {
        await _dio.post('/ubicaciones-tecnicas', data: datos);
      } else {
        await _dio.put('/ubicaciones-tecnicas/$id', data: datos);
      }
    });
  }

  @override
  Future<void> borrar(String id) {
    return traducirErrores(() async {
      await _dio.delete('/ubicaciones-tecnicas/$id');
    });
  }
}
