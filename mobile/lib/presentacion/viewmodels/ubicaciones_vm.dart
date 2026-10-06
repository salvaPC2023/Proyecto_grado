import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelos/orden_trabajo.dart';
import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';

class UbicacionesViewModel extends AsyncNotifier<List<UbicacionTecnica>> {
  @override
  Future<List<UbicacionTecnica>> build() {
    ref.watch(sesionProvider.select((sesion) => sesion?.token));
    return ref.read(repositorioUbicacionesProvider).listar();
  }

  Future<void> recargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(repositorioUbicacionesProvider).listar());
  }

  Future<void> guardar({String? id, required String sector, String? subsector, String? sistema, String? subsistema}) async {
    await ref.read(repositorioUbicacionesProvider).guardar(
          id: id,
          sector: sector,
          subsector: subsector,
          sistema: sistema,
          subsistema: subsistema,
        );
    await recargar();
  }

  Future<void> borrar(String id) async {
    await ref.read(repositorioUbicacionesProvider).borrar(id);
    await recargar();
  }
}

final ubicacionesViewModelProvider =
    AsyncNotifierProvider<UbicacionesViewModel, List<UbicacionTecnica>>(UbicacionesViewModel.new);
