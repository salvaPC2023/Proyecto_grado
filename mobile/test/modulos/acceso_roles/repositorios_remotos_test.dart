import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/datos/remoto/repositorio_autenticacion_remoto.dart';
import 'package:maintenance_app/datos/remoto/repositorio_perfil_remoto.dart';
import 'package:maintenance_app/datos/remoto/repositorio_tecnicos_remoto.dart';
import 'package:maintenance_app/dominio/errores.dart';

import '../../compartido/dio_falso.dart';

// Asi responde el backend
const perfilJson = {
  'id': 'u1',
  'nombre': 'Ana',
  'apellido_paterno': 'Rojas',
  'apellido_materno': null,
  'nombre_usuario': 'ana',
  'rol': 'supervisor',
};

const tecnicoJson = {
  'id': 't1',
  'usuario_id': 'u2',
  'grupo_id': 'g1',
  'profesion': 'electrico',
  'nombre': 'Luis',
  'apellido_paterno': 'Quispe',
  'apellido_materno': 'Mamani',
  'nombre_usuario': 'lquispe',
  'activo': true,
};

void main() {
  test('iniciar sesión envía usuario y contraseña', () async {
    final adaptador = AdaptadorHttpFalso((_) => {'access_token': 'abc', 'role': 'tecnico'});
    final repositorio = RepositorioAutenticacionRemoto(crearDioFalso(adaptador));

    final resultado = await repositorio.iniciarSesion('ana', '1234');

    expect(adaptador.ultima.path, '/auth/login');
    expect(adaptador.ultima.data, {'nombre_usuario': 'ana', 'password': '1234'});
    expect(resultado.token, 'abc');
  });

  test('el error del backend llega como ErrorDeAplicacion', () {
    final adaptador = AdaptadorHttpFalso((_) => {'detail': 'Credenciales inválidas'}, estado: 401);
    final repositorio = RepositorioAutenticacionRemoto(crearDioFalso(adaptador));

    expect(repositorio.iniciarSesion('ana', 'mala'), throwsA(isA<ErrorDeAplicacion>()));
  });

  test('ver y editar el perfil', () async {
    final adaptador = AdaptadorHttpFalso((_) => perfilJson);
    final repositorio = RepositorioPerfilRemoto(crearDioFalso(adaptador));

    final perfil = await repositorio.verPerfil();
    await repositorio.editarPerfil(nombre: 'Ana', apellidoPaterno: 'Rojas');

    expect(perfil.nombreCompleto, 'Ana Rojas');
    expect(adaptador.ultima.method, 'PATCH');
  });

  test('cambiar la contraseña', () async {
    final adaptador = AdaptadorHttpFalso((_) => null);
    final repositorio = RepositorioPerfilRemoto(crearDioFalso(adaptador));

    await repositorio.cambiarPassword(passwordActual: 'vieja', passwordNueva: 'nueva');

    expect(adaptador.ultima.path, '/perfil/password');
  });

  test('listar y crear técnicos', () async {
    final adaptador = AdaptadorHttpFalso((p) => p.method == 'GET' ? [tecnicoJson] : tecnicoJson);
    final repositorio = RepositorioTecnicosRemoto(crearDioFalso(adaptador));

    final tecnicos = await repositorio.listar();
    final creado = await repositorio.crear(
      nombre: 'Luis',
      apellidoPaterno: 'Quispe',
      nombreUsuario: 'lquispe',
      profesion: 'electrico',
    );

    expect(tecnicos.single.nombreCompleto, 'Luis Quispe Mamani');
    expect(creado.nombreUsuario, 'lquispe');
  });

  test('cambiar el estado de un técnico', () async {
    final adaptador = AdaptadorHttpFalso((_) => null);
    final repositorio = RepositorioTecnicosRemoto(crearDioFalso(adaptador));

    await repositorio.cambiarEstado('t1', false);

    expect(adaptador.ultima.path, '/tecnicos/t1/estado');
    expect(adaptador.ultima.data, {'activo': false});
  });
}
