import '../modelos/grupo.dart';

abstract interface class RepositorioGrupos {
  Future<List<Grupo>> listar();

  /// El grupo anterior del supervisor queda sin supervisor
  Future<void> crear({required String nombreDeGrupo, required String supervisorId});

  /// Si el supervisor ya tenía grupo, se intercambian
  Future<void> asignarSupervisor(String grupoId, String supervisorId);
}
