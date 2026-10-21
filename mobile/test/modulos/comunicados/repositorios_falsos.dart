import 'dart:typed_data';

import 'package:maintenance_app/dominio/errores.dart';
import 'package:maintenance_app/dominio/modelos/comunicado.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_comunicados.dart';

// Implementación en memoria, no se llama a la API real

final _ahora = DateTime.now();

Comunicado crearComunicado({
  String id = 'c1',
  String titulo = 'Uso obligatorio de EPP',
  String? texto = 'Casco y guantes en subestaciones',
  CategoriaComunicado categoria = CategoriaComunicado.seguridad,
  bool personal = false,
  bool tieneImagen = false,
  String? destinatario,
}) {
  return Comunicado(
    id: id,
    titulo: titulo,
    texto: texto,
    categoria: categoria,
    tieneImagen: tieneImagen,
    personal: personal,
    fechaEnvio: _ahora,
    fechaExpiracion: _ahora.add(const Duration(days: 7)),
    autorNombre: 'Ana Rojas',
    destinatarioNombre: destinatario,
  );
}

class RepositorioComunicadosFalso implements RepositorioComunicados {
  RepositorioComunicadosFalso({List<Comunicado>? comunicados, this.error, this.errorAlPublicar})
      : comunicados = comunicados ?? [];

  final List<Comunicado> comunicados;
  final ErrorDeAplicacion? error;
  final ErrorDeAplicacion? errorAlPublicar;

  ComunicadoNuevo? publicado;
  String? retirado;

  @override
  Future<List<Comunicado>> listar() async {
    if (error != null) throw error!;
    return List.of(comunicados);
  }

  @override
  Future<Comunicado> publicar(ComunicadoNuevo comunicado) async {
    if (errorAlPublicar != null) throw errorAlPublicar!;
    publicado = comunicado;
    final creado = crearComunicado(
      id: 'nuevo',
      titulo: comunicado.titulo,
      texto: comunicado.texto,
      categoria: comunicado.categoria,
      personal: comunicado.tecnicoId != null,
    );
    comunicados.insert(0, creado);
    return creado;
  }

  @override
  Future<void> retirar(String comunicadoId) async {
    retirado = comunicadoId;
    comunicados.removeWhere((c) => c.id == comunicadoId);
  }

  @override
  Future<Uint8List> imagen(String comunicadoId) async => Uint8List(0);
}
