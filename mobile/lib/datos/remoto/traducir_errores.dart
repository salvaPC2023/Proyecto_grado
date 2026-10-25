import 'package:dio/dio.dart';

import '../../dominio/errores.dart';

Future<T> traducirErrores<T>(Future<T> Function() llamada) async {
  try {
    return await llamada();
  } on DioException catch (error) {
    throw _traducir(error);
  }
}

ErrorDeAplicacion _traducir(DioException error) {
  final respuesta = error.response;
  if (respuesta == null) {
    // nunca llegó una respuesta: sin señal, servidor apagado o tiempo de espera agotado
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const ErrorSinConexion(),
      _ => const ErrorDeAplicacion('Error inesperado. Intenta de nuevo.'),
    };
  }

  final datos = respuesta.data;
  final mensaje = datos is Map && datos['detail'] is String ? datos['detail'] as String : 'Error inesperado. Intenta de nuevo.';
  // el login también responde 401 con credenciales incorrectas; el mensaje se conserva igual
  if (respuesta.statusCode == 401) return ErrorSesionVencida(mensaje);
  return ErrorDeAplicacion(mensaje);
}
