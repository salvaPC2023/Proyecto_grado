import '../modelos/perfil.dart';

abstract interface class RepositorioPerfil {
  Future<Perfil> verPerfil();

  Future<Perfil> editarPerfil({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
  });

  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  });
}
