import '../modelos/datos_de_acceso.dart';
import '../modelos/supervisor.dart';

abstract interface class RepositorioSupervisores {
  Future<List<Supervisor>> listar();

  Future<Supervisor> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String nombreDeGrupo,
    required String horarioEntrada,
    required String horarioSalida,
  });

  Future<void> cambiarEstado(String supervisorId, bool activo);

  /// Turno, área y, opcionalmente, grupo: si el grupo ya tiene supervisor, se intercambian.
  /// El nombre y los apellidos no se editan aquí: los cambia la propia persona en Mi Perfil
  Future<Supervisor> editar({
    required String supervisorId,
    required String horarioEntrada,
    required String horarioSalida,
    String? areaDesignada,
    String? grupoId,
  });

  /// Vuelve la cuenta a la contraseña inicial; al entrar, el supervisor debe elegir una nueva
  Future<DatosDeAcceso> restablecerPassword(String supervisorId);
}
