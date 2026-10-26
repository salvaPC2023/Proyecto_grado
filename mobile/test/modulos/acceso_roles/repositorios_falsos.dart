import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/dominio/modelos/datos_de_acceso.dart';
import 'package:maintenance_app/dominio/modelos/grupo.dart';
import 'package:maintenance_app/dominio/modelos/perfil.dart';
import 'package:maintenance_app/dominio/modelos/supervisor.dart';
import 'package:maintenance_app/dominio/modelos/tecnico.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_autenticacion.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_grupos.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_perfil.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_supervisores.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_tecnicos.dart';

// Implementaciones en memoria, no se llama a la API real

const perfilAdministrador = Perfil(
  id: 'u9',
  nombre: 'Carla',
  apellidoPaterno: 'Vargas',
  apellidoMaterno: null,
  nombreUsuario: 'admin',
  rol: 'administrador',
);

const supervisorAna = Supervisor(
  id: 's1',
  nombre: 'Ana',
  apellidoPaterno: 'Rojas',
  apellidoMaterno: null,
  nombreUsuario: 'ana',
  activo: true,
  horarioEntrada: '07:00:00',
  horarioSalida: '15:00:00',
  grupoNombre: 'Grupo Suministros',
  grupoId: 'g1',
  areaDesignada: 'Embotellado',
);

const supervisorJorge = Supervisor(
  id: 's2',
  nombre: 'Jorge',
  apellidoPaterno: 'Mamani',
  apellidoMaterno: null,
  nombreUsuario: 'jmamani',
  activo: false,
  horarioEntrada: '23:00:00',
  horarioSalida: '07:00:00',
  grupoNombre: 'Grupo Taller',
  grupoId: 'g2',
);

class RepositorioSupervisoresFalso implements RepositorioSupervisores {
  RepositorioSupervisoresFalso({
    this.supervisores = const [supervisorAna, supervisorJorge],
    this.error,
  });

  final List<Supervisor> supervisores;
  final ErrorDeAplicacion? error;

  String? nombreCreado;
  String? horarioEntradaCreado;
  String? idCambiado;

  @override
  Future<List<Supervisor>> listar() async {
    if (error != null) throw error!;
    return supervisores;
  }

  @override
  Future<Supervisor> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String nombreDeGrupo,
    required String horarioEntrada,
    required String horarioSalida,
  }) async {
    nombreCreado = nombre;
    horarioEntradaCreado = horarioEntrada;
    return supervisorAna;
  }

  @override
  Future<void> cambiarEstado(String supervisorId, bool activo) async {
    idCambiado = supervisorId;
  }

  // lo último que se envió al editar: (supervisorId, entrada, salida, área, grupoId)
  (String, String, String, String?, String?)? edicion;

  @override
  Future<Supervisor> editar({
    required String supervisorId,
    required String horarioEntrada,
    required String horarioSalida,
    String? areaDesignada,
    String? grupoId,
  }) async {
    if (error != null) throw error!;
    edicion = (supervisorId, horarioEntrada, horarioSalida, areaDesignada, grupoId);
    return supervisores.firstWhere((s) => s.id == supervisorId);
  }

  String? idRestablecido;

  @override
  Future<DatosDeAcceso> restablecerPassword(String supervisorId) async {
    if (error != null) throw error!;
    idRestablecido = supervisorId;
    final supervisor = supervisores.firstWhere((s) => s.id == supervisorId);
    return (nombreUsuario: supervisor.nombreUsuario, passwordInicial: 'ESPODI2026');
  }
}

const grupoSuministros = Grupo(
  id: 'g1',
  nombreDeGrupo: 'Grupo Suministros',
  cantidadTecnicos: 3,
  supervisorId: 's1',
  supervisorNombre: 'Ana Rojas',
);

const grupoTaller = Grupo(
  id: 'g2',
  nombreDeGrupo: 'Grupo Taller',
  cantidadTecnicos: 2,
  supervisorId: 's2',
  supervisorNombre: 'Jorge Mamani',
);

const grupoVacio = Grupo(id: 'g3', nombreDeGrupo: 'Grupo por error', cantidadTecnicos: 0);

class RepositorioGruposFalso implements RepositorioGrupos {
  RepositorioGruposFalso({
    this.grupos = const [grupoSuministros, grupoTaller, grupoVacio],
    this.tecnicos = const [tecnicoLuis],
    this.error,
  });

  final List<Grupo> grupos;
  final List<Tecnico> tecnicos;
  final ErrorDeAplicacion? error;

  String? idEliminado;
  String? tecnicoRestablecido;

  @override
  Future<List<Tecnico>> listarTecnicos(String grupoId) async => tecnicos.where((t) => t.grupoId == grupoId).toList();

  @override
  Future<DatosDeAcceso> restablecerPasswordTecnico(String tecnicoId) async {
    tecnicoRestablecido = tecnicoId;
    final tecnico = tecnicos.firstWhere((t) => t.id == tecnicoId);
    return (nombreUsuario: tecnico.nombreUsuario, passwordInicial: 'ESPODI2026');
  }

