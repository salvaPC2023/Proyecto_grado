import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/modelos/perfil.dart';
import '../dominio/repositorios/repositorio_almacen_local.dart';
import 'di.dart';


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
  bool get esAdministrador => rol == 'administrador';
  /// Imagen segun rol; se conoce desde el login
  String get imagenAvatar => switch (rol) {
        'administrador' => 'assets/images/icono_administrador.png',
        'supervisor' => 'assets/images/icono_supervisor.png',
        _ => 'assets/images/icono_tecnico.png',
      };
  String get etiquetaRol => switch (rol) {
        'administrador' => 'Administrador',
        'supervisor' => 'Supervisor',
        _ => 'Técnico',
      };

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
    // se guarda para que la cola de cierres se envíe aunque el técnico cierre la app
    final sesion = state;
    if (sesion != null) {
      _sinFallar(ref.read(repositorioSesionGuardadaProvider).guardar(SesionGuardada(
            token: sesion.token,
            rol: sesion.rol,
            usuarioId: sesion.id,
            nombreCompleto: sesion.nombreCompleto,
            nombreUsuario: sesion.nombreUsuario,
          )));
    }
  }

  void cerrarSesion() {
    state = null;
    _sinFallar(ref.read(repositorioSesionGuardadaProvider).borrar());
  }

  /// Al abrir la app: recupera la sesión guardada si su token sigue vigente. Devuelve true si la recuperó
  Future<bool> restaurar({DateTime? ahora}) async {
    try {
      final guardada = await ref.read(repositorioSesionGuardadaProvider).leer();
      if (guardada == null) return false;
      if (!tokenVigente(guardada.token, ahora: ahora)) {
        await ref.read(repositorioSesionGuardadaProvider).borrar();
        return false;
      }
      state = SesionUsuario(
        token: guardada.token,
        rol: guardada.rol,
        id: guardada.usuarioId,
        nombreCompleto: guardada.nombreCompleto,
        nombreUsuario: guardada.nombreUsuario,
      );
      return true;
    } catch (_) {
      return false; // si el celular no puede leerla, simplemente se pide iniciar sesión
    }
  }

  // si el celular no puede guardar la sesión, la app sigue funcionando: solo no la recordará al reabrirla
  void _sinFallar(Future<void> operacion) => operacion.catchError((Object _) {});
}

/// Revisa la fecha de vencimiento ("exp") que el backend pone dentro del token JWT
bool tokenVigente(String token, {DateTime? ahora}) {
  try {
    final partes = token.split('.');
    if (partes.length != 3) return false;
    final carga = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(partes[1])))) as Map<String, dynamic>;
    final vence = DateTime.fromMillisecondsSinceEpoch((carga['exp'] as num).toInt() * 1000);
    return (ahora ?? DateTime.now()).isBefore(vence);
  } catch (_) {
    return false;
  }
}

final sesionProvider = NotifierProvider<SesionNotifier, SesionUsuario?>(
  SesionNotifier.new,
);
