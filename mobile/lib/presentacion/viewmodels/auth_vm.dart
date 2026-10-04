import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';

class AuthViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> iniciarSesion(String nombreUsuario, String password) async {
    state = const AsyncValue.loading();
    try {
      final resultado =
          await ref.read(repositorioAutenticacionProvider).iniciarSesion(nombreUsuario, password);

      ref
          .read(sesionProvider.notifier)
          .establecerToken(token: resultado.token, rol: resultado.rol);

      final perfil = await ref.read(repositorioPerfilProvider).verPerfil();
      ref.read(sesionProvider.notifier).completarConPerfil(perfil);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      ref.read(sesionProvider.notifier).cerrarSesion();
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AsyncValue<void>>(AuthViewModel.new);
