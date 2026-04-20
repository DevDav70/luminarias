import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/luminaria_model.dart';
import '../services/luminaria_service.dart';
import 'editar_luminaria_page.dart';

class DetalleLuminariaPage extends StatefulWidget {
  final LuminariaModel luminaria;

  const DetalleLuminariaPage({super.key, required this.luminaria});

  @override
  State<DetalleLuminariaPage> createState() => _DetalleLuminariaPageState();
}

class _DetalleLuminariaPageState extends State<DetalleLuminariaPage> {
  late LuminariaModel luminariaActual;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    luminariaActual = widget.luminaria;
  }

  Color getEstadoColor(String estado) {
    final valor = estado.trim().toUpperCase();

    switch (valor) {
      case 'OPERATIVO':
        return AppTheme.success;
      case 'INOPERATIVO':
        return AppTheme.danger;
      case 'MANTENIMIENTO':
        return AppTheme.warning;
      default:
        return Colors.grey;
    }
  }

  String formatearFecha(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year.toString();
    return '$d/$m/$y';
  }

  Future<void> recargarDetalle() async {
    if (luminariaActual.id == null) return;

    try {
      final nuevaData = await LuminariaService.obtenerPorId(
        luminariaActual.id!,
      );

      if (nuevaData != null && mounted) {
        setState(() {
          luminariaActual = nuevaData;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al recargar: $e')));
    }
  }

  Future<void> cargarDetalleInicial() async {
    if (luminariaActual.id == null) return;

    setState(() {
      cargando = true;
    });

    try {
      final nuevaData = await LuminariaService.obtenerPorId(
        luminariaActual.id!,
      );

      if (nuevaData != null && mounted) {
        setState(() {
          luminariaActual = nuevaData;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar detalle: $e')));
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> eliminar(BuildContext context) async {
    try {
      if (luminariaActual.id == null) return;

      await LuminariaService.eliminarLuminaria(luminariaActual.id!);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro eliminado')));

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  Future<void> editarLuminaria() async {
    final actualizado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarLuminariaPage(luminaria: luminariaActual),
      ),
    );

    if (actualizado == true) {
      await recargarDetalle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = getEstadoColor(luminariaActual.estado);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de luminaria')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: recargarDetalle,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          luminariaActual.codigo.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          luminariaActual.areaZona.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Horómetro: ${luminariaActual.horometro.toStringAsFixed(1)} h',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: estadoColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            luminariaActual.estado.toUpperCase(),
                            style: TextStyle(
                              color: estadoColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatearFecha(luminariaActual.fechaRegistro),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Observación',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          luminariaActual.observacion.trim().isEmpty
                              ? 'Sin observación'
                              : luminariaActual.observacion.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          onPressed: editarLuminaria,
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: AppTheme.danger,
                          ),
                          onPressed: () => eliminar(context),
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
