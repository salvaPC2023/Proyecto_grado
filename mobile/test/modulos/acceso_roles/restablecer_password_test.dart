import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/presentacion/pantallas/grupos/pantalla_grupos.dart';
import 'package:maintenance_app/presentacion/pantallas/supervisores/pantalla_lista_supervisores.dart';

import '../../compartido/app_de_prueba.dart';
import 'repositorios_falsos.dart';

// Prueba con usuarios del 23/10/2026: si un técnico o supervisor olvida su contraseña,
// el administrador la devuelve a la inicial y le entrega sus datos de acceso
void main() {
  group('supervisor', () {
    testWidgets('restablece al confirmar y muestra los datos de acceso', (tester) async {
      final repositorio = RepositorioSupervisoresFalso();
      await montarPantalla(tester, const PantallaListaSupervisores(), sesion: perfilAdministrador, supervisores: repositorio);

      await tocar(tester, find.widgetWithText(TextButton, 'Restablecer contraseña').first); // Ana
      await tocar(tester, find.widgetWithText(FilledButton, 'Restablecer'));

      expect(repositorio.idRestablecido, 's1');
      expect(find.text('Contraseña restablecida'), findsOneWidget);
      expect(find.text('ana'), findsOneWidget);
      expect(find.text('ESPODI2026'), findsOneWidget);
    });

    testWidgets('no restablece nada si se cancela', (tester) async {
      final repositorio = RepositorioSupervisoresFalso();
      await montarPantalla(tester, const PantallaListaSupervisores(), sesion: perfilAdministrador, supervisores: repositorio);

      await tocar(tester, find.widgetWithText(TextButton, 'Restablecer contraseña').first);
      await tocar(tester, find.text('Cancelar'));

      expect(repositorio.idRestablecido, isNull);
    });
  });

  group('técnico', () {
    testWidgets('los grupos con técnicos permiten verlos en lugar de borrarlos', (tester) async {
      await montarPantalla(tester, const PantallaGrupos(), sesion: perfilAdministrador);

      // dos grupos con técnicos y uno vacío
      expect(find.widgetWithText(TextButton, 'Técnicos'), findsNWidgets(2));
    });

    testWidgets('restablece a un técnico desde su grupo', (tester) async {
      final repositorio = RepositorioGruposFalso();
      await montarPantalla(tester, const PantallaGrupos(), sesion: perfilAdministrador, grupos: repositorio);

      await tocar(tester, find.widgetWithText(TextButton, 'Técnicos').first); // Grupo Suministros
      expect(find.text('Técnicos de Grupo Suministros'), findsOneWidget);
      await tocar(tester, find.widgetWithText(TextButton, 'Restablecer'));
      await tocar(tester, find.widgetWithText(FilledButton, 'Restablecer'));

      expect(repositorio.tecnicoRestablecido, 't1');
      expect(find.text('Contraseña restablecida'), findsOneWidget);
      expect(find.text(tecnicoLuis.nombreUsuario), findsWidgets);
    });
  });
}
