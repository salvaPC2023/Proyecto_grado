import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/sesion.dart';
import '../../../nucleo/tema.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import '../autenticacion/pantalla_inicio_sesion.dart';
import '../ordenes_trabajo/pantalla_mis_ots.dart';
import '../ordenes_trabajo/pantalla_ots_grupo.dart';
import '../perfil/pantalla_mi_perfil.dart';
import '../supervisores/pantalla_lista_supervisores.dart';


class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final nombreUsuario = sesion?.nombreCompleto ?? '';
    final esAdministrador = sesion?.esAdministrador == true;
    final rol = esAdministrador
        ? 'Administrador'
        : sesion?.esSupervisor == true
            ? 'Supervisor'
            : 'Técnico';

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Encabezado(
                nombreUsuario: nombreUsuario,
                rol: rol,
                onCerrarSesion: () {
                  ref.read(sesionProvider.notifier).cerrarSesion();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const PantallaInicioSesion()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 20),
              _TarjetaProgreso(
                textoBoton: esAdministrador ? 'Gestionar Supervisores' : 'Ver Órdenes de Trabajo',
                onVerOts: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => esAdministrador
                        ? const PantallaListaSupervisores()
                        : sesion?.esSupervisor == true
                            ? const PantallaOtsGrupo()
                            : const PantallaMisOts(),
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

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.nombreUsuario,
    required this.rol,
    required this.onCerrarSesion,
  });
  final String nombreUsuario;
  final String rol;
  final VoidCallback onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PantallaMiPerfil()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF60A5FA), width: 2),
                ),
                padding: const EdgeInsets.all(2),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: ColoresApp.textoPlaceholder),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Bienvenido!',
                style: TextStyle(
                  color: ColoresApp.textoSuave,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$rol $nombreUsuario',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(9999),
          onTap: onCerrarSesion,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Icon(Icons.logout,
                size: 20, color: ColoresApp.textoOscuro),
          ),
        ),
      ],
    );
  }
}

class _TarjetaProgreso extends StatelessWidget {
  const _TarjetaProgreso({this.onVerOts, required this.textoBoton});
  final VoidCallback? onVerOts;
  final String textoBoton;

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
                const Text(
                  'PROGRESO TOTAL',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¡Tu jornada está casi\ncompleta!',
                  style: TextStyle(
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
                    value: 0.85,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const Text(
                  '85%',
                  style: TextStyle(
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

class _SeccionAvisos extends StatelessWidget {
  const _SeccionAvisos();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Tablón de anuncios',
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
        SizedBox(
          height: 245,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _TarjetaAviso(
                categoria: 'Seguridad',
                colorCategoria: Color(0xFFF59E0B),
                icono: Icons.health_and_safety_outlined,
                titulo: 'Seguridad Industrial: Uso obligatorio de EPP en subestaciones',
                estado: 'Prioridad Alta',
                progreso: 0.7,
                colorProgreso: Color(0xFF2563EB),
              ),
              SizedBox(width: 12),
              _TarjetaAviso(
                categoria: 'Mantenimiento',
                colorCategoria: Color(0xFF0284C7),
                icono: Icons.local_fire_department_outlined,
                titulo: 'Mantenimiento Preventivo Calderas: Protocolo Q2',
                estado: 'Procedimiento',
                progreso: 0.45,
                colorProgreso: Color(0xFFF59E0B),
              ),
            ],
          ),
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
  const _TarjetaAviso({
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
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
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, size: 32, color: colorCategoria),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorCategoria.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    categoria,
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
              titulo,
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
                  estado,
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
                      value: progreso,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation(colorProgreso),
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
