import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/presentacion/viewmodels/perfil_vm.dart';
import 'package:maintenance_app/presentacion/viewmodels/tecnicos_vm.dart';

import '../../compartido/app_de_prueba.dart';
import 'repositorios_falsos.dart';

void main() {
  test('el perfil se carga desde el repositorio', () async {
    final contenedor = crearContenedor(sesion: perfilSupervisor);

    final perfil = await contenedor.read(perfilViewModelProvider.future);

    expect(perfil.nombreUsuario, 'ana');
  });

  test('guardar cambios envía el nuevo nombre', () async {
    final repositorio = RepositorioPerfilFalso();
    final contenedor = crearContenedor(sesion: perfilSupervisor, perfil: repositorio);
    await contenedor.read(perfilViewModelProvider.future);

    await contenedor
        .read(perfilViewModelProvider.notifier)
        .guardarCambios(nombre: 'Ana María', apellidoPaterno: 'Rojas');

    expect(repositorio.nombreGuardado, 'Ana María');
  });

  test('la lista de técnicos se carga desde el repositorio', () async {
    final contenedor = crearContenedor(sesion: perfilSupervisor);

    final tecnicos = await contenedor.read(tecnicosViewModelProvider.future);

    expect(tecnicos, hasLength(3));
  });

  test('crear un técnico lo envía al repositorio', () async {
    final repositorio = RepositorioTecnicosFalso();
    final contenedor = crearContenedor(sesion: perfilSupervisor, tecnicos: repositorio);
    await contenedor.read(tecnicosViewModelProvider.future);

    await contenedor.read(tecnicosViewModelProvider.notifier).crear(
          nombre: 'Carlos',
          apellidoPaterno: 'Mendoza',
          nombreUsuario: 'cmendoza',
          profesion: 'electrico',
        );

    expect(repositorio.usuarioCreado, 'cmendoza');
  });
}
