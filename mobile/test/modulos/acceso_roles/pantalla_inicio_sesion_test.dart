import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/nucleo/di.dart';
import 'package:maintenance_app/presentacion/pantallas/autenticacion/pantalla_inicio_sesion.dart';

import 'repositorios_falsos.dart';

Future<void> _montar(WidgetTester tester, RepositorioAutenticacionFalso auth) {
  return tester.pumpWidget(ProviderScope(
    overrides: [
      repositorioAutenticacionProvider.overrideWithValue(auth),
      repositorioPerfilProvider.overrideWithValue(RepositorioPerfilFalso()),
    ],
    child: const MaterialApp(home: PantallaInicioSesion()),
  ));
}

Future<void> _tocarIniciarSesion(WidgetTester tester) async {
  final boton = find.text('Iniciar sesión');
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pump();
}

void main() {
  testWidgets('no llama al backend si los campos están vacíos', (tester) async {
    final auth = RepositorioAutenticacionFalso();
    await _montar(tester, auth);

    await _tocarIniciarSesion(tester);

    expect(auth.llamadas, 0);
  });

  testWidgets('muestra el mensaje del backend cuando el login falla', (tester) async {
    final auth = RepositorioAutenticacionFalso(error: const ErrorDeAplicacion('Credenciales inválidas'));
    await _montar(tester, auth);

    await tester.enterText(find.byType(TextField).at(0), 'ana');
    await tester.enterText(find.byType(TextField).at(1), 'mala');
    await _tocarIniciarSesion(tester);
    await tester.pump();

    expect(auth.llamadas, 1);
    expect(find.text('Credenciales inválidas'), findsOneWidget);
  });

  group('primer ingreso de un usuario recién creado', () {
    Future<void> iniciarComoRecienCreado(WidgetTester tester, RepositorioAutenticacionFalso auth) async {
      await _montar(tester, auth);
      await tester.enterText(find.byType(TextField).at(0), 'mqjgeubu');
      await tester.enterText(find.byType(TextField).at(1), 'ESPODI2026');
      await _tocarIniciarSesion(tester);
      await tester.pumpAndSettle();
    }

    Future<void> llenarDialogo(WidgetTester tester, {String usuario = 'cmamani', String password = 'Segura#26'}) async {
      await tester.enterText(find.byKey(const Key('primer_acceso_usuario')), usuario);
      await tester.enterText(find.byKey(const Key('primer_acceso_password')), password);
      await tester.enterText(find.byKey(const Key('primer_acceso_confirmacion')), password);
      // el diálogo es más alto que la pantalla de prueba: se desplaza hasta el botón
      await tester.ensureVisible(find.text('Guardar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
    }

    testWidgets('pide cambiar usuario y contraseña antes de entrar', (tester) async {
      await iniciarComoRecienCreado(tester, RepositorioAutenticacionFalso(recienCreado: true));

      expect(find.text('Primer ingreso'), findsOneWidget);
    });

    testWidgets('si cancela no entra al sistema', (tester) async {
      await iniciarComoRecienCreado(tester, RepositorioAutenticacionFalso(recienCreado: true));

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Primer ingreso'), findsNothing);
      expect(find.text('Debes cambiar tu usuario y contraseña para ingresar al sistema'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget); // sigue en la pantalla de login
    });

    testWidgets('no acepta conservar la contraseña inicial', (tester) async {
      final auth = RepositorioAutenticacionFalso(recienCreado: true);
      await iniciarComoRecienCreado(tester, auth);

      await llenarDialogo(tester, password: 'ESPODI2026');

      expect(find.text('La nueva contraseña debe ser distinta de la inicial'), findsOneWidget);
      expect(auth.usuarioNuevo, isNull);
    });

    testWidgets('al guardar vuelve al login con su usuario nuevo para que entre', (tester) async {
      final auth = RepositorioAutenticacionFalso(recienCreado: true);
      await iniciarComoRecienCreado(tester, auth);

      await llenarDialogo(tester);

      expect(auth.usuarioNuevo, 'cmamani');
      expect(auth.passwordNueva, 'Segura#26');
      expect(find.text('Primer ingreso'), findsNothing);
      expect(find.text('cmamani'), findsOneWidget); // queda escrito en el campo Usuario
      expect(find.text('Datos actualizados. Inicia sesión con tu nuevo usuario y contraseña'), findsOneWidget);
    });

    testWidgets('muestra dentro del diálogo el error del servidor', (tester) async {
      final auth = RepositorioAutenticacionFalso(
        recienCreado: true,
        errorPrimerAcceso: const ErrorDeAplicacion('Ese usuario ya está en uso, elige otro'),
      );
      await iniciarComoRecienCreado(tester, auth);

      await llenarDialogo(tester);

      expect(find.text('Ese usuario ya está en uso, elige otro'), findsOneWidget);
      expect(find.text('Primer ingreso'), findsOneWidget); // puede corregirlo sin salir
    });
  });
}
