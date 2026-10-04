import 'package:dio/dio.dart';

import '../../dominio/modelos/tecnico.dart';
import '../../dominio/repositorios/repositorio_tecnicos.dart';
import 'mapeo_json.dart';
import 'traducir_errores.dart';

class RepositorioTecnicosRemoto implements RepositorioTecnicos {
  RepositorioTecnicosRemoto(this._dio);
  final Dio _dio;

  @override
  Future<List<Tecnico>> listar() {
    return traducirErrores(() async {
      final respuesta = await _dio.get('/tecnicos');
      return (respuesta.data as List).map((e) => tecnicoDesdeJson(e as Json)).toList();
    });
  }

  @override
  Future<Tecnico> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String nombreUsuario,
    required String profesion,
  }) {
    return traducirErrores(() async {
      final respuesta = await _dio.post('/tecnicos', data: {
        'nombre': nombre,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'nombre_usuario': nombreUsuario,
        'profesion': profesion,
      });
      return tecnicoDesdeJson(respuesta.data as Json);
    });
  }

  @override
  Future<void> cambiarEstado(String tecnicoId, bool activo) {
    return traducirErrores(() async {
      await _dio.patch('/tecnicos/$tecnicoId/estado', data: {'activo': activo});
    });
  }
}
