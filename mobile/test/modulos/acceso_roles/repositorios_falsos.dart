import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/dominio/modelos/perfil.dart';
import 'package:maintenance_app/dominio/modelos/tecnico.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_autenticacion.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_perfil.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_tecnicos.dart';

// Implementaciones en memoria, no se llama a la API real

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
  RepositorioAutenticacionFalso({this.error});

  final ErrorDeAplicacion? error;
  int llamadas = 0;

  @override
  Future<ResultadoLogin> iniciarSesion(String nombreUsuario, String password) async {
    llamadas++;
    if (error != null) throw error!;
    return const ResultadoLogin(token: 'token-falso', rol: 'supervisor');
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

  String? usuarioCreado;
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
    required String nombreUsuario,
    required String profesion,
  }) async {
    usuarioCreado = nombreUsuario;
    profesionCreada = profesion;
    return tecnicoLuis;
  }

  @override
  Future<void> cambiarEstado(String tecnicoId, bool activo) async {
    idCambiado = tecnicoId;
  }
}
