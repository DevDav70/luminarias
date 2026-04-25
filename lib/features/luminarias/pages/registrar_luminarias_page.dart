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

  List<LuminariaModel> sugerencias = [];
  bool mostrandoSugerencias = false;
  bool cargandoSugerencias = false;

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

  Future<void> cargarSugerencias(String texto) async {
    final buscar = texto.trim();

    if (buscar.isEmpty) {
      setState(() {
        sugerencias = [];
        mostrandoSugerencias = false;
        cargandoSugerencias = false;
        ultimoHorometro = null;
      });
      return;
    }

    setState(() {
      cargandoSugerencias = true;
      mostrandoSugerencias = true;
    });

    try {
      final lista = await LuminariaService.sugerenciasPorCodigo(buscar);

      if (!mounted) return;

      setState(() {
        sugerencias = lista;
        mostrandoSugerencias = lista.isNotEmpty;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        sugerencias = [];
        mostrandoSugerencias = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          cargandoSugerencias = false;
        });
      }
    }
  }

  Future<void> seleccionarSugerencia(LuminariaModel item) async {
    codigoController.text = item.codigo.toUpperCase();
    zonaController.text = item.areaZona.toUpperCase();

    setState(() {
      estadoSeleccionado = _normalizarEstado(item.estado);
      mostrandoSugerencias = false;
      sugerencias = [];
    });

    await cargarUltimoRegistroPorCodigo(item.codigo);
  }

  Future<bool> confirmarDuplicadoSiExiste() async {
    final existe = await LuminariaService.existeRegistroEnFecha(
      codigo: codigoController.text,
      fecha: fechaSeleccionada,
    );

    if (!existe) return true;

    if (!mounted) return false;

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
                /// 🔴 ICONO
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFFF5A36),
                    size: 42,
                  ),
                ),

                const SizedBox(height: 18),

                /// 🧠 TITULO
                const Text(
                  'Registro duplicado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 10),

                /// 📄 TEXTO
                const Text(
                  'Esta luminaria ya fue registrada en esta fecha.\n\n¿Deseas registrarla de todas formas?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 22),

                /// 🔘 BOTONES
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
                          backgroundColor: const Color(0xFF4D81EA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Registrar igual',
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
      sugerencias = [];
      mostrandoSugerencias = false;
      estadoSeleccionado = 'Operativo';
      fechaSeleccionada = DateTime.now();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        codigoFocusNode.requestFocus();
      }
    });
  }

  Future<void> guardarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      guardando = true;
      mostrandoSugerencias = false;
    });

    try {
      final continuar = await confirmarDuplicadoSiExiste();

      if (!continuar) {
        if (!mounted) return;
        setState(() {
          guardando = false;
        });
        return;
      }

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

  Widget _buildSugerenciasCodigo() {
    if (!mostrandoSugerencias) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9D3CC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: cargandoSugerencias
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Buscando sugerencias...'),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sugerencias.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = sugerencias[index];

                return ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: Text(
                    item.codigo.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  subtitle: Text(
                    item.areaZona.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => seleccionarSugerencia(item),
                );
              },
            ),
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          mostrandoSugerencias = false;
        });
      },
      child: Scaffold(
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
                      suffixIcon: codigoController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                setState(() {
                                  codigoController.clear();
                                  zonaController.clear();
                                  horometroController.clear();
                                  observacionController.clear();
                                  ultimoHorometro = null;
                                  sugerencias = [];
                                  mostrandoSugerencias = false;
                                });
                              },
                            ),
                    ),
                    onChanged: (value) async {
                      final mayuscula = value.toUpperCase();

                      if (value != mayuscula) {
                        codigoController.value = codigoController.value
                            .copyWith(
                              text: mayuscula,
                              selection: TextSelection.collapsed(
                                offset: mayuscula.length,
                              ),
                            );
                      }

                      await cargarSugerencias(mayuscula);
                    },
                    onFieldSubmitted: (_) async {
                      setState(() {
                        mostrandoSugerencias = false;
                      });

                      await cargarUltimoRegistroPorCodigo(
                        codigoController.text,
                      );
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El código es obligatorio';
                      }
                      return null;
                    },
                  ),

                  _buildSugerenciasCodigo(),

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
                                    padding: EdgeInsets.only(
                                      left: 4,
                                      bottom: 8,
                                    ),
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
                                      if (value == null ||
                                          value.trim().isEmpty) {
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
                                    padding: EdgeInsets.only(
                                      left: 4,
                                      bottom: 8,
                                    ),
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
      ),
    );
  }
}
