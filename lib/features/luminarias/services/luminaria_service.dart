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
    await _client.from('luminarias').update(luminaria.toMap()).eq('id', id);
  }

  static Future<List<LuminariaModel>> buscarPorCodigo(String texto) async {
    if (texto.trim().isEmpty) return [];

    final response = await _client
        .from('luminarias')
        .select()
        .ilike('codigo', '%${texto.trim().toUpperCase()}%')
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => LuminariaModel.fromMap(item))
        .toList();
  }

  static Future<List<LuminariaModel>> sugerenciasPorCodigo(String texto) async {
    if (texto.trim().isEmpty) return [];

    final buscar = texto.trim().toUpperCase();

    final response = await _client
        .from('luminarias')
        .select()
        .ilike('codigo', '%$buscar%')
        .order('created_at', ascending: false)
        .limit(50);

    final lista = (response as List)
        .map((item) => LuminariaModel.fromMap(item))
        .toList();

    final Map<String, LuminariaModel> unicos = {};

    for (final item in lista) {
      unicos[item.codigo.trim().toUpperCase()] = item;
    }

    final listaFinal = unicos.values.toList()
      ..sort(
        (a, b) => a.codigo.toUpperCase().compareTo(b.codigo.toUpperCase()),
      );

    return listaFinal.take(10).toList();
  }

  static Future<bool> existeRegistroEnFecha({
    required String codigo,
    required DateTime fecha,
  }) async {
    final fechaTexto =
        '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';

    final response = await _client
        .from('luminarias')
        .select('id')
        .eq('codigo', codigo.trim().toUpperCase())
        .eq('fecha_registro', fechaTexto)
        .limit(1);

    return (response as List).isNotEmpty;
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
