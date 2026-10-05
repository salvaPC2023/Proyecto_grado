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
}
