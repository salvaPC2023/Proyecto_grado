import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/datos/remoto/repositorio_comunicados_remoto.dart';
import 'package:maintenance_app/dominio/modelos/comunicado.dart';

import '../../compartido/dio_falso.dart';

const comunicadoJson = {
  'id': 'c1',
  'titulo': 'Uso de EPP',
  'texto': 'Casco obligatorio',
  'categoria': 'seguridad',
  'tiene_imagen': true,
  'personal': false,
  'fecha_envio': '2026-10-21T09:00:00',
  'fecha_expiracion': '2026-10-28T23:59:00',
  'autor_nombre': 'Ana Rojas',
  'destinatario_nombre': null,
};

Map<String, String> _campos(RequestOptions peticion) =>
    {for (final campo in (peticion.data as FormData).fields) campo.key: campo.value};

void main() {
  test('lista y lee cada comunicado', () async {
    final adaptador = AdaptadorHttpFalso((_) => [comunicadoJson]);
    final repositorio = RepositorioComunicadosRemoto(crearDioFalso(adaptador));

    final comunicado = (await repositorio.listar()).single;

    expect(adaptador.ultima.path, '/comunicados');
    expect(comunicado.categoria, CategoriaComunicado.seguridad);
    expect(comunicado.tieneImagen, isTrue);
    expect(comunicado.fechaExpiracion, DateTime(2026, 10, 28, 23, 59));
  });

  test('un comunicado general se envía como formulario sin técnico', () async {
    final adaptador = AdaptadorHttpFalso((_) => comunicadoJson);
    final repositorio = RepositorioComunicadosRemoto(crearDioFalso(adaptador));

    await repositorio.publicar(ComunicadoNuevo(
      titulo: 'Uso de EPP',
      categoria: CategoriaComunicado.seguridad,
      fechaExpiracion: DateTime(2026, 10, 28, 23, 59),
      texto: 'Casco obligatorio',
    ));

    final campos = _campos(adaptador.ultima);
    expect(adaptador.ultima.method, 'POST');
    expect(campos['titulo'], 'Uso de EPP');
    expect(campos['categoria'], 'seguridad');
    expect(campos['fecha_expiracion'], '2026-10-28T23:59:00.000');
    expect(campos.containsKey('tecnico_id'), isFalse);
  });

  test('un comunicado personal lleva el técnico y la imagen adjunta', () async {
    final adaptador = AdaptadorHttpFalso((_) => comunicadoJson);
    final repositorio = RepositorioComunicadosRemoto(crearDioFalso(adaptador));

    await repositorio.publicar(ComunicadoNuevo(
      titulo: 'Para Luis',
      categoria: CategoriaComunicado.general,
      fechaExpiracion: DateTime(2026, 10, 28),
      tecnicoId: 't1',
      imagen: [0x89, 0x50, 0x4E, 0x47],
      nombreImagen: 'foto.png',
    ));

    final datos = adaptador.ultima.data as FormData;
    expect(_campos(adaptador.ultima)['tecnico_id'], 't1');
    expect(datos.files.single.key, 'imagen');
    expect(datos.files.single.value.filename, 'foto.png');
  });

  test('retirar usa DELETE con el id del comunicado', () async {
    final adaptador = AdaptadorHttpFalso((_) => null);
    final repositorio = RepositorioComunicadosRemoto(crearDioFalso(adaptador));

    await repositorio.retirar('c1');

    expect(adaptador.ultima.method, 'DELETE');
    expect(adaptador.ultima.path, '/comunicados/c1');
  });
}
