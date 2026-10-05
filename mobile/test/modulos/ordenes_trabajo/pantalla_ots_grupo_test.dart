import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/presentacion/pantallas/ordenes_trabajo/pantalla_ots_grupo.dart';

import '../../compartido/app_de_prueba.dart';
import '../acceso_roles/repositorios_falsos.dart';
import 'repositorios_falsos.dart';

void main() {
  final ots = [
    crearOt(id: 'ot1', titulo: 'Revisar transformador', tecnicoId: 't1'),
    crearOt(id: 'ot2', titulo: 'Cambiar motor', tecnicoId: 't2'),
  ];

  testWidgets('muestra las OTs de todo el grupo', (tester) async {
    await montarPantalla(tester, const PantallaOtsGrupo(),
        sesion: perfilSupervisor, ordenes: RepositorioOrdenesTrabajoFalso(ots: ots));

    expect(find.text('Revisar transformador'), findsOneWidget);
    expect(find.text('Cambiar motor'), findsOneWidget);
  });

  testWidgets('avisa si el grupo no tiene OTs', (tester) async {
    await montarPantalla(tester, const PantallaOtsGrupo(),
        sesion: perfilSupervisor, ordenes: RepositorioOrdenesTrabajoFalso(ots: []));

    expect(find.text('Tu grupo no tiene órdenes de trabajo para este día'), findsOneWidget);
  });

  testWidgets('muestra el error del servidor', (tester) async {
    await montarPantalla(tester, const PantallaOtsGrupo(),
        sesion: perfilSupervisor,
        ordenes: RepositorioOrdenesTrabajoFalso(error: const ErrorDeAplicacion('Sin conexión')));

    expect(find.text('Sin conexión'), findsOneWidget);
  });

  testWidgets('al tocar una OT abre su detalle', (tester) async {
    await montarPantalla(tester, const PantallaOtsGrupo(),
        sesion: perfilSupervisor, ordenes: RepositorioOrdenesTrabajoFalso(ots: ots));

    await tocar(tester, find.text('Cambiar motor'));

    expect(find.text('Detalle de OT'), findsOneWidget);
  });
}
