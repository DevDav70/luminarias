import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumi_app/features/luminarias/pages/registrar_luminarias_page.dart';

import '../models/luminaria_model.dart';
import '../services/luminaria_service.dart';
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
  DateTime? ultimaActualizacion;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  List<LuminariaModel> _obtenerUltimaLuminariaPorCodigo(
    List<LuminariaModel> lista,
  ) {
    final Map<String, LuminariaModel> unicos = {};

    for (final item in lista) {
      final codigo = item.codigo.trim().toUpperCase();
      if (codigo.isEmpty) continue;

      if (!unicos.containsKey(codigo)) {
        unicos[codigo] = item;
      } else {
        final actual = unicos[codigo]!;

        final fechaNueva = item.fechaRegistro;
        final fechaActual = actual.fechaRegistro;

        if (fechaNueva.isAfter(fechaActual)) {
          unicos[codigo] = item;
        }
      }
    }

    final resultado = unicos.values.toList()
      ..sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));

    return resultado;
  }

  Future<void> cargarDatos() async {
    try {
      final lista = await LuminariaService.obtenerLuminarias();

      final luminariasUnicas = _obtenerUltimaLuminariaPorCodigo(lista);

      int op = 0;
      int ino = 0;
      int man = 0;

      for (final item in luminariasUnicas) {
        final estado = item.estado.trim().toUpperCase();

        if (estado == 'OPERATIVO') op++;
        if (estado == 'INOPERATIVO') ino++;
        if (estado == 'MANTENIMIENTO') man++;
      }

      if (!mounted) return;

      setState(() {
        total = luminariasUnicas.length;
        operativas = op;
        inoperativas = ino;
        mantenimiento = man;
        ultimaActualizacion =
            luminariasUnicas.isNotEmpty ? luminariasUnicas.first.fechaRegistro : null;
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

  double get porcentajeOperativas {
    if (total == 0) return 0;
    return (operativas / total) * 100;
  }

  double get porcentajeInoperativas {
    if (total == 0) return 0;
    return (inoperativas / total) * 100;
  }

  double get porcentajeMantenimiento {
    if (total == 0) return 0;
    return (mantenimiento / total) * 100;
  }

  String get fechaHoyTexto {
    final ahora = DateTime.now();
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${ahora.day} de ${meses[ahora.month - 1]}, ${ahora.year}';
  }

  String get horaActualizada {
    final fecha = ultimaActualizacion ?? DateTime.now();
    return DateFormat('hh:mm a', 'es').format(fecha).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: refrescarHome,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  children: [
                    _buildTopCard(isSmall),
                    _buildMainContainer(isSmall),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopCard(bool isSmall) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF4E79FF), Color(0xFF2F56F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3563F6).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LUMIAPP',
                  style: TextStyle(
                    fontSize: isSmall ? 15 : 17,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF13265E),
                    height: 1,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Control de Luminarias',
                  style: TextStyle(
                    fontSize: isSmall ? 10.5 : 11.5,
                    color: const Color(0xFF7B84A3),
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContainer(bool isSmall) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: EdgeInsets.fromLTRB(
        isSmall ? 18 : 22,
        22,
        isSmall ? 18 : 22,
        22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingAndDate(isSmall),
          const SizedBox(height: 22),
          _buildHeroCard(isSmall),
          const SizedBox(height: 18),
          _buildStatsSection(),
          const SizedBox(height: 18),
          const Text(
            'Acciones rápidas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF13265E),
            ),
          ),
          const SizedBox(height: 14),
          _buildActionCard(
            title: 'Registrar luminaria',
            subtitle: 'Agrega una nueva luminaria al sistema',
            icon: Icons.add_rounded,
            iconBg: const Color(0xFF3563F6),
            cardColor: const Color(0xFFF1F5FF),
            arrowColor: const Color(0xFF3563F6),
            onTap: irARegistrar,
          ),
          const SizedBox(height: 14),
          _buildActionCard(
            title: 'Ver registros',
            subtitle: 'Consulta el historial de luminarias registradas',
            icon: Icons.format_list_bulleted_rounded,
            iconBg: const Color(0xFF7B4DFF),
            cardColor: const Color(0xFFF5F0FF),
            arrowColor: const Color(0xFF7B4DFF),
            titleColor: const Color(0xFF7B4DFF),
            onTap: irARegistros,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildGreetingAndDate(bool isSmall) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, Administrador! 👋',
                style: TextStyle(
                  fontSize: isSmall ? 23 : 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF13265E),
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Resumen operativo del sistema',
                style: TextStyle(
                  fontSize: isSmall ? 15 : 16,
                  color: const Color(0xFF6B7696),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 19,
                color: Color(0xFF3563F6),
              ),
              const SizedBox(width: 12),
              Text(
                fechaHoyTexto,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF22305F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF8C97B3),
                size: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(bool isSmall) {
    return Container(
      height: isSmall ? 250 : 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF4E79FF), Color(0xFF3E62F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3563F6).withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 24,
              right: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total reales',
                    style: TextStyle(
                      fontSize: isSmall ? 16 : 18,
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: isSmall ? 74 : 90,
                      height: 0.88,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Luminarias',
                    style: TextStyle(
                      fontSize: isSmall ? 24 : 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Actualizado $horaActualizada',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.98),
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(right: 26, top: 36, child: _buildLampIllustration()),
            Positioned(
              right: 40,
              bottom: 66,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.82),
                    width: 8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.white.withOpacity(0.96),
                    size: 40,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 56,
                child: CustomPaint(painter: _SoftWavePainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLampIllustration() {
    return SizedBox(
      width: 140,
      height: 170,
      child: Stack(
        children: [
          Positioned(
            right: 22,
            top: 0,
            child: Transform.rotate(
              angle: 0.22,
              child: Container(
                width: 82,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF2648B8),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            right: 34,
            top: 20,
            child: Container(
              width: 12,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1F42AE),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: 0,
            child: Container(
              width: 24,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1B3893),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 16,
            child: ClipPath(
              clipper: _LightBeamClipper(),
              child: Container(
                width: 90,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.55),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 14,
            child: Opacity(
              opacity: 0.09,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 20, height: 55, color: Colors.white),
                  const SizedBox(width: 10),
                  Container(width: 20, height: 80, color: Colors.white),
                  const SizedBox(width: 10),
                  Container(width: 18, height: 46, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return SizedBox(
      height: 205,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStatCard(
            title: 'Operativas',
            value: '$operativas',
            subtitle: '${porcentajeOperativas.toStringAsFixed(1)}% del total',
            icon: Icons.check_rounded,
            iconBg: const Color(0xFFE8F7ED),
            iconColor: const Color(0xFF2DBE68),
            accentColor: const Color(0xFF2DBE68),
          ),
          const SizedBox(width: 14),
          _buildStatCard(
            title: 'Inoperativas',
            value: '$inoperativas',
            subtitle: '${porcentajeInoperativas.toStringAsFixed(1)}% del total',
            icon: Icons.close_rounded,
            iconBg: const Color(0xFFFFEFF0),
            iconColor: const Color(0xFFFF5A57),
            accentColor: const Color(0xFFFF5A57),
          ),
          const SizedBox(width: 14),
          _buildStatCard(
            title: 'En mantenimiento',
            value: '$mantenimiento',
            subtitle:
                '${porcentajeMantenimiento.toStringAsFixed(1)}% del total',
            icon: Icons.handyman_rounded,
            iconBg: const Color(0xFFFFF4E6),
            iconColor: const Color(0xFFF6A11A),
            accentColor: const Color(0xFFF6A11A),
          ),
          const SizedBox(width: 14),
          _buildStatCard(
            title: 'Total luminarias',
            value: '$total',
            subtitle: 'Sin duplicados',
            icon: Icons.lightbulb_outline_rounded,
            iconBg: const Color(0xFFF1EEFF),
            iconColor: const Color(0xFF6E4FFF),
            accentColor: const Color(0xFF6E4FFF),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color accentColor,
  }) {
    return Container(
      width: 168,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border(top: BorderSide(color: accentColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 38),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF14265B),
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF13265E),
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: accentColor,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 12,
            child: CustomPaint(
              size: const Size(110, 12),
              painter: _MiniLinePainter(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color cardColor,
    required Color arrowColor,
    required VoidCallback onTap,
    Color titleColor = const Color(0xFF13265E),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: iconBg.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7696),
                        fontWeight: FontWeight.w500,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: arrowColor,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF4A73FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Mantén tu sistema actualizado para un mejor control operativo.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5E6A8D),
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();

    path.moveTo(0, size.height * 0.65);
    path.quadraticBezierTo(
      size.width * 0.20,
      size.height * 0.20,
      size.width * 0.46,
      size.height * 0.62,
    );
    path.quadraticBezierTo(
      size.width * 0.72,
      size.height * 0.98,
      size.width,
      size.height * 0.28,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniLinePainter extends CustomPainter {
  final Color color;

  _MiniLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.78),
      Offset(size.width * 0.10, size.height * 0.76),
      Offset(size.width * 0.18, size.height * 0.30),
      Offset(size.width * 0.30, size.height * 0.70),
      Offset(size.width * 0.42, size.height * 0.48),
      Offset(size.width * 0.54, size.height * 0.76),
      Offset(size.width * 0.66, size.height * 0.34),
      Offset(size.width * 0.78, size.height * 0.78),
      Offset(size.width * 0.90, size.height * 0.54),
      Offset(size.width, size.height * 0.78),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _LightBeamClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.25, 0);
    path.lineTo(size.width * 0.60, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}