import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/modelos/orden_trabajo.dart';
import 'package:maintenance_app/nucleo/sesion.dart';
import 'package:maintenance_app/presentacion/pantallas/inicio/pantalla_inicio.dart';
import 'package:maintenance_app/presentacion/pantallas/supervisores/pantalla_lista_supervisores.dart';

import '../modulos/acceso_roles/repositorios_falsos.dart';
import '../modulos/ordenes_trabajo/repositorios_falsos.dart';
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

    testWidgets('el administrador no tiene inicio: ve sus secciones de gestión', (tester) async {
      // el administrador entra directo a Supervisores, no a la pantalla de inicio
      await montarPantalla(tester, const PantallaListaSupervisores(), sesion: perfilAdministrador);

      expect(find.byIcon(Icons.home_rounded), findsNothing);
      expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
      expect(find.byIcon(Icons.manage_accounts_outlined), findsOneWidget);
      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
      expect(find.text('Ana Rojas'), findsOneWidget);
    });
  });

  group('tarjeta de progreso con las OTs de hoy', () {
    testWidgets('muestra el avance real de los pasos PM01', (tester) async {
      // la OT de ejemplo tiene un solo paso PM01, todavía sin cerrar
      await montarPantalla(tester, const PantallaInicio(), sesion: perfilTecnico);

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Te queda 1 paso por cerrar'), findsOneWidget);
    });

    testWidgets('con todos los pasos cerrados la jornada está completa', (tester) async {
      final cerrada = crearOt(pasos: [
        PasoOt(
          id: 'p2',
          numeroPaso: 2,
          descripcion: 'Cambiar filtro',
          claveControl: 'PM01',
          horasPlanificadas: 2,
          cierre: CierrePaso(
            id: 'c1',
            fechaHoraNotificacion: DateTime(2026, 10, 5, 10),
            tiempoRealTrabajado: 2,
            trabajoFinalizado: true,
            sinTrabajoRealizado: false,
            resultadoTrabajo: 'ejecutado',
            descripcionTrabajoRealizado: 'Se cambió el filtro',
          ),
        ),
      ]);
      await montarPantalla(tester, const PantallaInicio(),
          sesion: perfilTecnico, ordenes: RepositorioOrdenesTrabajoFalso(ots: [cerrada]));

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('¡Completaste tu jornada!'), findsOneWidget);
    });

    testWidgets('sin OTs para hoy lo indica', (tester) async {
      await montarPantalla(tester, const PantallaInicio(),
          sesion: perfilTecnico, ordenes: RepositorioOrdenesTrabajoFalso(ots: []));

      expect(find.text('No tienes órdenes para hoy'), findsOneWidget);
    });
  });
}
