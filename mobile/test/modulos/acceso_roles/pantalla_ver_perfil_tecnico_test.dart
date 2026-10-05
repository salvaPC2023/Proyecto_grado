import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/presentacion/pantallas/tecnicos/pantalla_ver_perfil_tecnico.dart';

import '../../compartido/app_de_prueba.dart';
import 'repositorios_falsos.dart';

PantallaVerPerfilTecnico perfilDeLuis({required bool activo}) => PantallaVerPerfilTecnico(
      id: 't1',
      nombreCompleto: 'Luis Quispe Mamani',
      nombreUsuario: 'lquispe',
      grupo: 'Grupo 1',
      profesion: 'electrico',
      activo: activo,
    );

void main() {
  testWidgets('muestra los datos del técnico', (tester) async {
    await montarPantalla(tester, perfilDeLuis(activo: true), sesion: perfilSupervisor);

    expect(find.text('Luis'), findsOneWidget);
    expect(find.text('Mamani'), findsOneWidget);
    expect(find.text('@lquispe'), findsOneWidget);
    expect(find.text('Activo'), findsOneWidget);
  });

  testWidgets('deshabilita la cuenta al confirmar', (tester) async {
    final repositorio = RepositorioTecnicosFalso();
    await montarPantalla(tester, perfilDeLuis(activo: true),
        sesion: perfilSupervisor, tecnicos: repositorio);

    await tocar(tester, find.text('Deshabilitar cuenta'));
    await tocar(tester, find.text('Deshabilitar'));

    expect(repositorio.idCambiado, 't1');
    expect(find.text('Cuenta deshabilitada'), findsOneWidget);
    expect(find.text('Inactivo'), findsOneWidget);
  });

  testWidgets('no cambia nada si se cancela', (tester) async {
    final repositorio = RepositorioTecnicosFalso();
    await montarPantalla(tester, perfilDeLuis(activo: false),
        sesion: perfilSupervisor, tecnicos: repositorio);

    await tocar(tester, find.text('Habilitar cuenta'));
    await tocar(tester, find.text('Cancelar'));

    expect(repositorio.idCambiado, isNull);
  });
}
