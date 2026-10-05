import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/nucleo/fechas.dart';
import 'package:maintenance_app/presentacion/pantallas/ordenes_trabajo/pantalla_mis_ots.dart';

import '../../compartido/app_de_prueba.dart';
import '../acceso_roles/repositorios_falsos.dart';
import 'repositorios_falsos.dart';

void main() {
  final ots = [
    crearOt(id: 'ot1', titulo: 'Revisar transformador', estatus: 'asignada'),
    crearOt(id: 'ot2', titulo: 'Cambiar motor', estatus: 'cerrada'),
  ];

  testWidgets('muestra las OTs del día', (tester) async {
    await montarPantalla(tester, const PantallaMisOts(),
        sesion: perfilTecnico, ordenes: RepositorioOrdenesTrabajoFalso(ots: ots));

    expect(find.text('Revisar transformador'), findsOneWidget);
    expect(find.text('Cambiar motor'), findsOneWidget);
  });

  testWidgets('avisa si no hay OTs en el día', (tester) async {
    await montarPantalla(tester, const PantallaMisOts(),
        sesion: perfilTecnico, ordenes: RepositorioOrdenesTrabajoFalso(ots: []));

    expect(find.text('No tienes órdenes de trabajo para este día'), findsOneWidget);
  });

  testWidgets('muestra el error del servidor', (tester) async {
    await montarPantalla(tester, const PantallaMisOts(),
        sesion: perfilTecnico,
        ordenes: RepositorioOrdenesTrabajoFalso(error: const ErrorDeAplicacion('Sin conexión')));

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('al elegir otro día consulta esa fecha', (tester) async {
    final repositorio = RepositorioOrdenesTrabajoFalso(ots: ots);
    await montarPantalla(tester, const PantallaMisOts(), sesion: perfilTecnico, ordenes: repositorio);
    final ayer = hoySinHora().subtract(const Duration(days: 1));

    await tocar(tester, find.text('${ayer.day}'));

    expect(repositorio.fechaConsultada, ayer);
  });

  testWidgets('al tocar una OT abre su detalle', (tester) async {
    await montarPantalla(tester, const PantallaMisOts(),
        sesion: perfilTecnico, ordenes: RepositorioOrdenesTrabajoFalso(ots: ots));

    await tocar(tester, find.text('Revisar transformador'));

    expect(find.text('Detalle de OT'), findsOneWidget);
  });
}
