import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/remoto/repositorio_autenticacion_remoto.dart';
import '../datos/remoto/repositorio_estandarizacion_remoto.dart';
import '../datos/remoto/repositorio_excel_remoto.dart';
import '../datos/remoto/repositorio_grupos_remoto.dart';
import '../datos/remoto/repositorio_ordenes_trabajo_remoto.dart';
import '../datos/remoto/repositorio_perfil_remoto.dart';
import '../datos/remoto/repositorio_supervisores_remoto.dart';
import '../datos/remoto/repositorio_tecnicos_remoto.dart';
import '../datos/remoto/repositorio_ubicaciones_remoto.dart';
import '../dominio/repositorios/repositorio_autenticacion.dart';
import '../dominio/repositorios/repositorio_estandarizacion.dart';
import '../dominio/repositorios/repositorio_excel.dart';
import '../dominio/repositorios/repositorio_grupos.dart';
import '../dominio/repositorios/repositorio_ordenes_trabajo.dart';
import '../dominio/repositorios/repositorio_perfil.dart';
import '../dominio/repositorios/repositorio_supervisores.dart';
import '../dominio/repositorios/repositorio_tecnicos.dart';
import '../dominio/repositorios/repositorio_ubicaciones.dart';
import 'api_client.dart';


final repositorioAutenticacionProvider = Provider<RepositorioAutenticacion>(
  (ref) => RepositorioAutenticacionRemoto(ref.watch(dioProvider)),
);

final repositorioPerfilProvider = Provider<RepositorioPerfil>(
  (ref) => RepositorioPerfilRemoto(ref.watch(dioProvider)),
);

final repositorioTecnicosProvider = Provider<RepositorioTecnicos>(
  (ref) => RepositorioTecnicosRemoto(ref.watch(dioProvider)),
);

final repositorioOrdenesTrabajoProvider = Provider<RepositorioOrdenesTrabajo>(
  (ref) => RepositorioOrdenesTrabajoRemoto(ref.watch(dioProvider)),
);

final repositorioSupervisoresProvider = Provider<RepositorioSupervisores>(
  (ref) => RepositorioSupervisoresRemoto(ref.watch(dioProvider)),
);

final repositorioEstandarizacionProvider = Provider<RepositorioEstandarizacion>(
  (ref) => RepositorioEstandarizacionRemoto(ref.watch(dioProvider)),
);

final repositorioGruposProvider = Provider<RepositorioGrupos>(
  (ref) => RepositorioGruposRemoto(ref.watch(dioProvider)),
);

final repositorioUbicacionesProvider = Provider<RepositorioUbicaciones>(
  (ref) => RepositorioUbicacionesRemoto(ref.watch(dioProvider)),
);

final repositorioExcelProvider = Provider<RepositorioExcel>(
  (ref) => RepositorioExcelRemoto(ref.watch(dioProvider)),
);
