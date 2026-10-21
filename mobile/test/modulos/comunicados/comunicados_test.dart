import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/presentacion/pantallas/inicio/pantalla_inicio.dart';

import '../../compartido/app_de_prueba.dart';
import '../acceso_roles/repositorios_falsos.dart';
import 'repositorios_falsos.dart';

final general = crearComunicado();
final personal = crearComunicado(
  id: 'c2',
  titulo: 'Apoya a tus compañeros',
  texto: 'Cuando termines tus OT, ayuda en la llenadora',
  personal: true,
  destinatario: 'Luis Quispe Mamani',
);

Future<RepositorioComunicadosFalso> _inicio(WidgetTester tester, {required bool supervisor, RepositorioComunicadosFalso? repositorio}) async {
  final comunicados = repositorio ?? RepositorioComunicadosFalso(comunicados: [general, personal]);
  await montarPantalla(tester, const PantallaInicio(), sesion: supervisor ? perfilSupervisor : perfilTecnico, comunicados: comunicados);
  return comunicados;
}

Future<void> _abrirNuevo(WidgetTester tester, {required bool personal}) async {
  // el primer + es el del tablón (general); el segundo, el de comunicados personales
  await tocar(tester, find.text('+').at(personal ? 1 : 0));
}

Future<void> _publicar(WidgetTester tester) async {
  await tocar(tester, find.text('Publicar'));
}

void main() {
  group('lo que ve el técnico', () {
    testWidgets('el general en el tablón y el personal en su sección', (tester) async {
      await _inicio(tester, supervisor: false);

      expect(find.text('Uso obligatorio de EPP'), findsOneWidget);
      expect(find.text('Apoya a tus compañeros'), findsOneWidget);
      expect(find.text('De Ana Rojas'), findsOneWidget);
    });

    testWidgets('no puede redactar comunicados', (tester) async {
      await _inicio(tester, supervisor: false);

      expect(find.text('+'), findsNothing);
    });

    testWidgets('sin comunicados lo indica en cada sección', (tester) async {
      await _inicio(tester, supervisor: false, repositorio: RepositorioComunicadosFalso());

      expect(find.text('No hay anuncios vigentes.'), findsOneWidget);
      expect(find.text('No tienes comunicados personales.'), findsOneWidget);
    });

    testWidgets('al tocar un comunicado ve el texto completo, sin la opción de retirarlo', (tester) async {
      await _inicio(tester, supervisor: false);

      await tocar(tester, find.text('Uso obligatorio de EPP'));

      expect(find.text('Casco y guantes en subestaciones'), findsOneWidget);
      expect(find.text('Retirar comunicado'), findsNothing);
    });

    testWidgets('si falla la carga puede reintentar', (tester) async {
      await _inicio(tester, supervisor: false, repositorio: RepositorioComunicadosFalso(error: const ErrorDeAplicacion('Sin conexión')));

      expect(find.text('Sin conexión'), findsNWidgets(2));
      expect(find.text('Reintentar'), findsNWidgets(2));
    });
  });

  group('lo que hace el supervisor', () {
    testWidgets('ve a quién envió cada comunicado personal', (tester) async {
      await _inicio(tester, supervisor: true);

      expect(find.text('Para Luis Quispe Mamani'), findsOneWidget);
      expect(find.text('+'), findsNWidgets(2));
    });

    testWidgets('publica un comunicado para todo el grupo', (tester) async {
      final repositorio = await _inicio(tester, supervisor: true, repositorio: RepositorioComunicadosFalso());

      await _abrirNuevo(tester, personal: false);
      await tester.enterText(find.widgetWithText(TextField, 'Ej. Uso obligatorio de EPP'), 'Corte de agua');
      await tester.enterText(find.widgetWithText(TextField, 'Escribe el comunicado'), 'Mañana de 8 a 10');
      await tocar(tester, find.text('Mantenimiento'));
      await _publicar(tester);

      expect(repositorio.publicado!.titulo, 'Corte de agua');
      expect(repositorio.publicado!.tecnicoId, isNull);
      expect(find.text('Comunicado publicado'), findsOneWidget);
      expect(find.text('Corte de agua'), findsOneWidget); // ya aparece en el tablón
    });

    testWidgets('un comunicado personal exige elegir al técnico', (tester) async {
      final repositorio = await _inicio(tester, supervisor: true, repositorio: RepositorioComunicadosFalso());

      await _abrirNuevo(tester, personal: true);
      await tester.enterText(find.widgetWithText(TextField, 'Ej. Uso obligatorio de EPP'), 'Felicitaciones');
      await tester.enterText(find.widgetWithText(TextField, 'Escribe el comunicado'), 'Buen trabajo');
      await _publicar(tester);

      expect(find.text('Elige el técnico'), findsOneWidget);
      expect(repositorio.publicado, isNull);
    });

    testWidgets('publica un comunicado personal para el técnico elegido', (tester) async {
      final repositorio = await _inicio(tester, supervisor: true, repositorio: RepositorioComunicadosFalso());

      await _abrirNuevo(tester, personal: true);
      await tocar(tester, find.text('Elige un técnico'));
      await tocar(tester, find.text('Luis Quispe Mamani').last);
      await tester.enterText(find.widgetWithText(TextField, 'Ej. Uso obligatorio de EPP'), 'Felicitaciones');
      await tester.enterText(find.widgetWithText(TextField, 'Escribe el comunicado'), 'Buen trabajo');
      await _publicar(tester);

      expect(repositorio.publicado!.tecnicoId, tecnicoLuis.id);
    });

    testWidgets('sin texto ni imagen no se publica', (tester) async {
      final repositorio = await _inicio(tester, supervisor: true, repositorio: RepositorioComunicadosFalso());

      await _abrirNuevo(tester, personal: false);
      await tester.enterText(find.widgetWithText(TextField, 'Ej. Uso obligatorio de EPP'), 'Solo título');
      await _publicar(tester);

      expect(find.text('Escribe un texto o adjunta una imagen'), findsOneWidget);
      expect(repositorio.publicado, isNull);
    });

    testWidgets('muestra el error del servidor al publicar', (tester) async {
      await _inicio(
        tester,
        supervisor: true,
        repositorio: RepositorioComunicadosFalso(errorAlPublicar: const ErrorDeAplicacion('El técnico no es de tu grupo')),
      );

      await _abrirNuevo(tester, personal: false);
      await tester.enterText(find.widgetWithText(TextField, 'Ej. Uso obligatorio de EPP'), 'Aviso');
      await tester.enterText(find.widgetWithText(TextField, 'Escribe el comunicado'), 'Texto');
      await _publicar(tester);

      expect(find.text('El técnico no es de tu grupo'), findsOneWidget);
      expect(find.text('Publicar'), findsOneWidget); // sigue en el formulario
    });

    testWidgets('retira un comunicado después de confirmar', (tester) async {
      final repositorio = await _inicio(tester, supervisor: true);

      await tocar(tester, find.text('Uso obligatorio de EPP'));
      await tocar(tester, find.text('Retirar comunicado'));
      await tocar(tester, find.widgetWithText(FilledButton, 'Retirar'));

      expect(repositorio.retirado, 'c1');
      expect(find.text('Comunicado retirado'), findsOneWidget);
      expect(find.text('Uso obligatorio de EPP'), findsNothing);
    });
  });
}
