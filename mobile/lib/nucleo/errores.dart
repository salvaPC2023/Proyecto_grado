import '../dominio/errores.dart';

/// Mensaje para mostrar al usuario a partir de cualquier error. La capa de
/// datos ya convierte los errores HTTP en ErrorDeAplicacion.
String mensajeDeError(Object error) {
  if (error is ErrorDeAplicacion) return error.mensaje;
  return 'Error inesperado. Intenta de nuevo.';
}
