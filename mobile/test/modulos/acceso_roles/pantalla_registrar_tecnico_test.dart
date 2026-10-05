import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/presentacion/pantallas/tecnicos/pantalla_registrar_tecnico.dart';

import '../../compartido/app_de_prueba.dart';
import 'repositorios_falsos.dart';

void main() {
  testWidgets('pide los campos obligatorios', (tester) async {
    await montarPantalla(tester, const PantallaRegistrarTecnico(), sesion: perfilSupervisor);

    await tocar(tester, find.text('Guardar Técnico'));

    expect(find.text('Completa los campos obligatorios'), findsOneWidget);
  });

  testWidgets('guarda el técnico con la profesión elegida', (tester) async {
    final repositorio = RepositorioTecnicosFalso();
    await montarPantalla(tester, const PantallaRegistrarTecnico(),
        sesion: perfilSupervisor, tecnicos: repositorio);

    await tester.enterText(find.widgetWithText(TextField, 'Ej. Carlos'), 'Carlos');
    await tester.enterText(find.widgetWithText(TextField, 'Ej. Mendoza'), 'Mendoza');
    await tester.enterText(find.widgetWithText(TextField, 'cmendoza_tec'), 'cmendoza');
    await tocar(tester, find.text('Mecánico'));
    await tocar(tester, find.text('Guardar Técnico'));

    expect(repositorio.usuarioCreado, 'cmendoza');
    expect(repositorio.profesionCreada, 'mecanico');
    expect(find.text('Pantalla base'), findsOneWidget); // vuelve a la pantalla anterior
  });
}
