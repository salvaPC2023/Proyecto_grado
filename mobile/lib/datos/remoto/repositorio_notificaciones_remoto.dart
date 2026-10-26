import 'package:dio/dio.dart';

import '../../dominio/repositorios/repositorio_notificaciones.dart';
import 'traducir_errores.dart';

class RepositorioNotificacionesRemoto implements RepositorioNotificaciones {
  RepositorioNotificacionesRemoto(this._dio);
  final Dio _dio;

  @override
  Future<void> registrarDispositivo(String token) {
    return traducirErrores(() async {
      await _dio.put('/notificaciones/dispositivo', data: {'token': token});
    });
  }
}
