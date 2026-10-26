import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_notificaciones.dart';
import 'package:maintenance_app/nucleo/di.dart';
import 'package:maintenance_app/nucleo/sesion.dart';
import 'package:maintenance_app/presentacion/widgets/registro_notificaciones.dart';

import '../modulos/acceso_roles/repositorios_falsos.dart';
import 'almacen_falso.dart';

// Tarjeta 23: el celular se registra al iniciar sesión para recibir los avisos de pasos sin cerrar

class ServicioPushFalso implements ServicioPush {
  String? token = 'token-celular';
  int borrados = 0;
  final tokens = StreamController<String>.broadcast();
  final mensajes = StreamController<NotificacionRecibida>.broadcast();

  @override
  Future<String?> obtenerToken() async => token;

  @override
  Stream<String> get tokensNuevos => tokens.stream;

  @override
  Stream<NotificacionRecibida> get enPrimerPlano => mensajes.stream;

  @override
  Future<void> borrarToken() async => borrados++;
}

class RepositorioNotificacionesFalso implements RepositorioNotificaciones {
  final registrados = <String>[];

  @override
  Future<void> registrarDispositivo(String token) async => registrados.add(token);
}

void main() {
  late ServicioPushFalso push;
  late RepositorioNotificacionesFalso repositorio;
  late ProviderContainer contenedor;

  Future<void> montar(WidgetTester tester) async {
    push = ServicioPushFalso();
    repositorio = RepositorioNotificacionesFalso();
    contenedor = ProviderContainer(overrides: [
      servicioPushProvider.overrideWithValue(push),
      repositorioNotificacionesProvider.overrideWithValue(repositorio),
      repositorioSesionGuardadaProvider.overrideWithValue(RepositorioSesionGuardadaEnMemoria()),
    ]);
    addTearDown(contenedor.dispose);
    final mensajero = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: contenedor,
      child: MaterialApp(
        scaffoldMessengerKey: mensajero,
        home: RegistroNotificaciones(mensajero: mensajero, child: const Scaffold(body: Text('App'))),
      ),
    ));
  }

  void iniciarSesion() {
    contenedor.read(sesionProvider.notifier)
      ..establecerToken(token: 't', rol: 'tecnico')
      ..completarConPerfil(perfilTecnico);
  }

  testWidgets('al iniciar sesión registra el celular en el backend', (tester) async {
    await montar(tester);
    expect(repositorio.registrados, isEmpty); // sin sesión no se registra

    iniciarSesion();
    await tester.pumpAndSettle();

    expect(repositorio.registrados, ['token-celular']);
  });

  testWidgets('si Firebase cambia el token, registra el nuevo', (tester) async {
    await montar(tester);
    iniciarSesion();
    await tester.pumpAndSettle();

    push.tokens.add('token-nuevo');
    await tester.pumpAndSettle();

    expect(repositorio.registrados.last, 'token-nuevo');
  });

  testWidgets('al cerrar sesión da de baja el celular', (tester) async {
    await montar(tester);
    iniciarSesion();
    await tester.pumpAndSettle();

    contenedor.read(sesionProvider.notifier).cerrarSesion();
    await tester.pumpAndSettle();

    expect(push.borrados, 1);
  });

  testWidgets('sin permiso de notificaciones la app sigue igual', (tester) async {
    await montar(tester);
    push.token = null;

    iniciarSesion();
    await tester.pumpAndSettle();

    expect(repositorio.registrados, isEmpty);
    expect(find.text('App'), findsOneWidget);
  });

  testWidgets('con la app abierta el aviso se muestra en pantalla', (tester) async {
    await montar(tester);

    push.mensajes.add(const NotificacionRecibida(titulo: 'Pasos sin cerrar', cuerpo: 'Tienes 2 pasos sin cerrar.'));
    await tester.pump();

    expect(find.text('Pasos sin cerrar: Tienes 2 pasos sin cerrar.'), findsOneWidget);
  });
}
