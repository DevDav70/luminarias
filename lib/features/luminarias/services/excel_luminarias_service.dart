import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../models/luminaria_model.dart';

class ExcelLuminariasService {
  static Future<String?> exportarLuminariasConDialogo(
    List<LuminariaModel> luminarias,
  ) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Luminarias'];

    // 🔥 ENCABEZADOS (FECHA PRIMERO)
    sheet.appendRow([
      TextCellValue('FECHA'),
      TextCellValue('CÓDIGO'),
      TextCellValue('ÁREA / ZONA'),
      TextCellValue('HORÓMETRO'),
      TextCellValue('ESTADO'),
      TextCellValue('OBSERVACIÓN'),
    ]);

    for (final item in luminarias) {
      final fecha =
          '${item.fechaRegistro.day.toString().padLeft(2, '0')}/'
          '${item.fechaRegistro.month.toString().padLeft(2, '0')}/'
          '${item.fechaRegistro.year}';

      // 🔥 DATOS (MISMO ORDEN)
      sheet.appendRow([
        TextCellValue(fecha),
        TextCellValue(item.codigo.toUpperCase()),
        TextCellValue(item.areaZona.toUpperCase()),
        TextCellValue(item.horometro.toStringAsFixed(1)),
        TextCellValue(item.estado.toUpperCase()),
        TextCellValue(
          item.observacion.trim().isEmpty
              ? 'SIN OBSERVACIÓN'
              : item.observacion.toUpperCase(),
        ),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    final Uint8List data = Uint8List.fromList(bytes);

    final String nombreArchivo =
        'reporte_luminarias_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final String? outputPath = await FilePicker.saveFile(
      dialogTitle: 'Guardar reporte Excel',
      fileName: nombreArchivo,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: data,
    );

    if (outputPath == null || outputPath.isEmpty) {
      return null;
    }

    return outputPath;
  }

  static Future<void> exportarLuminariasEnRuta(
    List<LuminariaModel> luminarias,
    String outputPath,
  ) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Luminarias'];

    // 🔥 ENCABEZADOS
    sheet.appendRow([
      TextCellValue('FECHA'),
      TextCellValue('CÓDIGO'),
      TextCellValue('ÁREA / ZONA'),
      TextCellValue('HORÓMETRO'),
      TextCellValue('ESTADO'),
      TextCellValue('OBSERVACIÓN'),
    ]);

    for (final item in luminarias) {
      final fecha =
          '${item.fechaRegistro.day.toString().padLeft(2, '0')}/'
          '${item.fechaRegistro.month.toString().padLeft(2, '0')}/'
          '${item.fechaRegistro.year}';

      sheet.appendRow([
        TextCellValue(fecha),
        TextCellValue(item.codigo.toUpperCase()),
        TextCellValue(item.areaZona.toUpperCase()),
        TextCellValue(item.horometro.toStringAsFixed(1)),
        TextCellValue(item.estado.toUpperCase()),
        TextCellValue(
          item.observacion.trim().isEmpty
              ? 'SIN OBSERVACIÓN'
              : item.observacion.toUpperCase(),
        ),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    final file = File(outputPath);
    await file.writeAsBytes(bytes, flush: true);
  }
}
