import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/luminaria_model.dart';
import 'editar_luminaria_page.dart';
import '../services/excel_luminarias_service.dart';

class RegistrosPage extends StatefulWidget {
  const RegistrosPage({super.key});

  @override
  State<RegistrosPage> createState() => _RegistrosPageState();
}

class _RegistrosPageState extends State<RegistrosPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> todosRegistros = [];
  List<Map<String, dynamic>> registrosFiltrados = [];
  List<String> fechasDisponibles = [];

  String? fechaSeleccionada;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarRegistros();
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String obtenerCampoFecha(Map<String, dynamic> item) {
    if (item['created_at'] != null) return 'created_at';
    if (item['fecha_registro'] != null) return 'fecha_registro';
    return '';
  }

  DateTime _parseFechaRegistro(Map<String, dynamic> item) {
    final campoFecha = obtenerCampoFecha(item);
    if (campoFecha.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final valor = item[campoFecha];
    if (valor == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    try {
      return DateTime.parse(valor.toString()).toLocal();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String _fechaClave(dynamic fecha) {
    if (fecha == null) return '';
    try {
      final date = DateTime.parse(fecha.toString()).toLocal();
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      return '';
    }
  }

  String _fechaVisualChip(String fechaClave) {
    try {
      final date = DateTime.parse(fechaClave);

      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final ayer = hoy.subtract(const Duration(days: 1));

      final hoyKey = DateFormat('yyyy-MM-dd').format(hoy);
      final ayerKey = DateFormat('yyyy-MM-dd').format(ayer);

      if (fechaClave == hoyKey) return 'Hoy';
      if (fechaClave == ayerKey) return 'Ayer';

      return DateFormat('dd MMM', 'es').format(date);
    } catch (_) {
      return fechaClave;
    }
  }

  String _fechaVisualLarga(String fechaClave) {
    try {
      final date = DateTime.parse(fechaClave);
      final texto = DateFormat(
        "EEEE, d 'de' MMMM 'de' yyyy",
        'es',
      ).format(date);
      if (texto.isEmpty) return fechaClave;
      return texto[0].toUpperCase() + texto.substring(1);
    } catch (_) {
      return fechaClave;
    }
  }

  String _horaVisual(dynamic fecha) {
    if (fecha == null) return '--:--';
    try {
      final date = DateTime.parse(fecha.toString()).toLocal();
      return DateFormat('hh:mm a', 'es').format(date);
    } catch (_) {
      return '--:--';
    }
  }

  List<Map<String, dynamic>> obtenerUltimaLuminariaPorCodigo(
    List<Map<String, dynamic>> registros,
  ) {
    final Map<String, Map<String, dynamic>> unicos = {};

    for (final item in registros) {
      final codigo = _safeText(item['codigo'], fallback: '').toUpperCase();
      if (codigo.isEmpty) continue;

      if (!unicos.containsKey(codigo)) {
        unicos[codigo] = item;
      } else {
        final fechaNueva = _parseFechaRegistro(item);
        final fechaActual = _parseFechaRegistro(unicos[codigo]!);

        if (fechaNueva.isAfter(fechaActual)) {
          unicos[codigo] = item;
        }
      }
    }

    final lista = unicos.values.toList()
      ..sort(
        (a, b) => _parseFechaRegistro(b).compareTo(_parseFechaRegistro(a)),
      );

    return lista;
  }

  Future<void> cargarRegistros() async {
    setState(() => loading = true);

    try {
      final response = await supabase.from('luminarias').select();
      final data = List<Map<String, dynamic>>.from(response);

      if (data.isEmpty) {
        if (!mounted) return;
        setState(() {
          todosRegistros = [];
          registrosFiltrados = [];
          fechasDisponibles = [];
          fechaSeleccionada = null;
          loading = false;
        });
        return;
      }

      final dataLimpia = data.where((item) {
        final codigo = _safeText(item['codigo'], fallback: '');
        final estado = _safeText(item['estado'], fallback: '');
        final campoFecha = obtenerCampoFecha(item);
        return codigo.isNotEmpty && estado.isNotEmpty && campoFecha.isNotEmpty;
      }).toList();

      final fechas = <String>{};

      for (final item in dataLimpia) {
        final campoFecha = obtenerCampoFecha(item);
        final key = _fechaClave(item[campoFecha]);
        if (key.isNotEmpty) {
          fechas.add(key);
        }
      }

      final fechasOrdenadas = fechas.toList()..sort((a, b) => b.compareTo(a));

      dataLimpia.sort(
        (a, b) => _parseFechaRegistro(b).compareTo(_parseFechaRegistro(a)),
      );

      if (!mounted) return;
      setState(() {
        todosRegistros = dataLimpia;
        registrosFiltrados = dataLimpia;
        fechasDisponibles = fechasOrdenadas;
        fechaSeleccionada = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar registros: $e')));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> exportarExcel() async {
    try {
      final luminarias = registrosFiltrados
          .map((item) => LuminariaModel.fromMap(item))
          .toList();

      if (luminarias.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay registros para exportar')),
        );
        return;
      }

      final ruta = await ExcelLuminariasService.exportarLuminariasConDialogo(
        luminarias,
      );

      if (!mounted) return;

      if (ruta == null || ruta.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Exportación cancelada')));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel exportado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al exportar Excel: $e')));
    }
  }

  void filtrarPorFecha(String fecha) {
    setState(() {
      fechaSeleccionada = fecha;
      registrosFiltrados = todosRegistros.where((item) {
        final campoFecha = obtenerCampoFecha(item);
        if (campoFecha.isEmpty) return false;
        return _fechaClave(item[campoFecha]) == fecha;
      }).toList();
    });
  }

  void mostrarTodos() {
    setState(() {
      fechaSeleccionada = null;
      registrosFiltrados = todosRegistros;
    });
  }

  Color estadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'OPERATIVO':
        return const Color(0xFF16A34A);
      case 'INOPERATIVO':
        return const Color(0xFFDC2626);
      case 'MANTENIMIENTO':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color estadoBgColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'OPERATIVO':
        return const Color(0xFFEAF7EE);
      case 'INOPERATIVO':
        return const Color(0xFFFDECEC);
      case 'MANTENIMIENTO':
        return const Color(0xFFFFF4DE);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String obtenerUbicacion(Map<String, dynamic> item) {
    return _safeText(
      item['area_zona'] ?? item['area'] ?? item['zona'] ?? item['frente'],
    ).toUpperCase();
  }

  IconData obtenerIcono(Map<String, dynamic> item) {
    final codigo = _safeText(item['codigo'], fallback: '').toUpperCase();

    if (codigo.contains('EX')) return Icons.construction_rounded;
    if (codigo.contains('CA')) return Icons.local_shipping_rounded;
    if (codigo.contains('TI')) return Icons.precision_manufacturing_rounded;
    if (codigo.contains('MO')) return Icons.agriculture_rounded;
    if (codigo.contains('RO')) return Icons.settings_rounded;

    return Icons.miscellaneous_services_rounded;
  }

  Map<String, List<Map<String, dynamic>>> agruparPorFecha(
    List<Map<String, dynamic>> registros,
  ) {
    final grupos = <String, List<Map<String, dynamic>>>{};

    for (final item in registros) {
      final campoFecha = obtenerCampoFecha(item);
      if (campoFecha.isEmpty) continue;

      final fecha = item[campoFecha];
      if (fecha == null) continue;

      final key = _fechaClave(fecha);
      if (key.isEmpty) continue;

      final codigo = _safeText(item['codigo'], fallback: '');
      final estado = _safeText(item['estado'], fallback: '');

      if (codigo.isEmpty || estado.isEmpty) continue;

      grupos.putIfAbsent(key, () => []);
      grupos[key]!.add(item);
    }

    final keys = grupos.keys.toList()..sort((a, b) => b.compareTo(a));

    final ordered = <String, List<Map<String, dynamic>>>{};
    for (final key in keys) {
      if (grupos[key] != null && grupos[key]!.isNotEmpty) {
        ordered[key] = grupos[key]!;
      }
    }
    return ordered;
  }

  Future<void> _editarRegistro(Map<String, dynamic> item) async {
    try {
      final luminaria = LuminariaModel.fromMap(item);

      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditarLuminariaPage(luminaria: luminaria),
        ),
      );

      if (resultado == true && mounted) {
        cargarRegistros();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la edición: $e')),
      );
    }
  }

  Future<bool> _confirmarEliminarRegistro(Map<String, dynamic> item) async {
    final codigo = _safeText(item['codigo'], fallback: 'SIN CÓDIGO');

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECEC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Color(0xFFDC2626),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Eliminar registro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '¿Estás seguro de eliminar el registro de\n$codigo?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return confirmar ?? false;
  }

  Future<bool> _eliminarRegistro(Map<String, dynamic> item) async {
    final id = item['id']?.toString();

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar: ID no encontrado')),
      );
      return false;
    }

    try {
      await supabase.from('luminarias').delete().eq('id', id);

      if (!mounted) return false;

      setState(() {
        todosRegistros.removeWhere((e) => e['id']?.toString() == id);
        registrosFiltrados.removeWhere((e) => e['id']?.toString() == id);

        final fechas = <String>{};

        for (final registro in todosRegistros) {
          final campoFecha = obtenerCampoFecha(registro);
          if (campoFecha.isNotEmpty) {
            final key = _fechaClave(registro[campoFecha]);
            if (key.isNotEmpty) fechas.add(key);
          }
        }

        fechasDisponibles = fechas.toList()..sort((a, b) => b.compareTo(a));

        if (fechaSeleccionada != null &&
            !fechasDisponibles.contains(fechaSeleccionada)) {
          fechaSeleccionada = null;
          registrosFiltrados = todosRegistros;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro eliminado correctamente')),
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));

      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 380;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F2EC),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF0F172A),
        ),
        title: Text(
          'Registros',
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: isSmall ? 20 : 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: exportarExcel,
            icon: const Icon(Icons.download_rounded),
            color: const Color(0xFF0F172A),
          ),
          IconButton(
            onPressed: cargarRegistros,
            icon: const Icon(Icons.refresh_rounded),
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: loading
            ? Center(
                key: const ValueKey('loading'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: Color(0xFF102D57),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Cargando registros...',
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: isSmall ? 13 : 14,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                key: const ValueKey('content'),
                onRefresh: cargarRegistros,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateChips(isSmall),
                      const SizedBox(height: 16),
                      _buildSummaryCard(isSmall),
                      const SizedBox(height: 18),
                      registrosFiltrados.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No hay registros para esa fecha',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : _buildGroupedList(isSmall),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDateChips(bool isSmall) {
    return SizedBox(
      height: isSmall ? 118 : 128,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildAllChip(isSmall),
          const SizedBox(width: 12),
          ...fechasDisponibles.map(
            (fecha) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildDateChip(
                fecha: fecha,
                isSelected: fechaSeleccionada == fecha,
                isSmall: isSmall,
                onTap: () => filtrarPorFecha(fecha),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllChip(bool isSmall) {
    final selected = fechaSeleccionada == null;

    return GestureDetector(
      onTap: mostrarTodos,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isSmall ? 112 : 122,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 12,
          vertical: isSmall ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF102D57) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? const Color(0xFF102D57) : const Color(0xFFE7E5E4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: selected ? Colors.white : const Color(0xFF0F172A),
              size: isSmall ? 24 : 26,
            ),
            const SizedBox(height: 8),
            Text(
              'Todos',
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: isSmall ? 16 : 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip({
    required String fecha,
    required bool isSelected,
    required bool isSmall,
    required VoidCallback onTap,
  }) {
    final date = DateTime.tryParse(fecha);
    final day = date != null ? DateFormat('dd').format(date) : '--';
    final month = date != null ? DateFormat('MMM', 'es').format(date) : '';
    final label = _fechaVisualChip(fecha);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isSmall ? 102 : 110,
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isSmall ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A34A)
                : const Color(0xFFE7E5E4),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              day,
              style: TextStyle(
                fontSize: isSmall ? 26 : 30,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              month,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isSmall) {
    final List<Map<String, dynamic>> baseResumen = fechaSeleccionada == null
        ? todosRegistros
        : registrosFiltrados;

    final luminariasUnicas = obtenerUltimaLuminariaPorCodigo(baseResumen);

    final total = luminariasUnicas.length;
    final operativos = luminariasUnicas
        .where((e) => _safeText(e['estado']).toUpperCase() == 'OPERATIVO')
        .length;
    final inoperativos = luminariasUnicas
        .where((e) => _safeText(e['estado']).toUpperCase() == 'INOPERATIVO')
        .length;
    final mantenimiento = luminariasUnicas
        .where((e) => _safeText(e['estado']).toUpperCase() == 'MANTENIMIENTO')
        .length;

    String ultimoRegistro = '--:--';
    if (luminariasUnicas.isNotEmpty) {
      final campoFecha = obtenerCampoFecha(luminariasUnicas.first);
      if (campoFecha.isNotEmpty) {
        ultimoRegistro = _horaVisual(luminariasUnicas.first[campoFecha]);
      }
    }

    final tituloResumen = fechaSeleccionada == null
        ? 'Luminarias únicas'
        : 'Luminarias del día';

    final subtituloResumen = fechaSeleccionada == null
        ? 'sin duplicados'
        : 'únicas registradas';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(isSmall ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: isSmall ? 58 : 68,
                height: isSmall ? 58 : 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF16A34A),
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloResumen,
                      style: TextStyle(
                        fontSize: isSmall ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$total',
                          style: TextStyle(
                            fontSize: isSmall ? 26 : 30,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            subtituloResumen,
                            style: TextStyle(
                              fontSize: isSmall ? 13 : 14,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryMini(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Operativas',
                  value: '$operativos',
                  extra: total > 0
                      ? '${((operativos / total) * 100).round()}%'
                      : '0%',
                  color: const Color(0xFF16A34A),
                  bg: const Color(0xFFEAF7EE),
                  isSmall: isSmall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMini(
                  icon: Icons.cancel_outlined,
                  label: 'Inoperativas',
                  value: '$inoperativos',
                  extra: total > 0
                      ? '${((inoperativos / total) * 100).round()}%'
                      : '0%',
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFDECEC),
                  isSmall: isSmall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMini(
                  icon: Icons.build_circle_outlined,
                  label: 'En mant.',
                  value: '$mantenimiento',
                  extra: total > 0
                      ? '${((mantenimiento / total) * 100).round()}%'
                      : '0%',
                  color: const Color(0xFFF59E0B),
                  bg: const Color(0xFFFFF4DE),
                  isSmall: isSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Última actualización: $ultimoRegistro',
              style: TextStyle(
                fontSize: isSmall ? 12 : 13,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMini({
    required IconData icon,
    required String label,
    required String value,
    required String extra,
    required Color color,
    required Color bg,
    required bool isSmall,
    bool smallText = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 6 : 8),
      child: Column(
        children: [
          Container(
            width: isSmall ? 50 : 56,
            height: isSmall ? 50 : 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: isSmall ? 24 : 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: smallText ? (isSmall ? 14 : 17) : (isSmall ? 22 : 25),
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            extra,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(bool isSmall) {
    final grupos = agruparPorFecha(registrosFiltrados);

    if (grupos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No hay fechas válidas para mostrar',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final widgets = <Widget>[];

    grupos.forEach((fecha, items) {
      widgets.add(_buildDateSectionHeader(fecha, items.length, isSmall));
      widgets.add(const SizedBox(height: 12));

      for (final item in items) {
        widgets.add(_buildRegistroCard(item, isSmall));
      }

      widgets.add(const SizedBox(height: 18));
    });

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: widgets,
    );
  }

  Widget _buildDateSectionHeader(String fecha, int total, bool isSmall) {
    return Row(
      children: [
        Container(
          width: isSmall ? 38 : 42,
          height: isSmall ? 38 : 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.calendar_today_rounded,
            size: isSmall ? 18 : 20,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _fechaVisualLarga(fecha),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmall ? 17 : 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 14,
            vertical: isSmall ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$total registros',
            style: TextStyle(
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w800,
              fontSize: isSmall ? 12 : 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistroCard(Map<String, dynamic> item, bool isSmall) {
    final codigo = _safeText(item['codigo'], fallback: '');
    final estado = _safeText(item['estado'], fallback: '');

    if (codigo.isEmpty || estado.isEmpty) {
      return const SizedBox.shrink();
    }

    final ubicacion = obtenerUbicacion(item);
    final color = estadoColor(estado.toUpperCase());
    final colorBg = estadoBgColor(estado.toUpperCase());
    final icon = obtenerIcono(item);
    final horometro = item['horometro'];

    final campoFecha = obtenerCampoFecha(item);
    final hora = campoFecha.isEmpty ? '--:--' : _horaVisual(item[campoFecha]);

    return Dismissible(
      key: ValueKey(item['id']?.toString() ?? '${codigo}_${hora}_$horometro'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmar = await _confirmarEliminarRegistro(item);
        if (!confirmar) return false;

        final eliminado = await _eliminarRegistro(item);
        return eliminado;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.centerRight,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 30),
            SizedBox(height: 4),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _editarRegistro(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isSmall ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: isSmall ? 96 : 102,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: isSmall ? 60 : 72,
                height: isSmall ? 60 : 72,
                decoration: BoxDecoration(
                  color: colorBg.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF0F2747),
                  size: isSmall ? 28 : 34,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      codigo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmall ? 18 : 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.place_outlined, ubicacion, isSmall),
                    if (horometro != null) ...[
                      const SizedBox(height: 6),
                      _infoRow(
                        Icons.schedule_rounded,
                        'Horómetro: $horometro h',
                        isSmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _estadoBadge(
                          estado.toUpperCase(),
                          color,
                          colorBg,
                          isSmall,
                        ),
                        _horaChip(hora, isSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: isSmall ? 34 : 38,
                height: isSmall ? 34 : 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: const Color(0xFF64748B),
                  size: isSmall ? 18 : 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estadoBadge(String estado, Color color, Color bg, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 14,
        vertical: isSmall ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: isSmall ? 12 : 13,
        ),
      ),
    );
  }

  Widget _horaChip(String hora, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 10 : 12,
        vertical: isSmall ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 16,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            hora,
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isSmall) {
    return Row(
      children: [
        Icon(icon, size: isSmall ? 17 : 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmall ? 14 : 15,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
