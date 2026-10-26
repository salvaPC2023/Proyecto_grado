import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/presentacion/pantallas/ordenes_trabajo/pantalla_nueva_ot.dart';

import '../../compartido/app_de_prueba.dart';
import '../acceso_roles/repositorios_falsos.dart';
import 'repositorios_falsos.dart';

final campoTitulo = find.widgetWithText(TextField, 'Título (ej. Sobrecalentamiento de transformador)');

Future<void> agregarPaso(WidgetTester tester, {required String descripcion, String? horas}) async {
  await tocar(tester, find.text('Agregar paso de mantenimiento'));
  if (horas == null) await tocar(tester, find.text('PMNN'));
  await tester.enterText(find.widgetWithText(TextField, 'Descripción'), descripcion);
  if (horas != null) {
    await tester.enterText(find.widgetWithText(TextField, 'Horas planificadas'), horas);
  }
  await tocar(tester, find.text('Agregar'));
}

void main() {
  testWidgets('pide el título', (tester) async {
    await montarPantalla(tester, const PantallaNuevaOt(), sesion: perfilSupervisor);

    await tocar(tester, find.text('Crear Orden de Trabajo'));

    expect(find.text('Escribe el título de la orden'), findsOneWidget);
    expect(find.text('Descripción del trabajo'), findsNothing); // la OT ya no lleva descripción general
  });

  testWidgets('pide la ubicación técnica', (tester) async {
    await montarPantalla(tester, const PantallaNuevaOt(), sesion: perfilSupervisor);
    await tester.enterText(campoTitulo, 'Cambiar filtro');

    await tocar(tester, find.text('Crear Orden de Trabajo'));

    expect(find.text('Selecciona una ubicación técnica'), findsOneWidget);
  });

  testWidgets('crea la OT cuando todos los datos están completos', (tester) async {
    final repositorio = RepositorioOrdenesTrabajoFalso();
    await montarPantalla(tester, const PantallaNuevaOt(), sesion: perfilSupervisor, ordenes: repositorio);

    await tester.enterText(campoTitulo, 'Cambiar filtro');
    await tocar(tester, find.text('Toca para elegir entre 2 ubicaciones'));
    await tocar(tester, find.text('TR-01'));
    await tocar(tester, find.byType(DropdownButton<String?>).last); // desplegable de técnicos
    await tocar(tester, find.text('Luis Quispe Mamani (Eléctrico)').last);
    await agregarPaso(tester, descripcion: 'Revisar aceite', horas: '2');
    await tocar(tester, find.text('Crear Orden de Trabajo'));

    expect(repositorio.tituloCreado, 'Cambiar filtro');
    expect(find.text('Pantalla base'), findsOneWidget);
  });

  testWidgets('el paso PM01 necesita descripción y horas', (tester) async {
    await montarPantalla(tester, const PantallaNuevaOt(), sesion: perfilSupervisor);

    await tocar(tester, find.text('Agregar paso de mantenimiento'));
    await tocar(tester, find.text('Agregar'));
    expect(find.text('Escribe la descripción del paso'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Descripción'), 'Revisar aceite');
    await tocar(tester, find.text('Agregar'));
    expect(find.text('Los pasos PM01 requieren horas mayores a 0'), findsOneWidget);
  });
}
