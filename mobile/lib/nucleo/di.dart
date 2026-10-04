import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datos/remoto/repositorio_autenticacion_remoto.dart';
import '../datos/remoto/repositorio_ordenes_trabajo_remoto.dart';
import '../datos/remoto/repositorio_perfil_remoto.dart';
import '../datos/remoto/repositorio_tecnicos_remoto.dart';
import '../dominio/repositorios/repositorio_autenticacion.dart';
import '../dominio/repositorios/repositorio_ordenes_trabajo.dart';
import '../dominio/repositorios/repositorio_perfil.dart';
import '../dominio/repositorios/repositorio_tecnicos.dart';
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
