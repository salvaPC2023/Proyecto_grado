import '../modelos/tecnico.dart';

abstract interface class RepositorioTecnicos {
  Future<List<Tecnico>> listar();

  Future<Tecnico> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String nombreUsuario,
    required String profesion,
  });

  Future<void> cambiarEstado(String tecnicoId, bool activo);
}
