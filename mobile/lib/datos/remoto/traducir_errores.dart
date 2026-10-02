import 'package:dio/dio.dart';

import '../../dominio/errores.dart';

/// Ejecuta una llamada HTTP y convierte cualquier DioException en un
/// ErrorDeAplicacion con el mensaje que el backend manda en "detail"
/// (HTTPException de FastAPI), o uno generico si no hay.
Future<T> traducirErrores<T>(Future<T> Function() llamada) async {
  try {
    return await llamada();
  } on DioException catch (error) {
    throw ErrorDeAplicacion(_mensaje(error));
  }
}

String _mensaje(DioException error) {
  final datos = error.response?.data;
  if (datos is Map && datos['detail'] is String) {
    return datos['detail'] as String;
  }

  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      return 'No se pudo conectar al servidor';
    default:
      return 'Error inesperado. Intenta de nuevo.';
  }
}
