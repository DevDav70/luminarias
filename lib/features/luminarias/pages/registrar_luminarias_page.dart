import 'package:flutter/material.dart';
import '../models/luminaria_model.dart';
import '../services/luminaria_service.dart';

class RegistrarLuminariaPage extends StatefulWidget {
  const RegistrarLuminariaPage({super.key});

  @override
  State<RegistrarLuminariaPage> createState() => _RegistrarLuminariaPageState();
}

class _RegistrarLuminariaPageState extends State<RegistrarLuminariaPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController codigoController = TextEditingController();
  final TextEditingController zonaController = TextEditingController();
  final TextEditingController horometroController = TextEditingController();
  final TextEditingController observacionController = TextEditingController();

  final FocusNode codigoFocusNode = FocusNode();

  String estadoSeleccionado = 'Operativo';
  DateTime fechaSeleccionada = DateTime.now();
  bool guardando = false;

  double? ultimoHorometro;
  bool buscandoUltimo = false;

  final List<String> estados = const [
    'Operativo',
    'Inoperativo',
    'Mantenimiento',
  ];

  @override
  void dispose() {
    codigoController.dispose();
    zonaController.dispose();
    horometroController.dispose();
    observacionController.dispose();
    codigoFocusNode.dispose();
    super.dispose();
  }

  Future<void> seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
      });
    }
  }

  String get fechaTexto {
    final String d = fechaSeleccionada.day.toString().padLeft(2, '0');
    final String m = fechaSeleccionada.month.toString().padLeft(2, '0');
    final String y = fechaSeleccionada.year.toString();
    return '$d/$m/$y';
  }

  String _normalizarEstado(String estado) {
    switch (estado.trim().toUpperCase()) {
      case 'OPERATIVO':
        return 'Operativo';
      case 'INOPERATIVO':
        return 'Inoperativo';
      case 'MANTENIMIENTO':
        return 'Mantenimiento';
      default:
        return 'Operativo';
    }
  }

  Future<void> cargarUltimoRegistroPorCodigo(String codigo) async {
    if (codigo.trim().isEmpty) {
      setState(() {
        ultimoHorometro = null;
      });
      return;
    }

    setState(() {
      buscandoUltimo = true;
    });

    try {
      final ultimo = await LuminariaService.obtenerUltimoPorCodigo(
        codigo.trim(),
      );

      if (!mounted) return;

      setState(() {
        ultimoHorometro = ultimo?.horometro;
      });

      if (ultimo != null) {
        zonaController.text = ultimo.areaZona.toUpperCase();
        estadoSeleccionado = _normalizarEstado(ultimo.estado);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        ultimoHorometro = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          buscandoUltimo = false;
        });
      }
    }
  }

  void limpiarFormularioParaNuevaLuminaria({String? codigoInicial}) {
    setState(() {
      codigoController.text = (codigoInicial ?? '').trim().toUpperCase();
      zonaController.clear();
      horometroController.clear();
      observacionController.clear();
      ultimoHorometro = null;
      estadoSeleccionado = 'Operativo';
      fechaSeleccionada = DateTime.now();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        codigoFocusNode.requestFocus();
      }
    });
  }

  Future<void> abrirSelectorLuminaria() async {
    final dynamic seleccionada = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SelectorLuminariaSheet(codigoInicial: codigoController.text),
    );

    if (!mounted || seleccionada == null) return;

    if (seleccionada is Map<String, dynamic> &&
        seleccionada['accion'] == 'crear') {
      final codigoEscrito = (seleccionada['codigo'] ?? '').toString();
      limpiarFormularioParaNuevaLuminaria(codigoInicial: codigoEscrito);
      return;
    }

    if (seleccionada is! LuminariaModel) return;

    codigoController.text = seleccionada.codigo.toUpperCase();
    zonaController.text = seleccionada.areaZona.toUpperCase();

    setState(() {
      estadoSeleccionado = _normalizarEstado(seleccionada.estado);
    });

    await cargarUltimoRegistroPorCodigo(seleccionada.codigo);
  }

  Future<void> guardarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      guardando = true;
    });

    try {
      final luminaria = LuminariaModel(
        codigo: codigoController.text.trim().toUpperCase(),
        areaZona: zonaController.text.trim().toUpperCase(),
        horometro: double.parse(horometroController.text.trim()),
        estado: estadoSeleccionado.toUpperCase(),
        fechaRegistro: fechaSeleccionada,
        observacion: observacionController.text.trim().toUpperCase(),
      );

      await LuminariaService.crearLuminaria(luminaria);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Luminaria registrada correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'Operativo':
        return const Color(0xFF2EAF4A);
      case 'Inoperativo':
        return const Color(0xFFFF5A36);
      case 'Mantenimiento':
        return const Color(0xFFF2B632);
      default:
        return const Color(0xFF2EAF4A);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFDFDFD),
      labelStyle: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(color: Color(0xFFB0B7C3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFD9D3CC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFD9D3CC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFF4C7CF0), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2DDD7)),
      ),
      child: child,
    );
  }

  Future<void> _mostrarSelectorEstado() async {
    final seleccionado = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F8F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Seleccionar estado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...estados.map((estado) {
                final color = _estadoColor(estado);
                final esActual = estado == estadoSeleccionado;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.pop(context, estado),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: esActual
                              ? const Color(0xFF4C7CF0)
                              : const Color(0xFFE5E7EB),
                          width: esActual ? 1.4 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.04),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              estado,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (esActual)
                            const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF4C7CF0),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (seleccionado != null) {
      setState(() {
        estadoSeleccionado = seleccionado;
      });
    }
  }

  Widget _buildEstadoSelector() {
    final color = _estadoColor(estadoSeleccionado);

    return GestureDetector(
      onTap: _mostrarSelectorEstado,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF4C7CF0), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                estadoSeleccionado,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 28,
              color: Color(0xFF1F2937),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFechaSelector() {
    return InkWell(
      onTap: seleccionarFecha,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD9D3CC)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF2563EB),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                fechaTexto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EFEB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EFEB),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF14213D),
        title: const Text(
          'Registrar luminaria',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: Color(0xFF14213D),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: codigoController,
                  focusNode: codigoFocusNode,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: 'Código',
                    hint: 'Ejemplo: CO-TI-21',
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EFEB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD9D3CC)),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF14213D),
                          size: 30,
                        ),
                        onPressed: abrirSelectorLuminaria,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.trim().isEmpty) {
                      setState(() {
                        ultimoHorometro = null;
                      });
                    }
                  },
                  onFieldSubmitted: (_) async {
                    await cargarUltimoRegistroPorCodigo(codigoController.text);
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El código es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: zonaController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: 'Área / Zona',
                    hint: 'Ejemplo: PATIO NORTE',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El área / zona es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF13233E), Color(0xFF0F1B30)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: buscandoUltimo
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.1,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Buscando último horómetro...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF203D72),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: Color(0xFF8EB2FF),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                ultimoHorometro != null
                                    ? 'Último horómetro registrado\n${ultimoHorometro!.toStringAsFixed(1)} h'
                                    : 'No hay historial previo para este código',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                _buildCard(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    'Horómetro del día',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4B5563),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextFormField(
                                  controller: horometroController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _inputDecoration(
                                    label: '',
                                    hint: ultimoHorometro != null
                                        ? 'Mayor o igual a ${ultimoHorometro!.toStringAsFixed(1)}'
                                        : 'Ej. 1250.0',
                                    prefixIcon: const Icon(
                                      Icons.speed_rounded,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El horómetro es obligatorio';
                                    }

                                    final numero = double.tryParse(
                                      value.trim(),
                                    );
                                    if (numero == null) {
                                      return 'Ingresa un número válido';
                                    }

                                    if (numero < 0) {
                                      return 'El horómetro no puede ser negativo';
                                    }

                                    if (ultimoHorometro != null &&
                                        numero < ultimoHorometro!) {
                                      return 'No puede ser menor al último horómetro';
                                    }

                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    'Estado',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4B5563),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _buildEstadoSelector(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Fecha',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      _buildFechaSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: observacionController,
                  textCapitalization: TextCapitalization.characters,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    label: 'Observación (opcional)',
                    hint: 'Escribe alguna observación...',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4D81EA), Color(0xFF5B8EF1)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4D81EA).withOpacity(.28),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: guardando ? null : guardarRegistro,
                      icon: const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        guardando ? 'Guardando...' : 'Guardar registro',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorLuminariaSheet extends StatefulWidget {
  final String codigoInicial;

  const _SelectorLuminariaSheet({required this.codigoInicial});

  @override
  State<_SelectorLuminariaSheet> createState() =>
      _SelectorLuminariaSheetState();
}

