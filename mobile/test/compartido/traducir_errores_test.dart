import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/datos/remoto/traducir_errores.dart';
import 'package:maintenance_app/dominio/errores.dart';

DioException _error({DioExceptionType tipo = DioExceptionType.badResponse, Object? datos}) {
  final peticion = RequestOptions(path: '/x');
  return DioException(
    requestOptions: peticion,
    type: tipo,
    response: datos == null ? null : Response(requestOptions: peticion, data: datos),
  );
}

void main() {
  test('devuelve el resultado si la llamada no falla', () async {
    expect(await traducirErrores(() async => 42), 42);
  });

  test('usa el campo detail que envía el backend', () {
    expect(
      traducirErrores(() => throw _error(datos: {'detail': 'Credenciales inválidas'})),
      throwsA(isA<ErrorDeAplicacion>()
          .having((e) => e.mensaje, 'mensaje', 'Credenciales inválidas')),
    );
  });

  test('avisa cuando no hay conexión', () {
    expect(
      traducirErrores(() => throw _error(tipo: DioExceptionType.connectionError)),
      throwsA(isA<ErrorDeAplicacion>()
          .having((e) => e.mensaje, 'mensaje', 'No se pudo conectar al servidor')),
    );
  });
}
