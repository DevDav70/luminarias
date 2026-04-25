class LuminariaModel {
  final String? id;
  final String codigo;
  final String areaZona;
  final double horometro;
  final String estado;
  final DateTime fechaRegistro;
  final String observacion;
  final DateTime? createdAt;

  LuminariaModel({
    this.id,
    required this.codigo,
    required this.areaZona,
    required this.horometro,
    required this.estado,
    required this.fechaRegistro,
    required this.observacion,
    this.createdAt,
  });

  factory LuminariaModel.fromMap(Map<String, dynamic> map) {
    final valorHorometro = map['horometro'];

    return LuminariaModel(
      id: map['id']?.toString(),
      codigo: (map['codigo'] ?? '').toString(),
      areaZona: (map['area_zona'] ?? '').toString(),
      horometro: valorHorometro is num
          ? valorHorometro.toDouble()
          : double.tryParse(valorHorometro.toString()) ?? 0,
      estado: (map['estado'] ?? '').toString(),
      fechaRegistro: DateTime.parse(map['fecha_registro'].toString()),
      observacion: (map['observacion'] ?? '').toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo.trim().toUpperCase(),
      'area_zona': areaZona.trim().toUpperCase(),
      'horometro': horometro,
      'estado': estado.trim().toUpperCase(),
      'fecha_registro':
          '${fechaRegistro.year.toString().padLeft(4, '0')}-'
          '${fechaRegistro.month.toString().padLeft(2, '0')}-'
          '${fechaRegistro.day.toString().padLeft(2, '0')}',
      'observacion': observacion.trim().toUpperCase(),
    };
  }
}