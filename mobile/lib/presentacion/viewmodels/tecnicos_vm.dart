import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelos/tecnico.dart';
import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';

class TecnicosViewModel extends AsyncNotifier<List<Tecnico>> {
  @override
  Future<List<Tecnico>> build() {
    // Depende del token: otro Supervisor que entre en el mismo dispositivo no
    // debe ver, ni por un instante, los tecnicos del grupo del anterior.
    ref.watch(sesionProvider.select((sesion) => sesion?.token));
    return ref.read(repositorioTecnicosProvider).listar();
  }

  Future<void> recargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(repositorioTecnicosProvider).listar());
  }

  /// Lanza si algo sale mal (ej. nombre de usuario duplicado) — la
  /// pantalla lo atrapa con try/catch para mostrar el mensaje.
  Future<void> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String nombreUsuario,
    required String profesion,
  }) async {
    await ref.read(repositorioTecnicosProvider).crear(
          nombre: nombre,
          apellidoPaterno: apellidoPaterno,
          apellidoMaterno: apellidoMaterno,
          nombreUsuario: nombreUsuario,
          profesion: profesion,
        );
    await recargar();
  }

  Future<void> cambiarEstado(String tecnicoId, bool activo) async {
    await ref.read(repositorioTecnicosProvider).cambiarEstado(tecnicoId, activo);
    await recargar();
  }
}

final tecnicosViewModelProvider =
    AsyncNotifierProvider<TecnicosViewModel, List<Tecnico>>(TecnicosViewModel.new);
