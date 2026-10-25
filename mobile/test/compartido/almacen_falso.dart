import 'package:maintenance_app/dominio/modelos/cierre_pendiente.dart';
import 'package:maintenance_app/dominio/repositorios/repositorio_almacen_local.dart';

// Lo que en el celular se guarda en disco, aquí vive en memoria durante el test

class RepositorioColaCierresEnMemoria implements RepositorioColaCierres {
  RepositorioColaCierresEnMemoria([List<CierrePendiente>? cierres]) : cierres = [...?cierres];
  List<CierrePendiente> cierres;

  @override
  Future<List<CierrePendiente>> leer() async => [...cierres];

  @override
  Future<void> guardar(List<CierrePendiente> nuevos) async => cierres = [...nuevos];
}

class RepositorioSesionGuardadaEnMemoria implements RepositorioSesionGuardada {
  RepositorioSesionGuardadaEnMemoria([this.sesion]);
  SesionGuardada? sesion;

  @override
  Future<SesionGuardada?> leer() async => sesion;

  @override
  Future<void> guardar(SesionGuardada nueva) async => sesion = nueva;

  @override
  Future<void> borrar() async => sesion = null;
}

class RepositorioRespaldoEnMemoria implements RepositorioRespaldoLocal {
  final _datos = <String, (Object?, DateTime)>{};

  @override
  Future<void> guardar(String clave, Object? json) async => _datos[clave] = (json, DateTime.now());

  @override
  Future<(Object?, DateTime)?> leer(String clave) async => _datos[clave];
}
