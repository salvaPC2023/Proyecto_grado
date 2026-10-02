import 'package:dio/dio.dart';

import '../../dominio/modelos/perfil.dart';
import '../../dominio/repositorios/repositorio_perfil.dart';
import 'mapeo_json.dart';
import 'traducir_errores.dart';

class RepositorioPerfilRemoto implements RepositorioPerfil {
  RepositorioPerfilRemoto(this._dio);
  final Dio _dio;

  @override
  Future<Perfil> verPerfil() {
    return traducirErrores(() async {
      final respuesta = await _dio.get('/perfil');
      return perfilDesdeJson(respuesta.data as Json);
    });
  }

  @override
  Future<Perfil> editarPerfil({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
  }) {
    return traducirErrores(() async {
      final respuesta = await _dio.patch('/perfil', data: {
        'nombre': nombre,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
      });
      return perfilDesdeJson(respuesta.data as Json);
    });
  }

  @override
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) {
    return traducirErrores(() async {
      await _dio.patch('/perfil/password', data: {
        'password_actual': passwordActual,
        'password_nueva': passwordNueva,
      });
    });
  }
}
