import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../dominio/modelos/comunicado.dart';
import '../../dominio/repositorios/repositorio_comunicados.dart';
import 'mapeo_json.dart';
import 'traducir_errores.dart';

class RepositorioComunicadosRemoto implements RepositorioComunicados {
  RepositorioComunicadosRemoto(this._dio);
  final Dio _dio;

  @override
  Future<List<Comunicado>> listar() {
    return traducirErrores(() async {
      final respuesta = await _dio.get('/comunicados');
      return [for (final c in respuesta.data as List) comunicadoDesdeJson(c as Json)];
    });
  }

  @override
  Future<Comunicado> publicar(ComunicadoNuevo comunicado) {
    return traducirErrores(() async {
      // se envía como formulario porque puede llevar una imagen
      final datos = FormData.fromMap({
        'titulo': comunicado.titulo,
        'categoria': comunicado.categoria.name,
        'fecha_expiracion': comunicado.fechaExpiracion.toIso8601String(),
        if (comunicado.texto != null) 'texto': comunicado.texto,
        if (comunicado.tecnicoId != null) 'tecnico_id': comunicado.tecnicoId,
        if (comunicado.imagen != null)
          'imagen': MultipartFile.fromBytes(comunicado.imagen!, filename: comunicado.nombreImagen ?? 'imagen'),
      });
      final respuesta = await _dio.post('/comunicados', data: datos);
      return comunicadoDesdeJson(respuesta.data as Json);
    });
  }

  @override
  Future<void> retirar(String comunicadoId) {
    return traducirErrores(() async {
      await _dio.delete('/comunicados/$comunicadoId');
    });
  }

  @override
  Future<Uint8List> imagen(String comunicadoId) {
    return traducirErrores(() async {
      final respuesta = await _dio.get<List<int>>(
        '/comunicados/$comunicadoId/imagen',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(respuesta.data!);
    });
  }
}
