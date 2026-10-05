import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/presentacion/pantallas/tecnicos/pantalla_lista_tecnicos.dart';

import '../../compartido/app_de_prueba.dart';
import 'repositorios_falsos.dart';

void main() {
  testWidgets('muestra los técnicos y cuántos están activos', (tester) async {
    await montarPantalla(tester, const PantallaListaTecnicos(), sesion: perfilSupervisor);

    expect(find.text('2 Técnicos a cargo'), findsOneWidget);
    expect(find.text('Luis Quispe Mamani'), findsOneWidget);
    expect(find.text('Inactivo'), findsOneWidget);
  });

  testWidgets('avisa si no hay técnicos', (tester) async {
    await montarPantalla(tester, const PantallaListaTecnicos(),
        sesion: perfilSupervisor, tecnicos: RepositorioTecnicosFalso(tecnicos: []));

    expect(find.text('No hay técnicos registrados'), findsOneWidget);
  });

  testWidgets('muestra el error del servidor', (tester) async {
    await montarPantalla(tester, const PantallaListaTecnicos(),
        sesion: perfilSupervisor,
        tecnicos: RepositorioTecnicosFalso(error: const ErrorDeAplicacion('Sin conexión')));

    expect(find.text('Sin conexión'), findsOneWidget);
  });

  testWidgets('abre el perfil de un técnico', (tester) async {
    await montarPantalla(tester, const PantallaListaTecnicos(), sesion: perfilSupervisor);

    await tocar(tester, find.byIcon(Icons.chevron_right));

    expect(find.text('Perfil del Técnico'), findsOneWidget);
  });

  testWidgets('abre el registro de técnicos y vuelve a la lista', (tester) async {
    await montarPantalla(tester, const PantallaListaTecnicos(), sesion: perfilSupervisor);

    await tocar(tester, find.byIcon(Icons.person_add));
    expect(find.text('Registrar Técnico'), findsOneWidget);

    await tocar(tester, find.text('Cancelar'));
    expect(find.text('Lista de Técnicos'), findsOneWidget);
  });
}
