import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelos/grupo.dart';
import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';
import 'supervisores_vm.dart';

class GruposViewModel extends AsyncNotifier<List<Grupo>> {
  @override
  Future<List<Grupo>> build() {
    ref.watch(sesionProvider.select((sesion) => sesion?.token));
    return ref.read(repositorioGruposProvider).listar();
  }

  Future<void> recargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(repositorioGruposProvider).listar());
  }

  // la lista de supervisores muestra el nombre del grupo, por eso también se recarga
  Future<void> _despuesDeCambiar() async {
    ref.invalidate(supervisoresViewModelProvider);
    await recargar();
  }

  Future<void> crear({required String nombreDeGrupo, required String supervisorId}) async {
    await ref.read(repositorioGruposProvider).crear(nombreDeGrupo: nombreDeGrupo, supervisorId: supervisorId);
    await _despuesDeCambiar();
  }

  Future<void> asignarSupervisor(String grupoId, String supervisorId) async {
    await ref.read(repositorioGruposProvider).asignarSupervisor(grupoId, supervisorId);
    await _despuesDeCambiar();
  }
}

final gruposViewModelProvider = AsyncNotifierProvider<GruposViewModel, List<Grupo>>(GruposViewModel.new);
