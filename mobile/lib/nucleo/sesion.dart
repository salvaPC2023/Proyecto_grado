import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/modelos/perfil.dart';


class SesionUsuario {
  const SesionUsuario({
    required this.token,
    required this.rol,
    this.id = '',
    this.nombreCompleto = '',
    this.nombreUsuario = '',
  });

  final String token;
  final String rol;
  final String id;
  final String nombreCompleto;
  final String nombreUsuario;

  bool get esSupervisor => rol == 'supervisor';

  SesionUsuario copyWith({String? id, String? nombreCompleto, String? nombreUsuario}) {
    return SesionUsuario(
      token: token,
      rol: rol,
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
    );
  }
}

class SesionNotifier extends Notifier<SesionUsuario?> {
  @override
  SesionUsuario? build() => null;

  void establecerToken({required String token, required String rol}) {
    state = SesionUsuario(token: token, rol: rol);
  }

  void completarConPerfil(Perfil perfil) {
    state = state?.copyWith(
      id: perfil.id,
      nombreCompleto: perfil.nombreCompleto,
      nombreUsuario: perfil.nombreUsuario,
    );
  }

  void cerrarSesion() => state = null;
}

final sesionProvider = NotifierProvider<SesionNotifier, SesionUsuario?>(
  SesionNotifier.new,
);
