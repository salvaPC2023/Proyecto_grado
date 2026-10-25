import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dominio/modelos/cierre_pendiente.dart';
import '../../dominio/repositorios/repositorio_almacen_local.dart';

/// La cola se guarda como JSON en las preferencias del celular; son pocos cierres, no hace falta una base de datos
class RepositorioColaCierresLocal implements RepositorioColaCierres {
  static const _clave = 'cola_cierres';

  @override
  Future<List<CierrePendiente>> leer() async {
    final texto = (await SharedPreferences.getInstance()).getString(_clave);
    if (texto == null) return [];
    return [for (final json in jsonDecode(texto) as List) cierrePendienteDesdeJson(json as Map<String, dynamic>)];
  }

  @override
  Future<void> guardar(List<CierrePendiente> cierres) async {
    await (await SharedPreferences.getInstance()).setString(_clave, jsonEncode(cierres.map(cierrePendienteAJson).toList()));
  }
}

Map<String, dynamic> cierrePendienteAJson(CierrePendiente c) => {
      'id': c.id,
      'usuario_id': c.usuarioId,
      'ot_id': c.otId,
      'paso_id': c.pasoId,
      'ejecutado': c.ejecutado,
      'tiempo_real_trabajado': c.tiempoRealTrabajado,
      'descripcion': c.descripcion,
      'fecha_hora': c.fechaHora.toIso8601String(),
      'titulo_ot': c.tituloOt,
      'descripcion_paso': c.descripcionPaso,
      'motivo_rechazo': c.motivoRechazo,
    };

CierrePendiente cierrePendienteDesdeJson(Map<String, dynamic> json) => CierrePendiente(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      otId: json['ot_id'] as String,
      pasoId: json['paso_id'] as String,
      ejecutado: json['ejecutado'] as bool,
      tiempoRealTrabajado: (json['tiempo_real_trabajado'] as num).toDouble(),
      descripcion: json['descripcion'] as String,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      tituloOt: json['titulo_ot'] as String? ?? '',
      descripcionPaso: json['descripcion_paso'] as String? ?? '',
      motivoRechazo: json['motivo_rechazo'] as String?,
    );

/// El token se guarda cifrado (Keystore en Android), no en las preferencias comunes (QAS-13)
class RepositorioSesionSegura implements RepositorioSesionGuardada {
  static const _almacen = FlutterSecureStorage();
  static const _clave = 'sesion';

  @override
  Future<SesionGuardada?> leer() async {
    final texto = await _almacen.read(key: _clave);
    if (texto == null) return null;
    final json = jsonDecode(texto) as Map<String, dynamic>;
    return SesionGuardada(
      token: json['token'] as String,
      rol: json['rol'] as String,
      usuarioId: json['usuario_id'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      nombreUsuario: json['nombre_usuario'] as String,
    );
  }

  @override
  Future<void> guardar(SesionGuardada sesion) => _almacen.write(
        key: _clave,
        value: jsonEncode({
          'token': sesion.token,
          'rol': sesion.rol,
          'usuario_id': sesion.usuarioId,
          'nombre_completo': sesion.nombreCompleto,
          'nombre_usuario': sesion.nombreUsuario,
        }),
      );

  @override
  Future<void> borrar() => _almacen.delete(key: _clave);
}

/// Copia de las respuestas del servidor (OT del técnico y su detalle) con la hora en que se guardaron
class RepositorioRespaldoPreferencias implements RepositorioRespaldoLocal {
  static const _prefijo = 'respaldo_';

  @override
  Future<void> guardar(String clave, Object? json) async {
    await (await SharedPreferences.getInstance())
        .setString('$_prefijo$clave', jsonEncode({'guardado': DateTime.now().toIso8601String(), 'json': json}));
  }

  @override
  Future<(Object?, DateTime)?> leer(String clave) async {
    final texto = (await SharedPreferences.getInstance()).getString('$_prefijo$clave');
    if (texto == null) return null;
    final datos = jsonDecode(texto) as Map<String, dynamic>;
    return (datos['json'], DateTime.parse(datos['guardado'] as String));
  }
}
