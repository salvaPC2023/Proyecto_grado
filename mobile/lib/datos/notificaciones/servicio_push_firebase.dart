import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../dominio/repositorios/repositorio_notificaciones.dart';

// Se usa el token de FCM (getToken, onTokenRefresh, deleteToken), que firebase_messaging 17 marca como
// obsoleto en favor del registro por ID de instalación. Es el que el backend envía con firebase-admin
// (messaging.Message(token=...)); se cambiará cuando el SDK del backend use el mismo esquema.
// ignore_for_file: deprecated_member_use

/// Si Firebase no se pudo iniciar (por ejemplo, sin google-services.json), la app funciona igual, sin notificaciones
class ServicioPushFirebase implements ServicioPush {
  bool get _disponible => Firebase.apps.isNotEmpty;

  @override
  Future<String?> obtenerToken() async {
    if (!_disponible) return null;
    // en Android 13 o superior el sistema pregunta al usuario la primera vez
    final permiso = await FirebaseMessaging.instance.requestPermission();
    if (permiso.authorizationStatus == AuthorizationStatus.denied) return null;
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Stream<String> get tokensNuevos => _disponible ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  @override
  Stream<NotificacionRecibida> get enPrimerPlano => _disponible
      ? FirebaseMessaging.onMessage
          .where((mensaje) => mensaje.notification != null)
          .map((mensaje) => NotificacionRecibida(
                titulo: mensaje.notification!.title ?? '',
                cuerpo: mensaje.notification!.body ?? '',
              ))
      : const Stream.empty();

  @override
  Future<void> borrarToken() async {
    if (_disponible) await FirebaseMessaging.instance.deleteToken();
  }
}
