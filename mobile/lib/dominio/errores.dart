class ErrorDeAplicacion implements Exception {
  const ErrorDeAplicacion(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// No hubo respuesta del servidor (sin señal o servidor apagado): se puede reintentar más tarde
class ErrorSinConexion extends ErrorDeAplicacion {
  const ErrorSinConexion([super.mensaje = 'No se pudo conectar al servidor']);
}

/// El servidor rechazó el token (vencido o inválido): hay que volver a iniciar sesión
class ErrorSesionVencida extends ErrorDeAplicacion {
  const ErrorSesionVencida(super.mensaje);
}
