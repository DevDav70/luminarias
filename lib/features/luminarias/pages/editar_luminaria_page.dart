import 'package:flutter/material.dart';
import '../models/luminaria_model.dart';
import '../services/luminaria_service.dart';

class EditarLuminariaPage extends StatefulWidget {
  final LuminariaModel luminaria;

  const EditarLuminariaPage({super.key, required this.luminaria});

  @override
  State<EditarLuminariaPage> createState() => _EditarLuminariaPageState();
}

class _EditarLuminariaPageState extends State<EditarLuminariaPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController codigoController;
  late final TextEditingController zonaController;
  late final TextEditingController horometroController;
  late final TextEditingController observacionController;

  late String estadoSeleccionado;
  late DateTime fechaSeleccionada;

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    codigoController = TextEditingController(
      text: widget.luminaria.codigo.toUpperCase(),
    );
    zonaController = TextEditingController(
      text: widget.luminaria.areaZona.toUpperCase(),
    );
    horometroController = TextEditingController(
      text: widget.luminaria.horometro.toString(),
    );
    observacionController = TextEditingController(
      text: widget.luminaria.observacion.toUpperCase(),
    );

    estadoSeleccionado = _normalizarEstado(widget.luminaria.estado);
    fechaSeleccionada = widget.luminaria.fechaRegistro;
  }

  String _normalizarEstado(String estado) {
    final valor = estado.trim().toUpperCase();

    switch (valor) {
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

  @override
  void dispose() {
    codigoController.dispose();
    zonaController.dispose();
    horometroController.dispose();
    observacionController.dispose();
    super.dispose();
  }

  Future<void> seleccionarFecha() async {
    final picked = await showDatePicker(
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
    final d = fechaSeleccionada.day.toString().padLeft(2, '0');
    final m = fechaSeleccionada.month.toString().padLeft(2, '0');
    final y = fechaSeleccionada.year.toString();
    return '$d/$m/$y';
  }

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.luminaria.id == null) return;

    setState(() {
      guardando = true;
    });

    try {
      final luminariaActualizada = LuminariaModel(
        id: widget.luminaria.id,
        codigo: codigoController.text.trim().toUpperCase(),
        areaZona: zonaController.text.trim().toUpperCase(),
        horometro: double.parse(horometroController.text.trim()),
        estado: estadoSeleccionado.toUpperCase(),
        fechaRegistro: fechaSeleccionada,
        observacion: observacionController.text.trim().toUpperCase(),
        createdAt: widget.luminaria.createdAt,
      );

      await LuminariaService.actualizarLuminaria(
        widget.luminaria.id!,
        luminariaActualizada,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Luminaria actualizada correctamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
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
      appBar: AppBar(title: const Text('Editar luminaria')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: codigoController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Código'),
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
              TextFormField(
                controller: horometroController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Horómetro'),
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
              ElevatedButton.icon(
                onPressed: guardando ? null : guardarCambios,
                icon: const Icon(Icons.save),
                label: Text(guardando ? 'Guardando...' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
