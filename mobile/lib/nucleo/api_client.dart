import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sesion.dart';

/// Dirección del backend. Se elige al compilar:
/// `flutter build apk --release --dart-define=API_URL=https://tu-dominio.ngrok-free.app/api/v1`
/// Sin --dart-define se usa el backend local, para desarrollar con el emulador (con adb reverse).
const baseUrlApi = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000/api/v1');

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrlApi,
    // ngrok gratuito puede mostrar una página de aviso en lugar de la respuesta; este encabezado la omite.
    // El backend lo ignora, así que no afecta cuando se usa sin ngrok.
    headers: {'ngrok-skip-browser-warning': 'true'},
  ));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final sesion = ref.read(sesionProvider);
        if (sesion != null) {
          options.headers['Authorization'] = 'Bearer ${sesion.token}';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});
