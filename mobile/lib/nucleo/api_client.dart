import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sesion.dart';

// Funciona corriendo el backend en la misma PC (uvicorn en :8000) y la app
// con "flutter run -d chrome".
// TODO: si corres en un EMULADOR ANDROID en vez de Chrome, cambia
// "localhost" por "10.0.2.2" — asi es como el emulador ve tu PC.
const baseUrlApi = 'http://localhost:8000/api/v1';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: baseUrlApi));
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
