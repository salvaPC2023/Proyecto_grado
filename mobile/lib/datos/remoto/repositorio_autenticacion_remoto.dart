import 'package:dio/dio.dart';

import '../../dominio/repositorios/repositorio_autenticacion.dart';
import 'traducir_errores.dart';

class RepositorioAutenticacionRemoto implements RepositorioAutenticacion {
  RepositorioAutenticacionRemoto(this._dio);
  final Dio _dio;

  @override
  Future<ResultadoLogin> iniciarSesion(String nombreUsuario, String password) {
    return traducirErrores(() async {
      final respuesta = await _dio.post('/auth/login', data: {
        'nombre_usuario': nombreUsuario,
        'password': password,
      });
      return ResultadoLogin(
        token: respuesta.data['access_token'] as String,
        rol: respuesta.data['role'] as String,
      );
    });
  }
}
