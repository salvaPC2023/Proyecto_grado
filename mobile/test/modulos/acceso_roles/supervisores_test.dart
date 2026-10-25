import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/datos/remoto/repositorio_grupos_remoto.dart';
import 'package:maintenance_app/datos/remoto/repositorio_supervisores_remoto.dart';
import 'package:maintenance_app/presentacion/viewmodels/supervisores_vm.dart';

import '../../compartido/app_de_prueba.dart';
import '../../compartido/dio_falso.dart';
import 'repositorios_falsos.dart';

// Asi responde el backend
const supervisorJson = {
  'id': 's1',
  'usuario_id': 'u1',
  'nombre': 'Ana',
  'apellido_paterno': 'Rojas',
  'apellido_materno': null,
  'nombre_usuario': 'ana',
  'activo': true,
  'horario_entrada': '07:00:00',
  'horario_salida': '15:00:00',
  'area_designada': null,
  'grupo_nombre': 'Grupo Suministros',
};

void main() {
  group('repositorio remoto', () {
    test('lista los supervisores', () async {
      final adaptador = AdaptadorHttpFalso((_) => [supervisorJson]);
      final repositorio = RepositorioSupervisoresRemoto(crearDioFalso(adaptador));

      final supervisores = await repositorio.listar();

      expect(adaptador.ultima.path, '/supervisores');
      expect(supervisores.single.horario, '07:00 - 15:00');
    });

    test('crea un supervisor con su grupo y turno', () async {
      final adaptador = AdaptadorHttpFalso((_) => supervisorJson);
      final repositorio = RepositorioSupervisoresRemoto(crearDioFalso(adaptador));

      await repositorio.crear(
        nombre: 'Ana',
        apellidoPaterno: 'Rojas',
        nombreDeGrupo: 'Grupo Suministros',
        horarioEntrada: '07:00',
        horarioSalida: '15:00',
      );

      expect(adaptador.ultima.method, 'POST');
      expect(adaptador.ultima.data['nombre_de_grupo'], 'Grupo Suministros');
    });

    test('cambia el estado de un supervisor', () async {
      final adaptador = AdaptadorHttpFalso((_) => null);
      final repositorio = RepositorioSupervisoresRemoto(crearDioFalso(adaptador));

      await repositorio.cambiarEstado('s1', false);

      expect(adaptador.ultima.path, '/supervisores/s1/estado');
      expect(adaptador.ultima.data, {'activo': false});
    });

    test('edita turno y área sin enviar el grupo si no cambia', () async {
      final adaptador = AdaptadorHttpFalso((_) => {...supervisorJson, 'grupo_id': 'g1', 'area_designada': 'Procesos'});
      final repositorio = RepositorioSupervisoresRemoto(crearDioFalso(adaptador));

      final editado = await repositorio.editar(
        supervisorId: 's1',
        horarioEntrada: '23:00',
        horarioSalida: '07:00',
        areaDesignada: 'Procesos',
      );

      expect(adaptador.ultima.method, 'PATCH');
      expect(adaptador.ultima.path, '/supervisores/s1');
      expect(adaptador.ultima.data, {'horario_entrada': '23:00', 'horario_salida': '07:00', 'area_designada': 'Procesos'});
      expect(editado.grupoId, 'g1');
      expect(editado.areaDesignada, 'Procesos');
    });

    test('al cambiar de grupo envía el grupo nuevo', () async {
      final adaptador = AdaptadorHttpFalso((_) => supervisorJson);
      final repositorio = RepositorioSupervisoresRemoto(crearDioFalso(adaptador));

      await repositorio.editar(supervisorId: 's1', horarioEntrada: '07:00', horarioSalida: '15:00', grupoId: 'g2');

      expect(adaptador.ultima.data['grupo_id'], 'g2');
    });
  });

  test('borrar un grupo llama a DELETE /grupos/{id}', () async {
    final adaptador = AdaptadorHttpFalso((_) => null);
    final repositorio = RepositorioGruposRemoto(crearDioFalso(adaptador));

    await repositorio.eliminar('g3');

    expect(adaptador.ultima.method, 'DELETE');
    expect(adaptador.ultima.path, '/grupos/g3');
  });

  group('viewmodel', () {
    test('carga la lista de supervisores', () async {
      final contenedor = crearContenedor(sesion: perfilAdministrador);

      final supervisores = await contenedor.read(supervisoresViewModelProvider.future);

      expect(supervisores, hasLength(2));
    });

    test('cambiar el estado lo envía al repositorio', () async {
      final repositorio = RepositorioSupervisoresFalso();
      final contenedor = crearContenedor(sesion: perfilAdministrador, supervisores: repositorio);
      await contenedor.read(supervisoresViewModelProvider.future);

      await contenedor.read(supervisoresViewModelProvider.notifier).cambiarEstado('s2', true);

      expect(repositorio.idCambiado, 's2');
    });
  });
}
