import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/nucleo/di.dart';
import 'package:maintenance_app/nucleo/sesion.dart';
import 'package:maintenance_app/presentacion/viewmodels/auth_vm.dart';

import 'repositorios_falsos.dart';

ProviderContainer _crearContenedor(RepositorioAutenticacionFalso auth) {
  final contenedor = ProviderContainer(overrides: [
    repositorioAutenticacionProvider.overrideWithValue(auth),
    repositorioPerfilProvider.overrideWithValue(RepositorioPerfilFalso()),
  ]);
  addTearDown(contenedor.dispose);
  return contenedor;
}

void main() {
  test('con credenciales correctas guarda la sesión con el perfil', () async {
    final contenedor = _crearContenedor(RepositorioAutenticacionFalso());

    final resultado =
        await contenedor.read(authViewModelProvider.notifier).iniciarSesion('ana', '1234');

    expect(resultado, ResultadoInicioSesion.ingreso);
    final sesion = contenedor.read(sesionProvider)!;
    expect(sesion.token, 'token-falso');
    expect(sesion.nombreCompleto, 'Ana Rojas');
    expect(contenedor.read(authViewModelProvider).hasError, isFalse);
  });

  test('si el login falla deja la sesión vacía y el estado en error', () async {
    final contenedor = _crearContenedor(RepositorioAutenticacionFalso(error: const ErrorDeAplicacion('Credenciales inválidas')));

    final resultado =
        await contenedor.read(authViewModelProvider.notifier).iniciarSesion('ana', 'mala');

    expect(resultado, ResultadoInicioSesion.fallo);
    expect(contenedor.read(sesionProvider), isNull);
    expect(contenedor.read(authViewModelProvider).error, isA<ErrorDeAplicacion>());
  });

  test('un usuario recién creado no abre la sesión hasta cambiar sus datos', () async {
    final contenedor = _crearContenedor(RepositorioAutenticacionFalso(recienCreado: true));

    final resultado =
        await contenedor.read(authViewModelProvider.notifier).iniciarSesion('mqjgeubu', 'ESPODI2026');

    expect(resultado, ResultadoInicioSesion.primerAcceso);
    expect(contenedor.read(sesionProvider), isNull);
  });

  test('el primer acceso usa el token del login y no abre la sesión', () async {
    final auth = RepositorioAutenticacionFalso(recienCreado: true);
    final contenedor = _crearContenedor(auth);
    final vm = contenedor.read(authViewModelProvider.notifier);
    await vm.iniciarSesion('mqjgeubu', 'ESPODI2026');

    await vm.completarPrimerAcceso(nombreUsuario: 'cmamani', passwordNueva: 'Segura#26');

    expect(auth.tokenPrimerAcceso, 'token-falso');
    expect(auth.usuarioNuevo, 'cmamani');
    expect(contenedor.read(sesionProvider), isNull); // debe volver a iniciar sesión
  });
}
