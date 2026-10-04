import '../dominio/errores.dart';

String mensajeDeError(Object error) {
  if (error is ErrorDeAplicacion) return error.mensaje;
  return 'Error inesperado. Intenta de nuevo.';
}
