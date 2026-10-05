import '../modelos/supervisor.dart';

abstract interface class RepositorioSupervisores {
  Future<List<Supervisor>> listar();

  Future<Supervisor> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String nombreUsuario,
    required String nombreDeGrupo,
    required String horarioEntrada,
    required String horarioSalida,
  });

  Future<void> cambiarEstado(String supervisorId, bool activo);
}
