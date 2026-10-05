import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/nucleo/sesion.dart';
import 'package:maintenance_app/presentacion/pantallas/inicio/pantalla_inicio.dart';

import '../modulos/acceso_roles/repositorios_falsos.dart';
import 'app_de_prueba.dart';

void main() {
  testWidgets('saluda al usuario con su rol', (tester) async {
    await montarPantalla(tester, const PantallaInicio(), sesion: perfilTecnico);

    expect(find.text('Técnico Luis Quispe Mamani'), findsOneWidget);
  });

  testWidgets('el técnico va a sus OTs', (tester) async {
    await montarPantalla(tester, const PantallaInicio(), sesion: perfilTecnico);

    await tocar(tester, find.text('Ver Órdenes de Trabajo'));

    expect(find.text('Asignadas'), findsOneWidget); // filtro de la pantalla Mis OTs
  });

  testWidgets('el supervisor va a las OTs de su grupo', (tester) async {
    await montarPantalla(tester, const PantallaInicio(), sesion: perfilSupervisor);

    await tocar(tester, find.text('Ver Órdenes de Trabajo'));

    expect(find.text('Filtrar por:'), findsOneWidget);
  });

  testWidgets('el avatar abre el perfil', (tester) async {
    await montarPantalla(tester, const PantallaInicio(), sesion: perfilSupervisor);

    await tocar(tester, find.byIcon(Icons.person));

    expect(find.text('Mi Perfil'), findsOneWidget);
  });

  testWidgets('cerrar sesión vuelve al login', (tester) async {
    final contenedor = await montarPantalla(tester, const PantallaInicio(), sesion: perfilSupervisor);

    await tocar(tester, find.byIcon(Icons.logout));

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(contenedor.read(sesionProvider), isNull);
  });

  group('barra de navegación', () {
    testWidgets('el supervisor llega a técnicos, nueva OT y vuelve al inicio', (tester) async {
      await montarPantalla(tester, const PantallaInicio(), sesion: perfilSupervisor);

      await tocar(tester, find.byIcon(Icons.groups_outlined));
      expect(find.text('Lista de Técnicos'), findsOneWidget);

      await tocar(tester, find.byIcon(Icons.add));
      expect(find.text('Nueva Orden de Trabajo'), findsOneWidget);

      await tocar(tester, find.byIcon(Icons.home_rounded));
      expect(find.text('Pantalla base'), findsOneWidget);
    });

    testWidgets('el técnico no ve las opciones de supervisor', (tester) async {
      await montarPantalla(tester, const PantallaInicio(), sesion: perfilTecnico);

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.groups_outlined), findsNothing);

      await tocar(tester, find.byIcon(Icons.calendar_today_outlined));
      expect(find.text('Asignadas'), findsOneWidget);
    });
  });
}
