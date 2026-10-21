import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/comunicado.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/sesion.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/comunicados_vm.dart';
import 'componentes_comunicados.dart';
import 'pantalla_nuevo_comunicado.dart';

/// Comunicados generales del grupo, en un carrusel
class SeccionTablon extends ConsumerWidget {
  const SeccionTablon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esSupervisor = ref.watch(sesionProvider)?.esSupervisor ?? false;
    return _Seccion(
      titulo: 'Tablón de anuncios',
      personal: false,
      esSupervisor: esSupervisor,
      vacio: esSupervisor ? 'No publicaste anuncios vigentes. Toca + para publicar uno.' : 'No hay anuncios vigentes.',
      contenido: (comunicados) => _Carrusel(comunicados: comunicados),
    );
  }
}

/// Comunicados personales: los dirigidos al técnico, o los que el supervisor envió a sus técnicos
class SeccionComunicadosPersonales extends ConsumerWidget {
  const SeccionComunicadosPersonales({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esSupervisor = ref.watch(sesionProvider)?.esSupervisor ?? false;
    return _Seccion(
      titulo: 'Comunicado Personal',
      personal: true,
      esSupervisor: esSupervisor,
      vacio: esSupervisor ? 'No enviaste comunicados personales vigentes.' : 'No tienes comunicados personales.',
      contenido: (comunicados) => Column(
        children: [
          for (final c in comunicados)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TarjetaPersonal(comunicado: c, esSupervisor: esSupervisor),
            ),
        ],
      ),
    );
  }
}

/// Título con su botón +, y los comunicados del tipo indicado con sus estados de carga, error y vacío
class _Seccion extends ConsumerWidget {
  const _Seccion({
    required this.titulo,
    required this.personal,
    required this.esSupervisor,
    required this.vacio,
    required this.contenido,
  });

  final String titulo;
  final bool personal;
  final bool esSupervisor;
  final String vacio;
  final Widget Function(List<Comunicado>) contenido;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(comunicadosViewModelProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // flexible: con la letra grande del celular el título se corta en lugar de desbordar
            Flexible(
              child: Text(
                titulo,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            if (esSupervisor)
              BotonNuevoComunicado(
                descripcion: personal ? 'Nuevo comunicado personal' : 'Nuevo comunicado para el grupo',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PantallaNuevoComunicado(personal: personal)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        estado.when(
          // sin indicador que gire: un espacio liso mientras cargan
          loading: () => const _Aviso(texto: 'Cargando…'),
          error: (error, _) => _Aviso(
            texto: mensajeDeError(error),
            accion: TextButton(
              onPressed: () => ref.read(comunicadosViewModelProvider.notifier).recargar(),
              child: const Text('Reintentar'),
            ),
          ),
          data: (todos) {
            final comunicados = todos.where((c) => c.personal == personal).toList();
            return comunicados.isEmpty ? _Aviso(texto: vacio) : contenido(comunicados);
          },
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, this.accion});
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 13)),
          ?accion,
        ],
      ),
    );
  }
}

class _Carrusel extends StatefulWidget {
  const _Carrusel({required this.comunicados});
  final List<Comunicado> comunicados;

  @override
  State<_Carrusel> createState() => _CarruselState();
}

class _CarruselState extends State<_Carrusel> {
  // cada tarjeta ocupa el 88% del ancho y se asoma la siguiente
  final _controlador = PageController(viewportFraction: 0.88);
  int _paginaActual = 0;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comunicados = widget.comunicados;
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    // si se retiró el último comunicado, la página actual ya no existe
    final pagina = _paginaActual.clamp(0, comunicados.length - 1);
    return Column(
      children: [
        SizedBox(
          height: 230,
          // el carrusel usa todo el ancho de la pantalla, sin el margen de 20,
          // para que las tarjetas no se corten contra una pared invisible al deslizar
          child: OverflowBox(
            minWidth: anchoPantalla,
            maxWidth: anchoPantalla,
            child: PageView.builder(
              controller: _controlador,
              itemCount: comunicados.length,
              onPageChanged: (nueva) => setState(() => _paginaActual = nueva),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: _TarjetaTablon(comunicado: comunicados[i]),
              ),
            ),
          ),
        ),
        if (comunicados.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < comunicados.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == pagina ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == pagina ? ColoresApp.principal : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TarjetaTablon extends StatelessWidget {
  const _TarjetaTablon({required this.comunicado});
  final Comunicado comunicado;

  @override
  Widget build(BuildContext context) {
    final c = comunicado;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => mostrarDetalleComunicado(context, c),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      c.tieneImagen
                          ? ImagenComunicado(comunicadoId: c.id)
                          : ColoredBox(
                              color: c.categoria.color.withValues(alpha: 0.08),
                              child: Icon(c.categoria.icono, size: 36, color: c.categoria.color),
                            ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.categoria.color.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.categoria.etiqueta,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 39,
                child: Text(
                  c.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cuandoSeEnvio(c.fechaEnvio),
                      style: const TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 10),
                    ),
                  ),
                  Text(venceEl(c.fechaExpiracion), style: const TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaPersonal extends StatelessWidget {
  const _TarjetaPersonal({required this.comunicado, required this.esSupervisor});
  final Comunicado comunicado;
  final bool esSupervisor;

  @override
  Widget build(BuildContext context) {
    final c = comunicado;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => mostrarDetalleComunicado(context, c),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(c.categoria.icono, size: 14, color: c.categoria.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      esSupervisor ? 'Para ${c.destinatarioNombre ?? ''}' : 'De ${c.autorNombre}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ColoresApp.principal, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    cuandoSeEnvio(c.fechaEnvio),
                    style: const TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(c.titulo, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x99EFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x99DBEAFE)),
                ),
                child: Text(
                  c.texto ?? 'Imagen adjunta. Toca para verla.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
