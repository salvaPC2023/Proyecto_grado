import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/datos/remoto/repositorio_autenticacion_remoto.dart';
import 'package:maintenance_app/datos/remoto/repositorio_ordenes_trabajo_remoto.dart';
import 'package:maintenance_app/datos/remoto/repositorio_perfil_remoto.dart';
import 'package:maintenance_app/datos/remoto/repositorio_tecnicos_remoto.dart';
import 'package:maintenance_app/nucleo/api_client.dart';
import 'package:maintenance_app/nucleo/di.dart';
import 'package:maintenance_app/nucleo/sesion.dart';

import 'dio_falso.dart';

void main() {
  test('con sesión iniciada envía el token en cada petición', () async {
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
    contenedor.read(sesionProvider.notifier).establecerToken(token: 'abc', rol: 'tecnico');
    final adaptador = AdaptadorHttpFalso((_) => null);
    final dio = contenedor.read(dioProvider)..httpClientAdapter = adaptador;

    await dio.get('/perfil');

    expect(adaptador.ultima.headers['Authorization'], 'Bearer abc');
  });

  test('sin sesión no envía token', () async {
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
    final adaptador = AdaptadorHttpFalso((_) => null);
    final dio = contenedor.read(dioProvider)..httpClientAdapter = adaptador;

    await dio.get('/perfil');

    expect(adaptador.ultima.headers.containsKey('Authorization'), isFalse);
  });

  test('la app usa los repositorios que llaman a la API', () {
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);

    expect(contenedor.read(repositorioAutenticacionProvider), isA<RepositorioAutenticacionRemoto>());
    expect(contenedor.read(repositorioPerfilProvider), isA<RepositorioPerfilRemoto>());
    expect(contenedor.read(repositorioTecnicosProvider), isA<RepositorioTecnicosRemoto>());
    expect(contenedor.read(repositorioOrdenesTrabajoProvider), isA<RepositorioOrdenesTrabajoRemoto>());
  });
}
