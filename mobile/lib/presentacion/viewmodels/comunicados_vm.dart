import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dominio/modelos/comunicado.dart';
import '../../nucleo/di.dart';
import '../../nucleo/sesion.dart';

class ComunicadosViewModel extends AsyncNotifier<List<Comunicado>> {
  @override
  Future<List<Comunicado>> build() {
    // al cambiar de sesión se vuelven a pedir: cada usuario ve los suyos
    ref.watch(sesionProvider.select((sesion) => sesion?.token));
    return ref.read(repositorioComunicadosProvider).listar();
  }

  Future<void> recargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(repositorioComunicadosProvider).listar());
  }

  /// Lanza ErrorDeAplicacion si el backend lo rechaza, para mostrar el motivo en el formulario
  Future<void> publicar(ComunicadoNuevo comunicado) async {
    await ref.read(repositorioComunicadosProvider).publicar(comunicado);
    await recargar();
  }

  Future<void> retirar(String comunicadoId) async {
    await ref.read(repositorioComunicadosProvider).retirar(comunicadoId);
    await recargar();
  }
}

final comunicadosViewModelProvider =
    AsyncNotifierProvider<ComunicadosViewModel, List<Comunicado>>(ComunicadosViewModel.new);

/// Imagen de un comunicado; se pide una sola vez mientras se muestre
final imagenComunicadoProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, comunicadoId) => ref.read(repositorioComunicadosProvider).imagen(comunicadoId),
);
