import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Reemplaza la conexión HTTP de Dio, donde guarda cada peticion y responde con responeder
class AdaptadorHttpFalso implements HttpClientAdapter {
  AdaptadorHttpFalso(this.responder, {this.estado = 200});

  final Object? Function(RequestOptions peticion) responder;
  final int estado;
  final peticiones = <RequestOptions>[];

  RequestOptions get ultima => peticiones.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    peticiones.add(options);
    return ResponseBody.fromString(
      jsonEncode(responder(options)),
      estado,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Simula que no hay señal: ninguna petición llega al servidor
class AdaptadorSinConexion implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    throw DioException.connectionError(requestOptions: options, reason: 'sin señal');
  }

  @override
  void close({bool force = false}) {}
}

Dio crearDioFalso(HttpClientAdapter adaptador) =>
    Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adaptador;
