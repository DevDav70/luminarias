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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar luminaria')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: codigoController,
                focusNode: codigoFocusNode,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Código',
                  hintText: 'Ejemplo: CO-TI-21',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: abrirSelectorLuminaria,
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
                decoration: const InputDecoration(labelText: 'Área / Zona'),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121A2B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: buscandoUltimo
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Buscando último horómetro...'),
                        ],
                      )
                    : Text(
                        ultimoHorometro != null
                            ? 'Último horómetro registrado: ${ultimoHorometro!.toStringAsFixed(1)} h'
                            : 'No hay historial previo para este código',
                        style: TextStyle(
                          color: ultimoHorometro != null
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: horometroController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Horómetro del día',
                  hintText: ultimoHorometro != null
                      ? 'Mayor o igual a ${ultimoHorometro!.toStringAsFixed(1)}'
                      : 'Ejemplo: 1234.5',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El horómetro es obligatorio';
                  }

                  final numero = double.tryParse(value.trim());
                  if (numero == null) {
                    return 'Ingresa un número válido';
                  }

                  if (numero < 0) {
                    return 'El horómetro no puede ser negativo';
                  }

                  if (ultimoHorometro != null && numero < ultimoHorometro!) {
                    return 'No puede ser menor al último horómetro';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: estadoSeleccionado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(
                    value: 'Operativo',
                    child: Text('Operativo'),
                  ),
                  DropdownMenuItem(
                    value: 'Inoperativo',
                    child: Text('Inoperativo'),
                  ),
                  DropdownMenuItem(
                    value: 'Mantenimiento',
                    child: Text('Mantenimiento'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    estadoSeleccionado = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El estado es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: seleccionarFecha,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(fechaTexto),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: observacionController,
                textCapitalization: TextCapitalization.characters,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: guardando ? null : guardarRegistro,
                child: Text(guardando ? 'Guardando...' : 'Guardar registro'),
              ),
            ],
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
            color: Color(0xFFF3F4F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
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
                      fontWeight: FontWeight.w700,
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
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 1.2,
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
