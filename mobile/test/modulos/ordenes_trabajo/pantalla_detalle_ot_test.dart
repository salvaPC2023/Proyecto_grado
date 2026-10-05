import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/dominio/modelos/orden_trabajo.dart';
import 'package:maintenance_app/presentacion/pantallas/ordenes_trabajo/pantalla_detalle_ot.dart';

import '../../compartido/app_de_prueba.dart';
import '../acceso_roles/repositorios_falsos.dart';
import 'repositorios_falsos.dart';

void main() {
  testWidgets('muestra los datos y los pasos de la OT', (tester) async {
    await montarPantalla(tester, const PantallaDetalleOt(otId: 'ot1'), sesion: perfilTecnico);

    expect(find.text('Revisar transformador'), findsOneWidget);
    expect(find.text('Planta Norte / Subestación A / Transformadores / TR-01'), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);
    expect(find.text('1 paso PM01 pendiente'), findsOneWidget);
    expect(find.text('Informativo'), findsOneWidget);
  });

  testWidgets('el técnico ve el botón para registrar el cierre', (tester) async {
    await montarPantalla(tester, const PantallaDetalleOt(otId: 'ot1'), sesion: perfilTecnico);

    await tocar(tester, find.text('Registrar cierre'));

    expect(find.text('El registro de cierre aun no esta disponible'), findsOneWidget);
  });

  testWidgets('el supervisor no puede registrar cierres', (tester) async {
    await montarPantalla(tester, const PantallaDetalleOt(otId: 'ot1'), sesion: perfilSupervisor);

    expect(find.text('Registrar cierre'), findsNothing);
  });

  testWidgets('muestra el cierre de los pasos terminados', (tester) async {
    final otCerrada = crearOt(
      estatus: 'cerrada',
      fechaCierre: DateTime(2026, 10, 5, 12),
      pasos: [
        PasoOt(
          id: 'p1',
          numeroPaso: 1,
          descripcion: 'Cambiar filtro',
          claveControl: 'PM01',
          horasPlanificadas: 2,
          cierre: cierreEjecutado,
        ),
      ],
    );
    await montarPantalla(tester, const PantallaDetalleOt(otId: 'ot1'),
        sesion: perfilTecnico, ordenes: RepositorioOrdenesTrabajoFalso(ots: [otCerrada]));

    expect(find.text('Todos los pasos PM01 están cerrados'), findsOneWidget);
    expect(find.text('Se cambió el filtro'), findsOneWidget);
    expect(find.text('Cerrada el: '), findsOneWidget);
  });

  testWidgets('muestra el error del servidor', (tester) async {
    await montarPantalla(tester, const PantallaDetalleOt(otId: 'ot1'),
        sesion: perfilTecnico,
        ordenes: RepositorioOrdenesTrabajoFalso(error: const ErrorDeAplicacion('Sin conexión')));

    expect(find.text('Sin conexión'), findsOneWidget);
  });
}
