import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';

enum ResultadoInicioSesion { ingreso, primerAcceso, fallo }

class AuthViewModel extends Notifier<AsyncValue<void>> {
  // token del login de un usuario recién creado; solo sirve para cambiar sus datos
  String? _tokenPrimerAcceso;

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<ResultadoInicioSesion> iniciarSesion(String nombreUsuario, String password) async {
    state = const AsyncValue.loading();
    try {
      final resultado =
          await ref.read(repositorioAutenticacionProvider).iniciarSesion(nombreUsuario, password);

      if (resultado.debeCambiarCredenciales) {
        // no se abre la sesión hasta que cambie usuario y contraseña
        _tokenPrimerAcceso = resultado.token;
        state = const AsyncValue.data(null);
        return ResultadoInicioSesion.primerAcceso;
      }

      ref
          .read(sesionProvider.notifier)
          .establecerToken(token: resultado.token, rol: resultado.rol);

      final perfil = await ref.read(repositorioPerfilProvider).verPerfil();
      ref.read(sesionProvider.notifier).completarConPerfil(perfil);

      state = const AsyncValue.data(null);
      return ResultadoInicioSesion.ingreso;
    } catch (e, st) {
      ref.read(sesionProvider.notifier).cerrarSesion();
      state = AsyncValue.error(e, st);
      return ResultadoInicioSesion.fallo;
    }
  }

  /// Lanza ErrorDeAplicacion si el backend rechaza los datos, para mostrarlo en el diálogo
  Future<void> completarPrimerAcceso({required String nombreUsuario, required String passwordNueva}) async {
    final token = _tokenPrimerAcceso;
    if (token == null) throw StateError('No hay un primer acceso pendiente');
    await ref.read(repositorioAutenticacionProvider).completarPrimerAcceso(
          token: token,
          nombreUsuario: nombreUsuario,
          passwordNueva: passwordNueva,
        );
    _tokenPrimerAcceso = null; // debe iniciar sesión otra vez con sus datos nuevos
  }

  void cancelarPrimerAcceso() => _tokenPrimerAcceso = null;
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AsyncValue<void>>(AuthViewModel.new);
