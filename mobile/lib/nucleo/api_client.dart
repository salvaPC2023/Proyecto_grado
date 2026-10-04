import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sesion.dart';

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
