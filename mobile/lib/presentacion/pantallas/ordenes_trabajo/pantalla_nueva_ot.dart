import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dominio/modelos/orden_trabajo.dart';
import '../../../dominio/modelos/tecnico.dart';
import '../../../nucleo/errores.dart';
import '../../../nucleo/tema.dart';
import '../../viewmodels/ordenes_trabajo_vm.dart';
import '../../viewmodels/tecnicos_vm.dart';
import '../../widgets/barra_navegacion_inferior.dart';
import 'formato_ot.dart';

class PantallaNuevaOt extends ConsumerStatefulWidget {
  const PantallaNuevaOt({super.key});

  @override
  ConsumerState<PantallaNuevaOt> createState() => _PantallaNuevaOtState();
}

const _tiposDeOrden = ['OE01', 'OE02', 'OE03', 'OE04'];
const _profesiones = {
  'electrico': 'Eléctrico',
  'mecanico': 'Mecánico',
  'electromecanico': 'Electromecánico',
};

class _PantallaNuevaOtState extends ConsumerState<PantallaNuevaOt> {
  final _controladorTitulo = TextEditingController();
  final _controladorDescripcion = TextEditingController();

  String _tipoDeOrden = _tiposDeOrden.first;
  UbicacionTecnica? _ubicacion;
  String? _profesionFiltro;
  String? _tecnicoId;
  bool _equipoEnFuncionamiento = false;
  late DateTime _inicio;
  late DateTime _fin;
  int _prioridad = 3;
  final List<PasoNuevo> _pasos = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _inicio = DateTime(ahora.year, ahora.month, ahora.day, ahora.hour + 1);
    _fin = _inicio.add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorDescripcion.dispose();
    super.dispose();
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _elegirUbicacion(List<UbicacionTecnica> ubicaciones) async {
    final elegida = await showModalBottomSheet<UbicacionTecnica>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SelectorUbicacion(ubicaciones: ubicaciones),
    );
    if (elegida != null) setState(() => _ubicacion = elegida);
  }

  Future<DateTime?> _elegirFechaHora(DateTime actual) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (fecha == null || !mounted) return null;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(actual),
      helpText: 'Hora',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (hora == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  Future<void> _agregarPaso() async {
    final paso = await showDialog<PasoNuevo>(
      context: context,
      builder: (_) => const _DialogoPaso(),
    );
    if (paso != null) setState(() => _pasos.add(paso));
  }

  Future<void> _crear() async {
    final titulo = _controladorTitulo.text.trim();
    final descripcion = _controladorDescripcion.text.trim();
    if (titulo.isEmpty || descripcion.isEmpty) {
      return _avisar('Completa el título y la descripción');
    }
    if (_ubicacion == null) return _avisar('Selecciona una ubicación técnica');
    if (_tecnicoId == null) return _avisar('Selecciona el técnico asignado');
    if (_fin.isBefore(_inicio)) {
      return _avisar('La fecha de fin no puede ser anterior a la de inicio');
    }
    if (!_pasos.any((p) => p.claveControl == 'PM01')) {
      return _avisar('Se requiere al menos un paso PM01');
    }

    setState(() => _guardando = true);
    try {
      final ot = await ref.read(nuevaOtViewModelProvider.notifier).crear(
            titulo: titulo,
            tipoDeOrden: _tipoDeOrden,
            ubicacionTecnicaId: _ubicacion!.id,
            tecnicoAsignadoId: _tecnicoId!,
            descripcion: descripcion,
            prioridad: _prioridad,
            estatusEquipo: _equipoEnFuncionamiento,
            fechaInicPlanif: _inicio,
            fechaFinPlanif: _fin,
            pasos: _pasos,
          );
      if (!mounted) return;
      ref.invalidate(otsGrupoViewModelProvider);
      _avisar('OT "${ot.titulo}" creada con ${ot.pasos.length} pasos');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _avisar(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ubicaciones = ref.watch(nuevaOtViewModelProvider);
    final tecnicos = ref.watch(tecnicosViewModelProvider);

    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: SafeArea(
        child: Column(
          children: [
            _Encabezado(onVolver: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Tarjeta(
                      titulo: 'Tipo de orden',
                      child: Row(
                        children: [
                          for (final tipo in _tiposDeOrden)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _BotonOpcion(
                                  texto: tipo,
                                  seleccionado: tipo == _tipoDeOrden,
                                  onTap: () => setState(() => _tipoDeOrden = tipo),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _Tarjeta(
                      titulo: 'Datos de la orden',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CampoTexto(
                            controlador: _controladorTitulo,
                            indicativo: 'Título (ej. Sobrecalentamiento de transformador)',
                            maxLength: 150,
                          ),
                          const SizedBox(height: 10),
                          _CampoTexto(
                            controlador: _controladorDescripcion,
                            indicativo: 'Descripción del trabajo',
                            lineas: 3,
                          ),
                        ],
                      ),
                    ),
                    _Tarjeta(
                      titulo: 'Ubicación técnica',
                      accion: ubicaciones.hasValue
                          ? TextButton.icon(
                              onPressed: () => _elegirUbicacion(ubicaciones.value!),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(Icons.chevron_right),
                              label: Text(_ubicacion == null ? 'Elegir' : 'Cambiar'),
                            )
                          : null,
                      child: ubicaciones.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => _ErrorConReintento(
                          mensaje: mensajeDeError(e),
                          onReintentar: ref.read(nuevaOtViewModelProvider.notifier).recargar,
                        ),
                        data: (lista) => _ubicacion == null
                            ? _Vacio(
                                texto: 'Toca para elegir entre ${lista.length} ubicaciones',
                                onTap: () => _elegirUbicacion(lista),
                              )
                            : _DetalleUbicacion(ubicacion: _ubicacion!),
                      ),
                    ),
                    _Tarjeta(
                      titulo: 'Grupo planificador (profesión)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Desplegable<String?>(
                            icono: Icons.settings_outlined,
                            valor: _profesionFiltro,
                            opciones: {null: 'Todas las profesiones', ..._profesiones},
                            onCambiar: (p) => setState(() {
                              _profesionFiltro = p;
                              _tecnicoId = null;
                            }),
                          ),
                          const SizedBox(height: 14),
                          const _Subtitulo('Técnico asignado'),
                          tecnicos.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => _ErrorConReintento(
                              mensaje: mensajeDeError(e),
                              onReintentar:
                                  ref.read(tecnicosViewModelProvider.notifier).recargar,
                            ),
                            data: (lista) => _selectorTecnico(lista),
                          ),
                          const SizedBox(height: 14),
                          const _Subtitulo('Estado del equipo'),
                          _Desplegable<bool>(
                            icono: Icons.power_settings_new,
                            valor: _equipoEnFuncionamiento,
                            opciones: const {
                              false: 'Detenido para intervención',
                              true: 'En funcionamiento',
                            },
                            onCambiar: (v) =>
                                setState(() => _equipoEnFuncionamiento = v ?? false),
                          ),
                        ],
                      ),
                    ),
                    _Tarjeta(
                      titulo: 'Planificación',
                      child: Row(
                        children: [
                          Expanded(
                            child: _BotonFecha(
                              etiqueta: 'Inicio',
                              fecha: _inicio,
                              onTap: () async {
                                final f = await _elegirFechaHora(_inicio);
                                if (f == null) return;
                                setState(() {
                                  final duracion = _fin.difference(_inicio);
                                  _inicio = f;
                                  if (_fin.isBefore(_inicio)) _fin = _inicio.add(duracion);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BotonFecha(
                              etiqueta: 'Fin',
                              fecha: _fin,
                              onTap: () async {
                                final f = await _elegirFechaHora(_fin);
                                if (f != null) setState(() => _fin = f);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Tarjeta(
                      titulo: 'Prioridad',
                      child: Row(
                        children: [
                          for (final entrada in etiquetasPrioridad.entries)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _BotonOpcion(
                                  texto: entrada.value,
                                  seleccionado: entrada.key == _prioridad,
                                  color: estiloPrioridad(entrada.key).color,
                                  onTap: () => setState(() => _prioridad = entrada.key),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Pasos de mantenimiento',
                          style: TextStyle(
                            color: ColoresApp.textoOscuro,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChipEtiqueta(
                          estilo: EstiloEtiqueta(
                            '${_pasos.length}',
                            ColoresApp.principal,
                            ColoresApp.badgeBorde,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _AvisoPasosSeguridad(),
                    const SizedBox(height: 10),
                    for (var i = 0; i < _pasos.length; i++)
                      _TarjetaPaso(
                        paso: _pasos[i],
                        onQuitar: () => setState(() => _pasos.removeAt(i)),
                      ),
                    _BotonAgregarPaso(onTap: _agregarPaso),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _guardando ? null : _crear,
                        style: FilledButton.styleFrom(
                          backgroundColor: ColoresApp.principal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Crear Orden de Trabajo',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BarraNavegacionInferior(activo: SeccionNav.agenda),
    );
  }

  Widget _selectorTecnico(List<Tecnico> todos) {
    final disponibles = todos
        .where((t) => t.activo)
        .where((t) => _profesionFiltro == null || t.profesion == _profesionFiltro)
        .toList();
    if (disponibles.isEmpty) {
      return const _Vacio(texto: 'No hay técnicos activos con esa profesión');
    }
    return _Desplegable<String?>(
      icono: Icons.person_outline,
      valor: _tecnicoId,
      indicativo: 'Selecciona un técnico',
      opciones: {
        for (final t in disponibles)
          t.id: '${t.nombreCompleto} (${_profesiones[t.profesion] ?? t.profesion})',
      },
      onCambiar: (id) => setState(() => _tecnicoId = id),
    );
  }
}


class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.onVolver});
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onVolver,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back, color: ColoresApp.textoOscuro),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Nueva Orden de Trabajo',
            style: TextStyle(
              color: ColoresApp.textoOscuro,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.child, this.accion});
  final String titulo;
  final Widget child;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x0F1E3A8A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _Subtitulo(titulo, abajo: 0)),
              ?accion,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Subtitulo extends StatelessWidget {
  const _Subtitulo(this.texto, {this.abajo = 8});
  final String texto;
  final double abajo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: abajo),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: ColoresApp.textoSuave,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  const _BotonOpcion({
    required this.texto,
    required this.seleccionado,
    required this.onTap,
    this.color = ColoresApp.principal,
  });
  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: seleccionado ? color : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              texto,
              style: TextStyle(
                color: seleccionado ? Colors.white : ColoresApp.textoSuave,
                fontSize: 14,
                fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({
    required this.controlador,
    required this.indicativo,
    this.lineas = 1,
    this.maxLength,
  });
  final TextEditingController controlador;
  final String indicativo;
  final int lineas;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      minLines: lineas,
      maxLines: lineas,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: indicativo,
        hintStyle: const TextStyle(color: ColoresApp.textoPlaceholder, fontSize: 14),
        counterText: '',
        filled: true,
        fillColor: ColoresApp.campoFondo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColoresApp.campoBorde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColoresApp.campoBorde),
        ),
      ),
    );
  }
}

class _Desplegable<T> extends StatelessWidget {
  const _Desplegable({
    required this.icono,
    required this.valor,
    required this.opciones,
    required this.onCambiar,
    this.indicativo,
  });
  final IconData icono;
  final T valor;
  final Map<T, String> opciones;
  final ValueChanged<T?> onCambiar;
  final String? indicativo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ColoresApp.campoFondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColoresApp.campoBorde),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: ColoresApp.principal),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: opciones.containsKey(valor) ? valor : null,
                isExpanded: true,
                hint: indicativo == null ? null : Text(indicativo!),
                items: [
                  for (final e in opciones.entries)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onCambiar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleUbicacion extends StatelessWidget {
  const _DetalleUbicacion({required this.ubicacion});
  final UbicacionTecnica ubicacion;

  @override
  Widget build(BuildContext context) {
    final niveles = {
      'Sector': ubicacion.sector,
      'Subsector': ubicacion.subsector,
      'Sistema': ubicacion.sistema,
      'Subsistema': ubicacion.subsistema,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresApp.badgeBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: ColoresApp.principal, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JERARQUÍA DE ACTIVO',
                      style: TextStyle(
                        color: ColoresApp.principal,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ubicacion.ruta,
                      style: const TextStyle(
                        color: ColoresApp.textoOscuro,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.6,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final n in niveles.entries)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        n.key.toUpperCase(),
                        style: const TextStyle(
                          color: ColoresApp.textoPlaceholder,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        n.value ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ColoresApp.textoOscuro,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectorUbicacion extends StatefulWidget {
  const _SelectorUbicacion({required this.ubicaciones});
  final List<UbicacionTecnica> ubicaciones;

  @override
  State<_SelectorUbicacion> createState() => _SelectorUbicacionState();
}

class _SelectorUbicacionState extends State<_SelectorUbicacion> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final filtro = _busqueda.toLowerCase();
    final visibles = widget.ubicaciones
        .where((u) => u.ruta.toLowerCase().contains(filtro))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, controlador) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColoresApp.campoBorde,
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: InputDecoration(
                hintText: 'Buscar ubicación (sector, sistema...)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: ColoresApp.campoFondo,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: ColoresApp.campoBorde),
                ),
              ),
            ),
          ),
          Expanded(
            child: visibles.isEmpty
                ? const Center(child: Text('Sin resultados'))
                : ListView.separated(
                    controller: controlador,
                    itemCount: visibles.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = visibles[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: ColoresApp.principal,
                        ),
                        title: Text(
                          u.nombreCorto,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(u.ruta),
                        onTap: () => Navigator.of(context).pop(u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BotonFecha extends StatelessWidget {
  const _BotonFecha({required this.etiqueta, required this.fecha, required this.onTap});
  final String etiqueta;
  final DateTime fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Subtitulo('$etiqueta planificado', abajo: 6),
        Material(
          color: ColoresApp.campoFondo,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ColoresApp.campoBorde),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: ColoresApp.principal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatoFecha(fecha),
                          style: const TextStyle(
                            color: ColoresApp.principal,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          formatoHora(fecha),
                          style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvisoPasosSeguridad extends StatelessWidget {
  const _AvisoPasosSeguridad();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresApp.badgeFondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColoresApp.badgeBorde),
      ),
      child: const Row(
        children: [
          Icon(Icons.health_and_safety_outlined, color: ColoresApp.principal),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Los 3 pasos de seguridad (PMNN) se agregan automáticamente '
              'como pasos 1 a 3. Agrega aquí los pasos de mantenimiento: al '
              'menos uno debe ser PM01 con horas planificadas.',
              style: TextStyle(color: ColoresApp.textoLabel, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPaso extends StatelessWidget {
  const _TarjetaPaso({required this.paso, required this.onQuitar});
  final PasoNuevo paso;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final esPm01 = paso.claveControl == 'PM01';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0F1E3A8A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ChipEtiqueta(
            estilo: esPm01
                ? const EstiloEtiqueta('PM01', Colors.white, ColoresApp.principal)
                : const EstiloEtiqueta('PMNN', ColoresApp.principal, ColoresApp.badgeFondo),
            conBorde: !esPm01,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paso.descripcion,
                  style: const TextStyle(
                    color: ColoresApp.textoOscuro,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (esPm01)
                  Text(
                    formatoHoras(paso.horasPlanificadas ?? 0),
                    style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar paso',
            onPressed: onQuitar,
            icon: const Icon(Icons.delete_outline, color: ColoresApp.textoPlaceholder),
          ),
        ],
      ),
    );
  }
}

class _BotonAgregarPaso extends StatelessWidget {
  const _BotonAgregarPaso({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add),
      label: const Text('Agregar paso de mantenimiento'),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresApp.principal,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: ColoresApp.chipProfesionBorde, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }
}

class _DialogoPaso extends StatefulWidget {
  const _DialogoPaso();

  @override
  State<_DialogoPaso> createState() => _DialogoPasoState();
}

class _DialogoPasoState extends State<_DialogoPaso> {
  final _descripcion = TextEditingController();
  final _horas = TextEditingController();
  String _clave = 'PM01';
  String? _error;

  @override
  void dispose() {
    _descripcion.dispose();
    _horas.dispose();
    super.dispose();
  }

  void _aceptar() {
    final descripcion = _descripcion.text.trim();
    if (descripcion.isEmpty) {
      return setState(() => _error = 'Escribe la descripción del paso');
    }
    double? horas;
    if (_clave == 'PM01') {
      horas = double.tryParse(_horas.text.trim().replaceAll(',', '.'));
      if (horas == null || horas <= 0) {
        return setState(() => _error = 'Los pasos PM01 requieren horas mayores a 0');
      }
    }
    Navigator.of(context).pop(
      PasoNuevo(descripcion: descripcion, claveControl: _clave, horasPlanificadas: horas),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo paso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'PM01', label: Text('PM01'), icon: Icon(Icons.build)),
              ButtonSegment(value: 'PMNN', label: Text('PMNN'), icon: Icon(Icons.info_outline)),
            ],
            selected: {_clave},
            onSelectionChanged: (s) => setState(() {
              _clave = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _clave == 'PM01'
                ? 'Mantenimiento: lleva horas planificadas y el técnico lo cierra.'
                : 'Informativo: solo descripción, no se cierra.',
            style: const TextStyle(color: ColoresApp.textoSuave, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descripcion,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          if (_clave == 'PM01')
            TextField(
              controller: _horas,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Horas planificadas'),
              onSubmitted: (_) => _aceptar(),
            ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFE11D48), fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _aceptar, child: const Text('Agregar')),
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.texto, this.onTap});
  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColoresApp.campoFondo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColoresApp.campoBorde),
        ),
        child: Text(texto, style: const TextStyle(color: ColoresApp.textoSuave)),
      ),
    );
  }
}

class _ErrorConReintento extends StatelessWidget {
  const _ErrorConReintento({required this.mensaje, required this.onReintentar});
  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(mensaje, style: const TextStyle(color: Color(0xFFE11D48))),
        ),
        TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
      ],
    );
  }
}
