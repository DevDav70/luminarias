import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/luminaria_model.dart';

class LuminariaService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> crearLuminaria(LuminariaModel luminaria) async {
    await _client.from('luminarias').insert(luminaria.toMap());
  }

  static Future<List<LuminariaModel>> obtenerLuminarias() async {
    final response = await _client
        .from('luminarias')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => LuminariaModel.fromMap(item))
        .toList();
  }

  static Future<void> eliminarLuminaria(String id) async {
    await _client.from('luminarias').delete().eq('id', id);
  }

  static Future<LuminariaModel?> obtenerPorId(String id) async {
    final response = await _client
        .from('luminarias')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    return LuminariaModel.fromMap(response);
  }

  static Future<void> actualizarLuminaria(
    String id,
    LuminariaModel luminaria,
  ) async {
    await _client
        .from('luminarias')
        .update({
          'codigo': luminaria.codigo,
          'area_zona': luminaria.areaZona,
          'horometro': luminaria.horometro,
          'estado': luminaria.estado,
          'fecha_registro':
              '${luminaria.fechaRegistro.year.toString().padLeft(4, '0')}-${luminaria.fechaRegistro.month.toString().padLeft(2, '0')}-${luminaria.fechaRegistro.day.toString().padLeft(2, '0')}',
          'observacion': luminaria.observacion,
        })
        .eq('id', id);
  }

  static Future<List<LuminariaModel>> buscarPorCodigo(String texto) async {
    if (texto.trim().isEmpty) return [];

    final response = await _client
        .from('luminarias')
        .select()
        .ilike('codigo', '%${texto.trim()}%')
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => LuminariaModel.fromMap(item))
        .toList();
  }

  static Future<LuminariaModel?> obtenerUltimoPorCodigo(String codigo) async {
    final response = await _client
        .from('luminarias')
        .select()
        .eq('codigo', codigo.trim().toUpperCase())
        .order('fecha_registro', ascending: false)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return LuminariaModel.fromMap(response);
  }
}
