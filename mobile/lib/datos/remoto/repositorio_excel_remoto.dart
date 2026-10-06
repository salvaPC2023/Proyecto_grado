import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../dominio/errores.dart';
import '../../dominio/repositorios/repositorio_excel.dart';
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
}
