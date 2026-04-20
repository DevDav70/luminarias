import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LuminariaCard extends StatelessWidget {
  final String codigo;
  final String zona;
  final double horometro;
  final String estado;
  final String fecha;
  final VoidCallback onTap;

  const LuminariaCard({
    super.key,
    required this.codigo,
    required this.zona,
    required this.horometro,
    required this.estado,
    required this.fecha,
    required this.onTap,
  });

  Color getEstadoColor() {
    final estadoNormalizado = estado.trim().toUpperCase();

    switch (estadoNormalizado) {
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

  String getEstadoTexto() {
    final estadoNormalizado = estado.trim().toUpperCase();

    switch (estadoNormalizado) {
      case 'OPERATIVO':
        return 'OPERATIVO';
      case 'INOPERATIVO':
        return 'INOPERATIVO';
      case 'MANTENIMIENTO':
        return 'MANTENIMIENTO';
      default:
        return estado.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = getEstadoColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    codigo.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    getEstadoTexto(),
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              zona.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Horómetro: ${horometro.toStringAsFixed(1)} h',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fecha,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
