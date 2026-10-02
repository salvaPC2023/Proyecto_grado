/// Error que la capa de datos entrega a las capas superiores, ya traducido a
/// un mensaje para el usuario. Asi la presentacion no depende de Dio.
class ErrorDeAplicacion implements Exception {
  const ErrorDeAplicacion(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}
