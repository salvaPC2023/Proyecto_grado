import 'package:dio/dio.dart';

import '../../dominio/repositorios/repositorio_estandarizacion.dart';
import 'traducir_errores.dart';

class RepositorioEstandarizacionRemoto implements RepositorioEstandarizacion {
  RepositorioEstandarizacionRemoto(this._dio);
  final Dio _dio;

  @override
  Future<String> estandarizar(String texto) {
    return traducirErrores(() async {
      final respuesta = await _dio.post('/descripciones/estandarizar', data: {'texto': texto});
      return respuesta.data['texto_estandarizado'] as String;
    });
  }
}
