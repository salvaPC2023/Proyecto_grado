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

    final exito =
        await contenedor.read(authViewModelProvider.notifier).iniciarSesion('ana', '1234');

    expect(exito, isTrue);
    final sesion = contenedor.read(sesionProvider)!;
    expect(sesion.token, 'token-falso');
    expect(sesion.nombreCompleto, 'Ana Rojas');
    expect(contenedor.read(authViewModelProvider).hasError, isFalse);
  });

  test('si el login falla deja la sesión vacía y el estado en error', () async {
    final contenedor = _crearContenedor(RepositorioAutenticacionFalso(error: const ErrorDeAplicacion('Credenciales inválidas')));

    final exito =
        await contenedor.read(authViewModelProvider.notifier).iniciarSesion('ana', 'mala');

    expect(exito, isFalse);
    expect(contenedor.read(sesionProvider), isNull);
    expect(contenedor.read(authViewModelProvider).error, isA<ErrorDeAplicacion>());
  });
}
