import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelos/supervisor.dart';
import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';

class SupervisoresViewModel extends AsyncNotifier<List<Supervisor>> {
  @override
  Future<List<Supervisor>> build() {
    ref.watch(sesionProvider.select((sesion) => sesion?.token));
    return ref.read(repositorioSupervisoresProvider).listar();
  }

  Future<void> recargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(repositorioSupervisoresProvider).listar());
  }

  Future<Supervisor> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String nombreDeGrupo,
    required String horarioEntrada,
    required String horarioSalida,
  }) async {
    final supervisor = await ref.read(repositorioSupervisoresProvider).crear(
          nombre: nombre,
          apellidoPaterno: apellidoPaterno,
          apellidoMaterno: apellidoMaterno,
          nombreDeGrupo: nombreDeGrupo,
          horarioEntrada: horarioEntrada,
          horarioSalida: horarioSalida,
        );
    await recargar();
    return supervisor;
  }

  Future<void> cambiarEstado(String supervisorId, bool activo) async {
    await ref.read(repositorioSupervisoresProvider).cambiarEstado(supervisorId, activo);
    await recargar();
  }
}

final supervisoresViewModelProvider =
    AsyncNotifierProvider<SupervisoresViewModel, List<Supervisor>>(SupervisoresViewModel.new);
