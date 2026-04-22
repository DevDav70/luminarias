import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/luminaria_model.dart';
import 'editar_luminaria_page.dart';

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
      final hoy = DateTime.now();
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
      final texto =
          DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'es').format(date);
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

      dataLimpia.sort((a, b) {
        final campoA = obtenerCampoFecha(a);
        final campoB = obtenerCampoFecha(b);

        final fechaA = campoA.isEmpty ? '' : _fechaClave(a[campoA]);
        final fechaB = campoB.isEmpty ? '' : _fechaClave(b[campoB]);

        return fechaB.compareTo(fechaA);
      });

      if (!mounted) return;
      setState(() {
        todosRegistros = dataLimpia;
        registrosFiltrados = dataLimpia;
        fechasDisponibles = fechasOrdenadas;
        fechaSeleccionada = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar registros: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
      default:
        return const Color(0xFF64748B);
    }
  }

  String obtenerUbicacion(Map<String, dynamic> item) {
    return _safeText(item['area'] ?? item['zona'] ?? item['frente'])
        .toUpperCase();
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

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 380;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F4EF),
        elevation: 0,
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
            fontWeight: FontWeight.w800,
            fontSize: isSmall ? 20 : 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: cargarRegistros,
            icon: const Icon(Icons.refresh_rounded),
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateChips(isSmall),
                  const SizedBox(height: 14),
                  _buildSummaryCard(isSmall),
                  const SizedBox(height: 16),
                  registrosFiltrados.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No hay registros para esa fecha',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : _buildGroupedList(isSmall),
                ],
              ),
            ),
    );
  }

  Widget _buildDateChips(bool isSmall) {
    return SizedBox(
      height: isSmall ? 116 : 124,
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
      child: Container(
        width: isSmall ? 110 : 122,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 12,
          vertical: isSmall ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F2747) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF0F2747) : const Color(0xFFE7E5E4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              size: isSmall ? 22 : 24,
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
      child: Container(
        width: isSmall ? 100 : 108,
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isSmall ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF16A34A) : const Color(0xFFE7E5E4),
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
    final total = registrosFiltrados.length;
    final operativos = registrosFiltrados
        .where((e) => _safeText(e['estado']).toUpperCase() == 'OPERATIVO')
        .length;
    final inoperativos = registrosFiltrados
        .where((e) => _safeText(e['estado']).toUpperCase() == 'INOPERATIVO')
        .length;

    String ultimoRegistro = '--:--';
    if (registrosFiltrados.isNotEmpty) {
      final campoFecha = obtenerCampoFecha(registrosFiltrados.first);
      if (campoFecha.isNotEmpty) {
        ultimoRegistro = _horaVisual(registrosFiltrados.first[campoFecha]);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                width: isSmall ? 54 : 62,
                height: isSmall ? 54 : 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registros del día',
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          '$total',
                          style: TextStyle(
                            fontSize: isSmall ? 22 : 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'encontrados',
                          style: TextStyle(
                            fontSize: isSmall ? 13 : 14,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryMini(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Operativos',
                  value: '$operativos',
                  extra: total > 0
                      ? '${((operativos / total) * 100).round()}%'
                      : '0%',
                  color: const Color(0xFF16A34A),
                  bg: const Color(0xFFEEF7FF),
                  isSmall: isSmall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryMini(
                  icon: Icons.cancel_outlined,
                  label: 'Inoperativos',
                  value: '$inoperativos',
                  extra: total > 0
                      ? '${((inoperativos / total) * 100).round()}%'
                      : '0%',
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFFEEEE),
                  isSmall: isSmall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryMini(
                  icon: Icons.schedule_rounded,
                  label: 'Último',
                  value: ultimoRegistro,
                  extra: 'Hoy',
                  color: const Color(0xFF7C3AED),
                  bg: const Color(0xFFF2EBFF),
                  isSmall: isSmall,
                  smallText: true,
                ),
              ),
            ],
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
    return Column(
      children: [
        Container(
          width: isSmall ? 46 : 52,
          height: isSmall ? 46 : 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: isSmall ? 22 : 26),
        ),
        const SizedBox(height: 8),
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
            fontSize: smallText ? (isSmall ? 14 : 16) : (isSmall ? 22 : 24),
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
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
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
              fontWeight: FontWeight.w600,
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
          width: isSmall ? 36 : 40,
          height: isSmall ? 36 : 40,
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
    final icon = obtenerIcono(item);
    final horometro = item['horometro'];

    final campoFecha = obtenerCampoFecha(item);
    final hora = campoFecha.isEmpty ? '--:--' : _horaVisual(item[campoFecha]);

    return GestureDetector(
      onTap: () => _editarRegistro(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
              height: isSmall ? 90 : 96,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: isSmall ? 58 : 68,
              height: isSmall ? 58 : 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F1),
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
                      _estadoBadge(estado.toUpperCase(), color, isSmall),
                      _horaChip(hora, isSmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_rounded,
              color: const Color(0xFF64748B),
              size: isSmall ? 20 : 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoBadge(String estado, Color color, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 14,
        vertical: isSmall ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isSmall) {
    return Row(
      children: [
        Icon(
          icon,
          size: isSmall ? 17 : 18,
          color: const Color(0xFF64748B),
        ),
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