class _SelectorLuminariaSheetState extends State<_SelectorLuminariaSheet> {
  final TextEditingController buscarController = TextEditingController();

  List<LuminariaModel> resultados = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    buscarController.text = widget.codigoInicial;
    buscar(widget.codigoInicial);
  }

  Future<void> buscar(String texto) async {
    setState(() {
      cargando = true;
    });

    try {
      final lista = texto.trim().isEmpty
          ? await LuminariaService.obtenerLuminarias()
          : await LuminariaService.buscarPorCodigo(texto);

      final Map<String, LuminariaModel> unicos = {};
      for (final item in lista) {
        unicos[item.codigo.toUpperCase()] = item;
      }

      final listaFinal = unicos.values.toList()
        ..sort(
          (a, b) => a.codigo.toUpperCase().compareTo(b.codigo.toUpperCase()),
        );

      setState(() {
        resultados = listaFinal;
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F8F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Seleccionar luminaria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: buscarController,
                  onChanged: buscar,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Buscar por código',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF2D6CDF),
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: cargando
                    ? const Center(child: CircularProgressIndicator())
                    : resultados.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                        child: Column(
                          children: [
                            const Text(
                              'No se encontró la luminaria',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context, {
                                    'accion': 'crear',
                                    'codigo': buscarController.text,
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Crear nueva luminaria'),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: resultados.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == resultados.length) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.pop(context, {
                                  'accion': 'crear',
                                  'codigo': buscarController.text,
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: Color(0xFF2563EB),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Crear nueva luminaria',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final item = resultados[index];

                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.pop(context, item);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5EDFF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.lightbulb_outline,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.codigo.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
