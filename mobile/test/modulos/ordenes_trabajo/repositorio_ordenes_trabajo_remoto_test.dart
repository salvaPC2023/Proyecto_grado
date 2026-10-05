import 'package:flutter_test/flutter_test.dart';
import 'package:maintenance_app/datos/remoto/repositorio_ordenes_trabajo_remoto.dart';
import 'package:maintenance_app/dominio/modelos/orden_trabajo.dart';

import '../../compartido/dio_falso.dart';

// Respuesta del back cuando pide una OT
final otJson = {
  'id': 'ot1',
  'titulo': 'Cambiar filtro',
  'tipo_de_orden': 'OE01',
  'tecnico_asignado_id': 't1',
  'descripcion': 'Filtro de aire',
  'prioridad': 2,
  'estatus': 'cerrada',
  'estatus_equipo': true,
  'fecha_inic_planif': '2026-10-05T08:00:00',
  'fecha_fin_planif': '2026-10-05T12:00:00',
  'fecha_cierre': '2026-10-05T12:30:00',
  'ubicacion': {'id': 'ub1', 'sector': 'Planta Norte', 'subsector': null, 'sistema': null, 'subsistema': null},
  'pasos': [
    {
      'id': 'p1',
      'numero_paso': 1,
      'descripcion': 'Desmontar',
      'clave_control': 'PM01',
      'horas_planificadas': 2,
      'cierre': {
        'id': 'c1',
        'fecha_hora_notificacion': '2026-10-05T11:00:00',
        'tiempo_real_trabajado': '1.5',
        'trabajo_finalizado': true,
        'sin_trabajo_realizado': false,
        'resultado_trabajo': 'ejecutado',
        'descripcion_trabajo_realizado': 'Listo',
      },
    },
  ],
};

void main() {
  test('obtiene el detalle de una OT', () async {
    final adaptador = AdaptadorHttpFalso((_) => otJson);
    final repositorio = RepositorioOrdenesTrabajoRemoto(crearDioFalso(adaptador));

    final ot = await repositorio.obtenerDetalle('ot1');

    expect(adaptador.ultima.path, '/ordenes-trabajo/ot1');
    expect(ot.ubicacion!.sector, 'Planta Norte');
    expect(ot.pasos.single.cierre!.tiempoRealTrabajado, 1.5);
  });

  test('lista mis OTs de una fecha', () async {
    final adaptador = AdaptadorHttpFalso((_) => [otJson]);
    final repositorio = RepositorioOrdenesTrabajoRemoto(crearDioFalso(adaptador));

    final ots = await repositorio.listarMisOts(fecha: DateTime(2026, 10, 5));

    expect(ots, hasLength(1));
    expect(adaptador.ultima.queryParameters, {'fecha': '2026-10-05'});
  });

  test('lista las OTs del grupo', () async {
    final adaptador = AdaptadorHttpFalso((_) => [otJson]);
    final repositorio = RepositorioOrdenesTrabajoRemoto(crearDioFalso(adaptador));

    await repositorio.listarOtsGrupo();

    expect(adaptador.ultima.path, '/ordenes-trabajo/grupo');
  });

  test('lista las ubicaciones técnicas', () async {
    final adaptador = AdaptadorHttpFalso((_) => [otJson['ubicacion']]);
    final repositorio = RepositorioOrdenesTrabajoRemoto(crearDioFalso(adaptador));

    final ubicaciones = await repositorio.listarUbicaciones();

    expect(ubicaciones.single.sector, 'Planta Norte');
  });

  test('crea una OT enviando sus pasos', () async {
    final adaptador = AdaptadorHttpFalso((_) => otJson);
    final repositorio = RepositorioOrdenesTrabajoRemoto(crearDioFalso(adaptador));

    await repositorio.crear(
      titulo: 'Cambiar filtro',
      tipoDeOrden: 'OE01',
      ubicacionTecnicaId: 'ub1',
      tecnicoAsignadoId: 't1',
      descripcion: 'Filtro de aire',
      prioridad: 2,
      estatusEquipo: true,
      fechaInicPlanif: DateTime(2026, 10, 5, 8),
      fechaFinPlanif: DateTime(2026, 10, 5, 12),
      pasos: const [PasoNuevo(descripcion: 'Desmontar', claveControl: 'PM01', horasPlanificadas: 2)],
    );

    expect(adaptador.ultima.method, 'POST');
    expect(adaptador.ultima.data['pasos'], [
      {'descripcion': 'Desmontar', 'clave_control': 'PM01', 'horas_planificadas': 2.0},
    ]);
  });

  test('registra el cierre de un paso', () async {
    final adaptador = AdaptadorHttpFalso((_) => otJson);
    final repositorio = RepositorioOrdenesTrabajoRemoto(crearDioFalso(adaptador));

    await repositorio.registrarCierre(otId: 'ot1', pasoId: 'p1', ejecutado: false, tiempoRealTrabajado: 0, descripcion: 'Sin repuesto');

    expect(adaptador.ultima.path, '/ordenes-trabajo/ot1/pasos/p1/cierre');
    expect(adaptador.ultima.data, {
      'resultado_trabajo': 'no_ejecutado',
      'tiempo_real_trabajado': 0.0,
      'descripcion_trabajo_realizado': 'Sin repuesto',
    });
  });
}