  @override
  Future<List<Grupo>> listar() async => grupos;

  @override
  Future<void> crear({required String nombreDeGrupo, required String supervisorId}) async {}

  @override
  Future<void> asignarSupervisor(String grupoId, String supervisorId) async {}

  @override
  Future<void> eliminar(String grupoId) async {
    if (error != null) throw error!;
    idEliminado = grupoId;
  }
}

const perfilSupervisor = Perfil(
  id: 'u1',
  nombre: 'Ana',
  apellidoPaterno: 'Rojas',
  apellidoMaterno: null,
  nombreUsuario: 'ana',
  rol: 'supervisor',
  grupoNombre: 'Grupo 1',
  horarioEntrada: '08:00:00',
  horarioSalida: '17:00:00',
);

const perfilTecnico = Perfil(
  id: 'u2',
  nombre: 'Luis',
  apellidoPaterno: 'Quispe',
  apellidoMaterno: 'Mamani',
  nombreUsuario: 'lquispe',
  rol: 'tecnico',
  profesion: 'electrico',
  grupoNombre: 'Grupo 1',
);

const tecnicoLuis = Tecnico(
  id: 't1',
  usuarioId: 'u2',
  grupoId: 'g1',
  profesion: 'electrico',
  nombre: 'Luis',
  apellidoPaterno: 'Quispe',
  apellidoMaterno: 'Mamani',
  nombreUsuario: 'lquispe',
  activo: true,
  grupoNombre: 'Grupo Taller',
);

const tecnicoMarco = Tecnico(
  id: 't2',
  usuarioId: 'u3',
  grupoId: 'g1',
  profesion: 'mecanico',
  nombre: 'Marco',
  apellidoPaterno: 'Rojas',
  apellidoMaterno: null,
  nombreUsuario: 'mrojas',
  activo: true,
);

const tecnicoPedro = Tecnico(
  id: 't3',
  usuarioId: 'u4',
  grupoId: 'g1',
  profesion: 'electrico',
  nombre: 'Pedro',
  apellidoPaterno: 'Soliz',
  apellidoMaterno: null,
  nombreUsuario: 'psoliz',
  activo: false,
);

class RepositorioAutenticacionFalso implements RepositorioAutenticacion {
  RepositorioAutenticacionFalso({this.error, this.recienCreado = false, this.errorPrimerAcceso});

  final ErrorDeAplicacion? error;
  // simula a un usuario que aún no cambió su usuario y contraseña
  final bool recienCreado;
  final ErrorDeAplicacion? errorPrimerAcceso;
  int llamadas = 0;

  String? tokenPrimerAcceso;
  String? usuarioNuevo;
  String? passwordNueva;

  @override
  Future<ResultadoLogin> iniciarSesion(String nombreUsuario, String password) async {
    llamadas++;
    if (error != null) throw error!;
    return ResultadoLogin(token: 'token-falso', rol: 'supervisor', debeCambiarCredenciales: recienCreado);
  }

  @override
  Future<void> completarPrimerAcceso({
    required String token,
    required String nombreUsuario,
    required String passwordNueva,
  }) async {
    if (errorPrimerAcceso != null) throw errorPrimerAcceso!;
    tokenPrimerAcceso = token;
    usuarioNuevo = nombreUsuario;
    this.passwordNueva = passwordNueva;
  }
}

class RepositorioPerfilFalso implements RepositorioPerfil {
  RepositorioPerfilFalso({this.perfil = perfilSupervisor, this.error});

  final Perfil perfil;
  final ErrorDeAplicacion? error;

  String? nombreGuardado;
  String? passwordNuevaGuardada;

  @override
  Future<Perfil> verPerfil() async {
    if (error != null) throw error!;
    return perfil;
  }

  @override
  Future<Perfil> editarPerfil({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    if (error != null) throw error!;
    nombreGuardado = nombre;
    return perfil;
  }

  @override
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    passwordNuevaGuardada = passwordNueva;
  }
}

class RepositorioTecnicosFalso implements RepositorioTecnicos {
  RepositorioTecnicosFalso({
    this.tecnicos = const [tecnicoLuis, tecnicoMarco, tecnicoPedro],
    this.error,
  });

  final List<Tecnico> tecnicos;
  final ErrorDeAplicacion? error;

  String? nombreCreado;
  String? profesionCreada;
  String? idCambiado;

  @override
  Future<List<Tecnico>> listar() async {
    if (error != null) throw error!;
    return tecnicos;
  }

  @override
  Future<Tecnico> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String profesion,
  }) async {
    nombreCreado = nombre;
    profesionCreada = profesion;
    return tecnicoLuis;
  }

  @override
  Future<void> cambiarEstado(String tecnicoId, bool activo) async {
    idCambiado = tecnicoId;
  }
}
