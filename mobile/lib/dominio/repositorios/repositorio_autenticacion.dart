class ResultadoLogin {
  const ResultadoLogin({
    required this.token,
    required this.rol,
    this.debeCambiarCredenciales = false,
  });
  final String token;
  final String rol;
  // usuario recién creado: el token solo sirve para cambiar usuario y contraseña
  final bool debeCambiarCredenciales;
}

abstract interface class RepositorioAutenticacion {
  Future<ResultadoLogin> iniciarSesion(String nombreUsuario, String password);

  /// Primer acceso: se usa el token del login, porque la sesión todavía no se abre
  Future<void> completarPrimerAcceso({
    required String token,
    required String nombreUsuario,
    required String passwordNueva,
  });
}
