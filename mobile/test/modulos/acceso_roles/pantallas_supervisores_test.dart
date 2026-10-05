import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/presentacion/pantallas/supervisores/pantalla_lista_supervisores.dart';
import 'package:maintenance_app/presentacion/pantallas/supervisores/pantalla_registrar_supervisor.dart';

import '../../compartido/app_de_prueba.dart';
import 'repositorios_falsos.dart';

void main() {
  group('lista de supervisores', () {
    testWidgets('muestra cada supervisor con su grupo y horario', (tester) async {
      await montarPantalla(tester, const PantallaListaSupervisores(), sesion: perfilAdministrador);

      expect(find.text('Ana Rojas'), findsOneWidget);
      expect(find.text('Grupo Suministros · 07:00 - 15:00'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('deshabilita un supervisor al confirmar', (tester) async {
      final repositorio = RepositorioSupervisoresFalso();
      await montarPantalla(tester, const PantallaListaSupervisores(), sesion: perfilAdministrador, supervisores: repositorio);

      await tocar(tester, find.widgetWithText(TextButton, 'Deshabilitar'));
      await tocar(tester, find.widgetWithText(FilledButton, 'Deshabilitar'));

      expect(repositorio.idCambiado, 's1');
      expect(find.text('Cuenta deshabilitada'), findsOneWidget);
    });

    testWidgets('no cambia nada si se cancela', (tester) async {
      final repositorio = RepositorioSupervisoresFalso();
      await montarPantalla(tester, const PantallaListaSupervisores(), sesion: perfilAdministrador, supervisores: repositorio);

      await tocar(tester, find.widgetWithText(TextButton, 'Habilitar'));
      await tocar(tester, find.text('Cancelar'));

      expect(repositorio.idCambiado, isNull);
    });

    testWidgets('avisa si no hay supervisores', (tester) async {
      await montarPantalla(tester, const PantallaListaSupervisores(),
          sesion: perfilAdministrador, supervisores: RepositorioSupervisoresFalso(supervisores: []));

      expect(find.text('No hay supervisores registrados'), findsOneWidget);
    });

    testWidgets('muestra el error del servidor', (tester) async {
      await montarPantalla(tester, const PantallaListaSupervisores(),
          sesion: perfilAdministrador,
          supervisores: RepositorioSupervisoresFalso(error: const ErrorDeAplicacion('Sin conexión')));

      expect(find.text('Sin conexión'), findsOneWidget);
    });

    testWidgets('abre el registro de supervisores', (tester) async {
      await montarPantalla(tester, const PantallaListaSupervisores(), sesion: perfilAdministrador);

      await tocar(tester, find.byTooltip('Registrar supervisor'));

      expect(find.text('Registrar Supervisor'), findsOneWidget);
    });
  });

  group('registro de supervisor', () {
    testWidgets('pide los campos obligatorios', (tester) async {
      await montarPantalla(tester, const PantallaRegistrarSupervisor(), sesion: perfilAdministrador);

      await tocar(tester, find.text('Guardar Supervisor'));

      expect(find.text('Completa los campos obligatorios'), findsOneWidget);
    });

    testWidgets('guarda el supervisor con el turno elegido', (tester) async {
      final repositorio = RepositorioSupervisoresFalso();
      await montarPantalla(tester, const PantallaRegistrarSupervisor(), sesion: perfilAdministrador, supervisores: repositorio);

      await tester.enterText(find.widgetWithText(TextField, 'Ej. Ana'), 'Luis');
      await tester.enterText(find.widgetWithText(TextField, 'Ej. Rojas'), 'Perez');
      await tester.enterText(find.widgetWithText(TextField, 'arojas_sup'), 'lperez');
      await tester.enterText(find.widgetWithText(TextField, 'Ej. Grupo Suministros'), 'Grupo Taller');
      await tocar(tester, find.text('Turno 2 (07:00 - 15:00)'));
      await tocar(tester, find.text('Turno 1 (23:00 - 07:00)').last);
      await tocar(tester, find.text('Guardar Supervisor'));

      expect(repositorio.usuarioCreado, 'lperez');
      expect(repositorio.horarioEntradaCreado, '23:00');
      expect(find.text('Supervisor registrado'), findsOneWidget);
    });
  });
}
