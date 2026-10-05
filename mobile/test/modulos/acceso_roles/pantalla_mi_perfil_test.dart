import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/presentacion/pantallas/perfil/pantalla_mi_perfil.dart';

import '../../compartido/app_de_prueba.dart';
import 'repositorios_falsos.dart';

void main() {
  testWidgets('el técnico ve su grupo y su profesión', (tester) async {
    await montarPantalla(tester, const PantallaMiPerfil(),
        sesion: perfilTecnico, perfil: RepositorioPerfilFalso(perfil: perfilTecnico));

    expect(find.text('@lquispe'), findsOneWidget);
    expect(find.text('Grupo 1'), findsOneWidget);
    expect(find.text('electrico'), findsOneWidget);
  });

  testWidgets('el supervisor ve su horario', (tester) async {
    await montarPantalla(tester, const PantallaMiPerfil(), sesion: perfilSupervisor);

    expect(find.text('08:00 - 17:00'), findsOneWidget);
  });

  testWidgets('guarda los cambios del nombre', (tester) async {
    final repositorio = RepositorioPerfilFalso();
    await montarPantalla(tester, const PantallaMiPerfil(), sesion: perfilSupervisor, perfil: repositorio);

    await tester.enterText(find.byType(TextField).first, 'Ana María');
    await tocar(tester, find.text('Guardar Cambios'));

    expect(repositorio.nombreGuardado, 'Ana María');
    expect(find.text('Perfil actualizado'), findsOneWidget);
  });

  testWidgets('cambia la contraseña', (tester) async {
    final repositorio = RepositorioPerfilFalso();
    await montarPantalla(tester, const PantallaMiPerfil(), sesion: perfilSupervisor, perfil: repositorio);

    await tester.enterText(find.widgetWithText(TextField, '••••••••'), 'mivieja123');
    await tester.enterText(find.widgetWithText(TextField, 'Ingresa nueva contraseña'), 'nueva123');
    await tocar(tester, find.byIcon(Icons.visibility_outlined)); // mostrar contraseña
    await tocar(tester, find.text('Guardar Cambios'));

    expect(repositorio.passwordNuevaGuardada, 'nueva123');
  });

  testWidgets('pide las dos contraseñas para cambiarla', (tester) async {
    await montarPantalla(tester, const PantallaMiPerfil(), sesion: perfilSupervisor);

    await tester.enterText(find.widgetWithText(TextField, '••••••••'), 'mivieja123');
    await tocar(tester, find.text('Guardar Cambios'));

    expect(find.text('Completa las dos contraseñas para cambiarla, o ninguna'), findsOneWidget);
  });

  testWidgets('muestra el error si no puede cargar el perfil', (tester) async {
    await montarPantalla(tester, const PantallaMiPerfil(),
        sesion: perfilSupervisor,
        perfil: RepositorioPerfilFalso(error: const ErrorDeAplicacion('Sin conexión')));

    expect(find.text('Sin conexión'), findsOneWidget);
  });
}
