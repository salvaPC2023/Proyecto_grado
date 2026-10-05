import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/presentacion/pantallas/ordenes_trabajo/pantalla_cierre_paso.dart';

import '../../compartido/app_de_prueba.dart';
import '../acceso_roles/repositorios_falsos.dart';
import 'repositorios_falsos.dart';

final pasoPm01 = crearOt().pasos[1]; // "Cambiar filtro", PM01
final campoHoras = find.byType(TextField).at(0);
final campoDescripcion = find.byType(TextField).at(1);
final botonRegistrar = find.widgetWithText(FilledButton, 'Registrar cierre');

void main() {
  testWidgets('pide las horas si el trabajo se ejecutó', (tester) async {
    await montarPantalla(tester, PantallaCierrePaso(otId: 'ot1', paso: pasoPm01), sesion: perfilTecnico);

    await tester.enterText(campoDescripcion, 'Se cambió el filtro');
    await tocar(tester, botonRegistrar);

    expect(find.text('Ingresa las horas trabajadas (mayores a 0)'), findsOneWidget);
  });

  testWidgets('pide la descripción del trabajo', (tester) async {
    await montarPantalla(tester, PantallaCierrePaso(otId: 'ot1', paso: pasoPm01), sesion: perfilTecnico);

    await tester.enterText(campoHoras, '1.5');
    await tocar(tester, botonRegistrar);

    expect(find.text('Describe el trabajo realizado'), findsOneWidget);
  });

  testWidgets('registra el cierre y vuelve a la pantalla anterior', (tester) async {
    final repositorio = RepositorioOrdenesTrabajoFalso();
    await montarPantalla(tester, PantallaCierrePaso(otId: 'ot1', paso: pasoPm01),
        sesion: perfilTecnico, ordenes: repositorio);

    await tester.enterText(campoHoras, '1,5'); // también acepta coma decimal
    await tester.enterText(campoDescripcion, 'Se cambió el filtro');
    await tocar(tester, botonRegistrar);

    expect(repositorio.pasoCerrado, 'p2');
    expect(repositorio.horasDelCierre, 1.5);
    expect(find.text('Pantalla base'), findsOneWidget);
  });

  testWidgets('si no se ejecutó envía 0 horas', (tester) async {
    final repositorio = RepositorioOrdenesTrabajoFalso();
    await montarPantalla(tester, PantallaCierrePaso(otId: 'ot1', paso: pasoPm01),
        sesion: perfilTecnico, ordenes: repositorio);

    await tocar(tester, find.text('No ejecutado'));
    await tester.enterText(campoDescripcion, 'No había repuesto');
    await tocar(tester, botonRegistrar);

    expect(repositorio.cierreEjecutado, isFalse);
    expect(repositorio.horasDelCierre, 0);
  });

  testWidgets('muestra el error del servidor', (tester) async {
    await montarPantalla(tester, PantallaCierrePaso(otId: 'ot1', paso: pasoPm01),
        sesion: perfilTecnico,
        ordenes: RepositorioOrdenesTrabajoFalso(errorAlCerrar: const ErrorDeAplicacion('El paso ya tiene un cierre registrado')));

    await tester.enterText(campoHoras, '1');
    await tester.enterText(campoDescripcion, 'Se cambió el filtro');
    await tocar(tester, botonRegistrar);

    expect(find.text('El paso ya tiene un cierre registrado'), findsOneWidget);
  });
}
