import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../dominio/errores.dart';
import '../../dominio/modelos/resultado_importacion.dart';
import '../../dominio/repositorios/repositorio_excel.dart';
import 'mapeo_json.dart';
import 'traducir_errores.dart';

String _fecha(DateTime f) => f.toIso8601String().substring(0, 10);

class RepositorioExcelRemoto implements RepositorioExcel {
  RepositorioExcelRemoto(this._dio);
  final Dio _dio;

  @override
  Future<Uint8List> exportarOts({DateTime? desde, DateTime? hasta, String? ubicacionTecnicaId}) {
    return traducirErrores(() async {
      try {
        final respuesta = await _dio.get<List<int>>(
          '/ordenes-trabajo/exportar',
          queryParameters: {
            if (desde != null) 'desde': _fecha(desde),
            if (hasta != null) 'hasta': _fecha(hasta),
            'ubicacion_tecnica_id': ?ubicacionTecnicaId,
          },
          options: Options(responseType: ResponseType.bytes),
        );
        return Uint8List.fromList(respuesta.data!);
      } on DioException catch (error) {
        // al pedir bytes, el mensaje de error del backend también llega en bytes
        final datos = error.response?.data;
        if (datos is List<int>) {
          final json = jsonDecode(utf8.decode(datos));
          if (json is Map && json['detail'] is String) throw ErrorDeAplicacion(json['detail'] as String);
        }
        rethrow;
      }
    });
  }

  Future<ResultadoImportacion> _importar(String ruta, Uint8List archivo, String nombreArchivo) {
    return traducirErrores(() async {
      final datos = FormData.fromMap({'archivo': MultipartFile.fromBytes(archivo, filename: nombreArchivo)});
      final respuesta = await _dio.post(ruta, data: datos);
      return resultadoImportacionDesdeJson(respuesta.data as Json);
    });
  }

  @override
  Future<ResultadoImportacion> importarCargaInicial(Uint8List archivo, String nombreArchivo) =>
      _importar('/importacion/carga-inicial', archivo, nombreArchivo);

  @override
  Future<ResultadoImportacion> importarParaMiGrupo(Uint8List archivo, String nombreArchivo) =>
      _importar('/importacion/mi-grupo', archivo, nombreArchivo);
}
