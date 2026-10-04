class ErrorDeAplicacion implements Exception {
  const ErrorDeAplicacion(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}
