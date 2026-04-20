import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/luminaria_model.dart';
import '../services/luminaria_service.dart';
import '../services/excel_luminarias_service.dart';
import '../widgets/luminaria_card.dart';
import 'detalle_luminaria_page.dart';

class RegistrosPage extends StatefulWidget {
  const RegistrosPage({super.key});

  @override
  State<RegistrosPage> createState() => _RegistrosPageState();
}

class _RegistrosPageState extends State<RegistrosPage> {
  late Future<List<LuminariaModel>> futureRegistros;
  bool exportando = false;

  @override
  void initState() {
    super.initState();
    cargarRegistros();
  }

  void cargarRegistros() {
    futureRegistros = LuminariaService.obtenerLuminarias();
  }

  String formatearFecha(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year.toString();
    return '$d/$m/$y';
  }

  Future<void> refrescar() async {
    setState(() {
      cargarRegistros();
    });
  }

  Future<void> exportarExcel() async {
    try {
      setState(() {
        exportando = true;
      });

      final registros = await LuminariaService.obtenerLuminarias();

      if (registros.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay registros para exportar')),
        );
        return;
      }

      final ruta = await ExcelLuminariasService.exportarLuminariasConDialogo(
        registros,
      );

      if (!mounted) return;

      if (ruta == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Exportación cancelada')));
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel guardado en: $ruta')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    } finally {
      if (mounted) {
        setState(() {
          exportando = false;
        });
      }
    }
  }

  Future<bool?> confirmarEliminacion(BuildContext context) async {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Eliminar',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Eliminar registro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '¿Seguro que deseas eliminar esta luminaria?',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 16,
                          height: 1.4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              borderRadius: BorderRadius.circular(18),
                              color: Colors.white.withOpacity(0.08),
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              borderRadius: BorderRadius.circular(18),
                              color: Colors.red.withOpacity(0.85),
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: const Text(
                                'Eliminar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> eliminarRegistro(LuminariaModel item) async {
    if (item.id == null) return;

    try {
      await LuminariaService.eliminarLuminaria(item.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro eliminado correctamente')),
      );

      refrescar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  Widget fondoEliminar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.90),
            Colors.redAccent.withOpacity(0.70),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      alignment: Alignment.centerRight,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 26),
          SizedBox(width: 8),
          Text(
            'Eliminar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros'),
        actions: [
          exportando
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: exportarExcel,
                  icon: const Icon(Icons.download),
                ),
        ],
      ),
      body: FutureBuilder<List<LuminariaModel>>(
        future: futureRegistros,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(decoration: TextDecoration.none),
              ),
            );
          }

          final registros = snapshot.data ?? [];

          if (registros.isEmpty) {
            return const Center(
              child: Text(
                'No hay registros de luminarias',
                style: TextStyle(decoration: TextDecoration.none),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refrescar,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final item = registros[index];

                return Dismissible(
                  key: ValueKey(item.id ?? '${item.codigo}_$index'),
                  direction: DismissDirection.endToStart,
                  background: fondoEliminar(),
                  confirmDismiss: (_) async {
                    return await confirmarEliminacion(context);
                  },
                  onDismissed: (_) async {
                    await eliminarRegistro(item);
                  },
                  child: LuminariaCard(
                    codigo: item.codigo,
                    zona: item.areaZona,
                    horometro: item.horometro,
                    estado: item.estado,
                    fecha: formatearFecha(item.fechaRegistro),
                    onTap: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleLuminariaPage(luminaria: item),
                        ),
                      );

                      if (resultado == true) {
                        await refrescar();
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
