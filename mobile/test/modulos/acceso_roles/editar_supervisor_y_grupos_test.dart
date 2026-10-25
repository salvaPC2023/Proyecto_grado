import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/presentacion/pantallas/grupos/pantalla_grupos.dart';
import 'package:maintenance_app/presentacion/pantallas/supervisores/pantalla_lista_supervisores.dart';

import '../../compartido/app_de_prueba.dart';
import 'repositorios_falsos.dart';

void main() {
  group('editar supervisor', () {
    Future<RepositorioSupervisoresFalso> abrirEdicionDeAna(WidgetTester tester) async {
      final repositorio = RepositorioSupervisoresFalso();
      await montarPantalla(tester, const PantallaListaSupervisores(), sesion: perfilAdministrador, supervisores: repositorio);
      await tocar(tester, find.widgetWithText(TextButton, 'Editar')); // el primero es Ana
      return repositorio;
    }

    testWidgets('muestra el área del supervisor en la lista', (tester) async {
      await montarPantalla(tester, const PantallaListaSupervisores(), sesion: perfilAdministrador);

      expect(find.text('Área: Embotellado'), findsOneWidget);
    });

    testWidgets('abre con el turno, el área y el grupo actuales', (tester) async {
      await abrirEdicionDeAna(tester);

      expect(find.text('Editar Ana Rojas'), findsOneWidget);
      expect(find.text('Turno 2 (07:00 - 15:00)'), findsOneWidget);
      expect(find.text('Embotellado'), findsOneWidget);
      expect(find.text('Grupo Suministros'), findsOneWidget);
    });

    testWidgets('guarda turno y área sin reenviar el grupo si no cambió', (tester) async {
      final repositorio = await abrirEdicionDeAna(tester);

      await tocar(tester, find.byKey(const Key('editar_supervisor_turno')));
      await tocar(tester, find.text('Turno 1 (23:00 - 07:00)').last);
      await tester.enterText(find.byKey(const Key('editar_supervisor_area')), 'Procesos');
      await tocar(tester, find.text('Guardar'));

      expect(repositorio.edicion, ('s1', '23:00', '07:00', 'Procesos', null));
      expect(find.text('Supervisor actualizado'), findsOneWidget);
    });

    testWidgets('al elegir un grupo con supervisor avisa del intercambio y lo envía', (tester) async {
      final repositorio = await abrirEdicionDeAna(tester);

      await tocar(tester, find.byKey(const Key('editar_supervisor_grupo')));
      await tocar(tester, find.text('Grupo Taller · Jorge Mamani').last);

      expect(find.text('Los grupos se intercambian: Jorge Mamani pasará al grupo "Grupo Suministros".'), findsOneWidget);
      await tocar(tester, find.text('Guardar'));
      expect(repositorio.edicion?.$5, 'g2');
    });
  });

  group('borrar grupo', () {
    testWidgets('solo los grupos sin técnicos se pueden borrar', (tester) async {
      await montarPantalla(tester, const PantallaGrupos(), sesion: perfilAdministrador);

      // tres grupos, uno solo vacío
      expect(find.widgetWithText(TextButton, 'Borrar'), findsOneWidget);
    });

    testWidgets('borra un grupo vacío al confirmar', (tester) async {
      final repositorio = RepositorioGruposFalso();
      await montarPantalla(tester, const PantallaGrupos(), sesion: perfilAdministrador, grupos: repositorio);

      await tocar(tester, find.widgetWithText(TextButton, 'Borrar'));
      await tocar(tester, find.widgetWithText(FilledButton, 'Borrar'));

      expect(repositorio.idEliminado, 'g3');
      expect(find.text('Grupo borrado'), findsOneWidget);
    });

    testWidgets('no borra nada si se cancela', (tester) async {
      final repositorio = RepositorioGruposFalso();
      await montarPantalla(tester, const PantallaGrupos(), sesion: perfilAdministrador, grupos: repositorio);

      await tocar(tester, find.widgetWithText(TextButton, 'Borrar'));
      await tocar(tester, find.text('Cancelar'));

      expect(repositorio.idEliminado, isNull);
    });
  });
}
