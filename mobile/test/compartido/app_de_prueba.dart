import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/modelos/perfil.dart';
import 'package:maintenance_app/nucleo/di.dart';
import 'package:maintenance_app/nucleo/sesion.dart';

import '../modulos/acceso_roles/repositorios_falsos.dart';
import '../modulos/ordenes_trabajo/repositorios_falsos.dart';

/// Crea un contenedor de Riverpod que usa los repositorios falsos en vez de la API
ProviderContainer crearContenedor({
  Perfil? sesion,
  RepositorioAutenticacionFalso? auth,
  RepositorioPerfilFalso? perfil,
  RepositorioTecnicosFalso? tecnicos,
  RepositorioOrdenesTrabajoFalso? ordenes,
  RepositorioSupervisoresFalso? supervisores,
}) {
  final contenedor = ProviderContainer(
    retry: (_, _) => null, // el error se ve de inmediato
    overrides: [
      repositorioAutenticacionProvider.overrideWithValue(auth ?? RepositorioAutenticacionFalso()),
      repositorioPerfilProvider.overrideWithValue(perfil ?? RepositorioPerfilFalso()),
      repositorioTecnicosProvider.overrideWithValue(tecnicos ?? RepositorioTecnicosFalso()),
      repositorioOrdenesTrabajoProvider.overrideWithValue(ordenes ?? RepositorioOrdenesTrabajoFalso()),
      repositorioSupervisoresProvider.overrideWithValue(supervisores ?? RepositorioSupervisoresFalso()),
    ],
  );
  addTearDown(contenedor.dispose);

  if (sesion != null) {
    contenedor.read(sesionProvider.notifier)
      ..establecerToken(token: 'token-falso', rol: sesion.rol!)
      ..completarConPerfil(sesion);
  }
  return contenedor;
}

/// Muestra pantalla con datos falsos. Queda encima de una pantalla vacia para que los botones de "volver" tengan por donde regresar
Future<ProviderContainer> montarPantalla(
  WidgetTester tester,
  Widget pantalla, {
  Perfil? sesion,
  RepositorioAutenticacionFalso? auth,
  RepositorioPerfilFalso? perfil,
  RepositorioTecnicosFalso? tecnicos,
  RepositorioOrdenesTrabajoFalso? ordenes,
  RepositorioSupervisoresFalso? supervisores,
}) async {
  // Pantalla grande de los tests es mas ancha que la real
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final contenedor = crearContenedor(
    sesion: sesion,
    auth: auth,
    perfil: perfil,
    tecnicos: tecnicos,
    ordenes: ordenes,
    supervisores: supervisores,
  );

  await tester.pumpWidget(UncontrolledProviderScope(
    container: contenedor,
    child: const MaterialApp(home: Scaffold(body: Text('Pantalla base'))),
  ));
  final navegador = tester.state<NavigatorState>(find.byType(Navigator));
  navegador.push(MaterialPageRoute(builder: (_) => pantalla));
  await tester.pumpAndSettle();
  return contenedor;
}

/// Toca un widget y espera a que todo termine
Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}
