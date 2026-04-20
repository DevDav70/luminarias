import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lumi_app/features/luminarias/pages/registrar_luminarias_page.dart';
import '../../../core/theme/app_theme.dart';
import '../services/luminaria_service.dart';
import '../widgets/stat_card.dart';
import 'registros_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int total = 0;
  int operativas = 0;
  int inoperativas = 0;
  int mantenimiento = 0;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      final lista = await LuminariaService.obtenerLuminarias();

      int op = 0;
      int ino = 0;
      int man = 0;

      for (final item in lista) {
        final estado = item.estado.trim().toUpperCase();

        if (estado == 'OPERATIVO') op++;
        if (estado == 'INOPERATIVO') ino++;
        if (estado == 'MANTENIMIENTO') man++;
      }

      if (!mounted) return;

      setState(() {
        total = lista.length;
        operativas = op;
        inoperativas = ino;
        mantenimiento = man;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
    }
  }

  Future<void> refrescarHome() async {
    await cargarDatos();
  }

  Future<void> irARegistrar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrarLuminariaPage()),
    );

    if (resultado == true) {
      await cargarDatos();
    }
  }

  Future<void> irARegistros() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrosPage()),
    );

    await cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Luminarias'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: false,
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF8F4EC),
                    Color(0xFFF2ECE2),
                    Color(0xFFECE5DA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -70,
                    left: -50,
                    child: _blurCircle(
                      size: 220,
                      color: const Color(0xFFDCE7FF),
                      opacity: 0.75,
                    ),
                  ),
                  Positioned(
                    top: 180,
                    right: -60,
                    child: _blurCircle(
                      size: 190,
                      color: const Color(0xFFFFE2D2),
                      opacity: 0.65,
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: -40,
                    child: _blurCircle(
                      size: 210,
                      color: const Color(0xFFE2F6E8),
                      opacity: 0.60,
                    ),
                  ),
                  Positioned(
                    bottom: 180,
                    right: 30,
                    child: _blurCircle(
                      size: 120,
                      color: const Color(0xFFFBE7B2),
                      opacity: 0.45,
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(color: Colors.white.withOpacity(0.06)),
                  ),
                  RefreshIndicator(
                    onRefresh: refrescarHome,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 8),
                        StatCard(
                          title: 'Total luminarias',
                          value: total.toString(),
                          icon: Icons.lightbulb_outline,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 14),
                        StatCard(
                          title: 'Operativas',
                          value: operativas.toString(),
                          icon: Icons.check_circle_outline,
                          color: AppTheme.success,
                        ),
                        const SizedBox(height: 14),
                        StatCard(
                          title: 'Inoperativas',
                          value: inoperativas.toString(),
                          icon: Icons.cancel_outlined,
                          color: AppTheme.danger,
                        ),
                        const SizedBox(height: 14),
                        StatCard(
                          title: 'Mantenimiento',
                          value: mantenimiento.toString(),
                          icon: Icons.build_circle_outlined,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(height: 28),
                        _glassActionButton(
                          text: 'Registrar luminaria',
                          icon: Icons.add,
                          filled: true,
                          onTap: irARegistrar,
                        ),
                        const SizedBox(height: 12),
                        _glassActionButton(
                          text: 'Ver registros',
                          icon: Icons.list_alt,
                          filled: false,
                          onTap: irARegistros,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _glassActionButton({
    required String text,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: filled
              ? const Color(0xFF7DA3FA).withOpacity(0.82)
              : Colors.white.withOpacity(0.38),
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: filled
                      ? Colors.white.withOpacity(0.18)
                      : Colors.white.withOpacity(0.55),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: filled ? Colors.white : AppTheme.textPrimary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: TextStyle(
                      color: filled ? Colors.white : AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  static Widget _blurCircle({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      ),
    );
  }
}
