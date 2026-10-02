class ResultadoLogin {
  const ResultadoLogin({required this.token, required this.rol});
  final String token;
  final String rol;
}

abstract interface class RepositorioAutenticacion {
  Future<ResultadoLogin> iniciarSesion(String nombreUsuario, String password);
}
