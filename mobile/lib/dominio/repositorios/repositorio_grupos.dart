import '../modelos/datos_de_acceso.dart';
import '../modelos/grupo.dart';
import '../modelos/tecnico.dart';

abstract interface class RepositorioGrupos {
  Future<List<Grupo>> listar();

  /// El grupo anterior del supervisor queda sin supervisor
  Future<void> crear({required String nombreDeGrupo, required String supervisorId});

  /// Si el supervisor ya tenía grupo, se intercambian
  Future<void> asignarSupervisor(String grupoId, String supervisorId);

  /// Solo un grupo sin técnicos; si tenía supervisor, este queda sin grupo
  Future<void> eliminar(String grupoId);

  /// Para el administrador: los técnicos de un grupo, para restablecer la contraseña de alguno
  Future<List<Tecnico>> listarTecnicos(String grupoId);

  /// Vuelve la cuenta del técnico a la contraseña inicial; al entrar, debe elegir una nueva
  Future<DatosDeAcceso> restablecerPasswordTecnico(String tecnicoId);
}
