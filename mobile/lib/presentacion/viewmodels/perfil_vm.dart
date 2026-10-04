import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelos/perfil.dart';
import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';

class PerfilViewModel extends AsyncNotifier<Perfil> {
  @override
  Future<Perfil> build() {
    ref.watch(sesionProvider.select((sesion) => sesion?.token));
    return ref.read(repositorioPerfilProvider).verPerfil();
  }

  Future<void> guardarCambios({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    final repositorio = ref.read(repositorioPerfilProvider);
    await repositorio.editarPerfil(
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
    );
    final perfil = await repositorio.verPerfil();
    ref.read(sesionProvider.notifier).completarConPerfil(perfil);
    state = AsyncValue.data(perfil);
  }

  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) {
    return ref.read(repositorioPerfilProvider).cambiarPassword(
          passwordActual: passwordActual,
          passwordNueva: passwordNueva,
        );
  }
}

final perfilViewModelProvider =
    AsyncNotifierProvider<PerfilViewModel, Perfil>(PerfilViewModel.new);
