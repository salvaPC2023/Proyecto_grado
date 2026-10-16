import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/orden_trabajo.dart';
import '../../../nucleo/sesion.dart';
import '../../../nucleo/tema.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import '../../viewmodels/ordenes_trabajo_vm.dart';
import '../../widgets/encabezado_usuario.dart';
import '../ordenes_trabajo/pantalla_mis_ots.dart';
import '../ordenes_trabajo/pantalla_ots_grupo.dart';

class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final esSupervisor = sesion?.esSupervisor == true;
    // las mismas OTs de hoy que se ven al tocar "Ver Órdenes de Trabajo"
    final otsDeHoy = esSupervisor ? ref.watch(otsGrupoViewModelProvider) : ref.watch(misOtsViewModelProvider);

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EncabezadoUsuario(),
              const SizedBox(height: 20),
              _TarjetaProgreso(
                textoBoton: 'Ver Órdenes de Trabajo',
                esSupervisor: esSupervisor,
                ots: otsDeHoy.value ?? const [],
                cargando: otsDeHoy.isLoading,
                onVerOts: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => esSupervisor ? const PantallaOtsGrupo() : const PantallaMisOts(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SeccionAvisos(),
              const SizedBox(height: 20),
              const _SeccionComunicadoPersonal(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BarraNavegacionInferior(activo: SeccionNav.inicio),
    );
  }
}

class _TarjetaProgreso extends StatelessWidget {
  const _TarjetaProgreso({
    this.onVerOts,
    required this.textoBoton,
    required this.esSupervisor,
    required this.ots,
    required this.cargando,
  });
  final VoidCallback? onVerOts;
  final String textoBoton;
  final bool esSupervisor;
  final List<OrdenTrabajo> ots;
  final bool cargando;

  // fold suma sobre la lista, como sum() en Python
  int get _pasosTotales => ots.fold(0, (total, ot) => total + ot.pm01Total);
  int get _pasosCerrados => ots.fold(0, (total, ot) => total + ot.pm01Cerrados);
  double get _fraccion => _pasosTotales == 0 ? 0 : _pasosCerrados / _pasosTotales;

  String get _mensaje {
    if (cargando) return 'Cargando tus órdenes de hoy...';
    final pendientes = _pasosTotales - _pasosCerrados;
    if (_pasosTotales == 0) return esSupervisor ? 'Tu grupo no tiene órdenes para hoy' : 'No tienes órdenes para hoy';
    if (pendientes == 0) return esSupervisor ? '¡El grupo completó la jornada!' : '¡Completaste tu jornada!';
    if (_fraccion >= 0.75) return esSupervisor ? '¡La jornada del grupo está casi completa!' : '¡Tu jornada está casi completa!';
    if (pendientes == 1) return esSupervisor ? 'Al grupo le queda 1 paso por cerrar' : 'Te queda 1 paso por cerrar';
    return esSupervisor ? 'Al grupo le quedan $pendientes pasos por cerrar' : 'Te quedan $pendientes pasos por cerrar';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColoresApp.principal,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x261E3A8A), blurRadius: 25, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esSupervisor ? 'PROGRESO DEL GRUPO HOY' : 'PROGRESO DE HOY',
                  style: const TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _mensaje,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onVerOts,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        textoBoton,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: _fraccion, // nunca null: un indicador sin valor gira sin parar
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Text(
                  '${(_fraccion * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso {
  const _Aviso({
    required this.categoria,
    required this.colorCategoria,
    required this.icono,
    required this.titulo,
    required this.estado,
    required this.progreso,
    required this.colorProgreso,
  });
  final String categoria;
  final Color colorCategoria;
  final IconData icono;
  final String titulo;
  final String estado;
  final double progreso;
  final Color colorProgreso;
}

const _avisos = [
  _Aviso(
    categoria: 'Seguridad',
    colorCategoria: Color(0xFFF59E0B),
    icono: Icons.health_and_safety_outlined,
    titulo: 'Seguridad Industrial: Uso obligatorio de EPP en subestaciones',
    estado: 'Prioridad Alta',
    progreso: 0.7,
    colorProgreso: Color(0xFF2563EB),
  ),
  _Aviso(
    categoria: 'Mantenimiento',
    colorCategoria: Color(0xFF0284C7),
    icono: Icons.local_fire_department_outlined,
    titulo: 'Mantenimiento Preventivo Calderas: Protocolo Q2',
    estado: 'Procedimiento',
    progreso: 0.45,
    colorProgreso: Color(0xFFF59E0B),
  ),
  // agrega un tercero para probar mejor los puntitos
];

class _SeccionAvisos extends StatefulWidget {
  const _SeccionAvisos();

  @override
  State<_SeccionAvisos> createState() => _SeccionAvisosState();
}

class _SeccionAvisosState extends State<_SeccionAvisos> {
  final _controlador = PageController(viewportFraction: 0.88); // cada tarjeta ocupa el 88% del ancho y se asoma la siguiente
  int _paginaActual = 0;

  @override
  void dispose() {
    _controlador.dispose(); // los controladores se liberan igual que los TextEditingController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Tablón de anuncios',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            _BadgeMas(onTap: () {}),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 230,
          // deja que el carrusel use todo el ancho de la pantalla, sin el margen de 20,
          // para que las tarjetas no se corten contra una pared invisible al deslizar
          child: OverflowBox(
            minWidth: anchoPantalla,
            maxWidth: anchoPantalla,
            child: PageView.builder(
              controller: _controlador,
              itemCount: _avisos.length,
              onPageChanged: (pagina) => setState(() => _paginaActual = pagina),
              itemBuilder: (context, i) => Padding(
                // espacio entre tarjetas y para que no se corte la sombra
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: _TarjetaAviso(aviso: _avisos[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _avisos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                // el punto activo se alarga y toma el color principal
                width: i == _paginaActual ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _paginaActual ? ColoresApp.principal : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BadgeMas extends StatelessWidget {
  const _BadgeMas({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: const Text(
          '+',
          style: TextStyle(
            color: ColoresApp.principal,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TarjetaAviso extends StatelessWidget {
  const _TarjetaAviso({required this.aviso});
  final _Aviso aviso;

  @override
  Widget build(BuildContext context) {
    // el ancho lo decide el PageView
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(aviso.icono, size: 32, color: aviso.colorCategoria),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: aviso.colorCategoria.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    aviso.categoria,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 39,
            child: Text(
              aviso.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF8FAFC))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  aviso.estado,
                  style: const TextStyle(
                    color: ColoresApp.textoPlaceholder,
                    fontSize: 10,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: SizedBox(
                    width: 64,
                    height: 6,
                    child: LinearProgressIndicator(
                      value: aviso.progreso,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation(aviso.colorProgreso),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionComunicadoPersonal extends StatelessWidget {
  const _SeccionComunicadoPersonal();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Comunicado Personal',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            _BadgeMas(onTap: () {}),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDBEAFE)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Técnico Oscar Pérez',
                      style: TextStyle(
                        color: ColoresApp.principal,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    'Hoy 09:15',
                    style: TextStyle(
                      color: ColoresApp.textoPlaceholder,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x99EFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x99DBEAFE)),
                ),
                child: const Text(
                  '"Tu desempeño es bueno pero necesito que al completar '
                  'todas tus OTs antes de tiempo apoyes a tus compañeros '
                  'de trabajo."',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
