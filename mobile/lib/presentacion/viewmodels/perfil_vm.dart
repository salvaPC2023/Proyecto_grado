import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelos/perfil.dart';
import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';

class PerfilViewModel extends AsyncNotifier<Perfil> {
  @override
  Future<Perfil> build() {
    // Depende del token: al cerrar sesion o entrar con otro usuario, este
    // provider se descarta y vuelve a pedir el perfil del usuario actual.
    // Sin esto, el perfil del usuario anterior quedaba guardado en memoria.
    ref.watch(sesionProvider.select((sesion) => sesion?.token));
    return ref.read(repositorioPerfilProvider).verPerfil();
  }

  /// Lanza si algo sale mal — la pantalla lo atrapa con try/catch.
  Future<void> guardarCambios({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    final perfil = await ref.read(repositorioPerfilProvider).editarPerfil(
          nombre: nombre,
          apellidoPaterno: apellidoPaterno,
          apellidoMaterno: apellidoMaterno,
        );
    // El nombre en el encabezado de Home tambien se actualiza.
    ref.read(sesionProvider.notifier).completarConPerfil(perfil);
    state = AsyncValue.data(perfil);
  }

  /// Lanza si algo sale mal (ej. contraseña actual incorrecta) — la
  /// pantalla lo atrapa con try/catch para mostrar el mensaje.
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
