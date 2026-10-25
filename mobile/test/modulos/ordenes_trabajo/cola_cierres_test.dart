import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/dominio/modelos/cierre_pendiente.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_almacen_local.dart';
import 'package:maintenance_app/nucleo/sesion.dart';
import 'package:maintenance_app/presentacion/viewmodels/cola_cierres_vm.dart';
import 'package:maintenance_app/presentacion/viewmodels/ordenes_trabajo_vm.dart';

import '../../compartido/almacen_falso.dart';
import '../../compartido/app_de_prueba.dart';
import '../acceso_roles/repositorios_falsos.dart';
import 'repositorios_falsos.dart';

// perfilTecnico tiene el id 'u2'
CierrePendiente _pendiente(String id, {String usuarioId = 'u2', String? motivoRechazo}) => CierrePendiente(
      id: id,
      usuarioId: usuarioId,
      otId: 'ot1',
      pasoId: 'p2',
      ejecutado: true,
      tiempoRealTrabajado: 1.5,
      descripcion: 'Se cambió el filtro',
      fechaHora: DateTime(2026, 10, 5, 10, 30),
      descripcionPaso: 'Cambiar filtro',
      motivoRechazo: motivoRechazo,
    );

/// Token con la fecha de vencimiento indicada, con la misma forma que los del backend
String _token(DateTime vence) {
  String parte(Map<String, Object> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${parte({'alg': 'HS256'})}.${parte({'sub': 'u2', 'exp': vence.millisecondsSinceEpoch ~/ 1000})}.firma';
}

SesionGuardada _sesionGuardada(DateTime vence) => SesionGuardada(
      token: _token(vence),
      rol: 'tecnico',
      usuarioId: 'u2',
      nombreCompleto: 'Luis Quispe Mamani',
      nombreUsuario: 'lquispe',
    );

void main() {
  group('registrar un cierre', () {
    test('sin conexión queda en la cola del celular como pendiente de envío', () async {
      final cola = RepositorioColaCierresEnMemoria();
      final contenedor = crearContenedor(
        sesion: perfilTecnico,
        cola: cola,
        ordenes: RepositorioOrdenesTrabajoFalso(errorAlCerrar: const ErrorSinConexion()),
      );
      contenedor.listen(cierrePasoViewModelProvider, (_, _) {});

      final resultado = await contenedor.read(cierrePasoViewModelProvider.notifier).registrar(
            otId: 'ot1',
            pasoId: 'p2',
            ejecutado: true,
            tiempoRealTrabajado: 1.5,
            descripcion: 'Se cambió el filtro',
          );

      expect(resultado, ResultadoCierre.pendienteDeEnvio);
      expect(cola.cierres.single.pasoId, 'p2');
      expect(cola.cierres.single.usuarioId, 'u2');
    });

    test('un error del servidor no va a la cola: se muestra como antes', () async {
      final cola = RepositorioColaCierresEnMemoria();
      final contenedor = crearContenedor(
        sesion: perfilTecnico,
        cola: cola,
        ordenes: RepositorioOrdenesTrabajoFalso(errorAlCerrar: const ErrorDeAplicacion('El paso ya tiene un cierre registrado')),
      );
      contenedor.listen(cierrePasoViewModelProvider, (_, _) {});

      final resultado = await contenedor.read(cierrePasoViewModelProvider.notifier).registrar(
            otId: 'ot1', pasoId: 'p2', ejecutado: true, tiempoRealTrabajado: 1.5, descripcion: 'x');

      expect(resultado, ResultadoCierre.fallo);
      expect(cola.cierres, isEmpty);
    });
  });

  group('enviar la cola', () {
    test('al volver la señal envía el cierre con su id y su hora, y lo quita de la cola', () async {
      final cola = RepositorioColaCierresEnMemoria([_pendiente('c1')]);
      final repositorio = RepositorioOrdenesTrabajoFalso();
      final contenedor = crearContenedor(sesion: perfilTecnico, cola: cola, ordenes: repositorio);

      final enviados = await contenedor.read(colaCierresViewModelProvider.notifier).enviarPendientes();

      expect(enviados, 1);
      expect(repositorio.cierresRecibidos, ['c1']);
      expect(repositorio.horaDelCierre, DateTime(2026, 10, 5, 10, 30)); // la hora en que se cerró el paso
      expect(cola.cierres, isEmpty);
    });

    test('sin señal todavía, conserva el cierre y lo reintenta con el mismo id', () async {
      final cola = RepositorioColaCierresEnMemoria([_pendiente('c1')]);
      final repositorio = RepositorioOrdenesTrabajoFalso()..errorAlCerrarActual = const ErrorSinConexion();
      final contenedor = crearContenedor(sesion: perfilTecnico, cola: cola, ordenes: repositorio);
      final vm = contenedor.read(colaCierresViewModelProvider.notifier);

      expect(await vm.enviarPendientes(), 0);
      expect(cola.cierres.single.id, 'c1');

      repositorio.errorAlCerrarActual = null; // vuelve la señal
      expect(await vm.enviarPendientes(), 1);
      expect(repositorio.cierresRecibidos, ['c1']);
    });

    test('si el servidor lo rechaza, lo marca con el motivo y no lo reintenta', () async {
      final cola = RepositorioColaCierresEnMemoria([_pendiente('c1')]);
      final repositorio = RepositorioOrdenesTrabajoFalso()
        ..errorAlCerrarActual = const ErrorDeAplicacion('La orden de trabajo ya está cerrada');
      final contenedor = crearContenedor(sesion: perfilTecnico, cola: cola, ordenes: repositorio);
      final vm = contenedor.read(colaCierresViewModelProvider.notifier);

      await vm.enviarPendientes();
      repositorio.errorAlCerrarActual = null;
      await vm.enviarPendientes();

      expect(cola.cierres.single.motivoRechazo, 'La orden de trabajo ya está cerrada');
      expect(repositorio.cierresRecibidos, isEmpty);

      await vm.descartar('c1');
      expect(cola.cierres, isEmpty);
    });

    test('con la sesión vencida espera a que se vuelva a iniciar sesión', () async {
      final cola = RepositorioColaCierresEnMemoria([_pendiente('c1')]);
      final repositorio = RepositorioOrdenesTrabajoFalso()..errorAlCerrarActual = const ErrorSesionVencida('Token invalido o expirado');
      final contenedor = crearContenedor(sesion: perfilTecnico, cola: cola, ordenes: repositorio);

      await contenedor.read(colaCierresViewModelProvider.notifier).enviarPendientes();

      expect(cola.cierres.single.rechazado, isFalse); // no se pierde ni se marca como rechazado
    });

    test('solo envía los cierres de quien tiene la sesión', () async {
      final cola = RepositorioColaCierresEnMemoria([_pendiente('de-otro', usuarioId: 'u99'), _pendiente('mio')]);
      final repositorio = RepositorioOrdenesTrabajoFalso();
      final contenedor = crearContenedor(sesion: perfilTecnico, cola: cola, ordenes: repositorio);

      await contenedor.read(colaCierresViewModelProvider.notifier).enviarPendientes();

      expect(repositorio.cierresRecibidos, ['mio']);
      expect(cola.cierres.single.id, 'de-otro'); // se enviará cuando esa persona inicie sesión
    });
  });

  group('sesión guardada', () {
    test('al iniciar sesión se guarda para enviar la cola aunque se cierre la app', () async {
      final guardada = RepositorioSesionGuardadaEnMemoria();
      crearContenedor(sesion: perfilTecnico, sesionGuardada: guardada);
      await Future<void>.delayed(Duration.zero);

      expect(guardada.sesion?.usuarioId, 'u2');
    });

    test('al reabrir la app se recupera si el token sigue vigente', () async {
      final guardada = RepositorioSesionGuardadaEnMemoria(_sesionGuardada(DateTime(2026, 10, 5, 14)));
      final contenedor = crearContenedor(sesionGuardada: guardada);

      final recuperada = await contenedor.read(sesionProvider.notifier).restaurar(ahora: DateTime(2026, 10, 5, 12));

      expect(recuperada, isTrue);
      expect(contenedor.read(sesionProvider)?.id, 'u2');
    });

    test('con el token vencido se pide iniciar sesión y se borra la sesión guardada', () async {
      final guardada = RepositorioSesionGuardadaEnMemoria(_sesionGuardada(DateTime(2026, 10, 5, 14)));
      final contenedor = crearContenedor(sesionGuardada: guardada);

      final recuperada = await contenedor.read(sesionProvider.notifier).restaurar(ahora: DateTime(2026, 10, 5, 15));

      expect(recuperada, isFalse);
      expect(guardada.sesion, isNull);
    });
  });
}
