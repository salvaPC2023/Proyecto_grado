import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/nucleo/fechas.dart';
import 'package:maintenance_app/presentacion/viewmodels/ordenes_trabajo_vm.dart';

import '../../compartido/app_de_prueba.dart';
import 'repositorios_falsos.dart';

void main() {
  test('Mis OTs consulta el día de hoy', () async {
    final repositorio = RepositorioOrdenesTrabajoFalso();
    final contenedor = crearContenedor(ordenes: repositorio);
    contenedor.listen(misOtsViewModelProvider, (_, _) {}); // mantiene vivo el provider

    final ots = await contenedor.read(misOtsViewModelProvider.future);

    expect(ots, hasLength(1));
    expect(repositorio.fechaConsultada, hoySinHora());
  });

  test('OTs del grupo se puede filtrar por otra fecha', () async {
    final repositorio = RepositorioOrdenesTrabajoFalso();
    final contenedor = crearContenedor(ordenes: repositorio);
    contenedor.listen(otsGrupoViewModelProvider, (_, _) {});
    await contenedor.read(otsGrupoViewModelProvider.future);

    await contenedor
        .read(otsGrupoViewModelProvider.notifier)
        .filtrarPorFecha(DateTime(2026, 1, 15));

    expect(repositorio.fechaConsultada, DateTime(2026, 1, 15));
  });

  test('Nueva OT carga las ubicaciones técnicas', () async {
    final contenedor = crearContenedor();
    contenedor.listen(nuevaOtViewModelProvider, (_, _) {});

    await contenedor.read(nuevaOtViewModelProvider.notifier).recargar();

    expect(contenedor.read(nuevaOtViewModelProvider).value, hasLength(2));
  });
}
