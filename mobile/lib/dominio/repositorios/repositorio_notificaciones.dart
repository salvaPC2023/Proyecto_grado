class NotificacionRecibida {
  const NotificacionRecibida({required this.titulo, required this.cuerpo});

  final String titulo;
  final String cuerpo;
}

/// Notificaciones push del celular (Firebase Cloud Messaging)
abstract interface class ServicioPush {
  /// Pide permiso para mostrar notificaciones y devuelve el token del celular; null si no hay permiso o no hay Firebase
  Future<String?> obtenerToken();

  /// Firebase puede cambiar el token del celular en cualquier momento
  Stream<String> get tokensNuevos;

  /// Con la app abierta, Android no muestra la notificación: la app la recibe aquí
  Stream<NotificacionRecibida> get enPrimerPlano;

  /// Al cerrar sesión: el backend deja de poder enviar a este celular
  Future<void> borrarToken();
}

abstract interface class RepositorioNotificaciones {
  /// Le dice al backend que este celular es del usuario con la sesión abierta
  Future<void> registrarDispositivo(String token);
}
