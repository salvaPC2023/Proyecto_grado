import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/di.dart';

class EstandarizacionViewModel extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncValue.data(null);

  Future<String?> estandarizar(String texto) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(repositorioEstandarizacionProvider).estandarizar(texto));
    return state.value;
  }

  void reiniciar() => state = const AsyncValue.data(null);
}

final estandarizacionViewModelProvider =
    NotifierProvider.autoDispose<EstandarizacionViewModel, AsyncValue<String?>>(EstandarizacionViewModel.new);
