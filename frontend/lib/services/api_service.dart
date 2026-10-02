import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/recipe.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<String>> getSuggestions() async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/api/ingredientes/sugeridos'))
        .timeout(const Duration(seconds: 12));
    final body = _decode(response);
    return List<String>.from(body['ingredientes'] as List);
  }

  Future<Recipe> generateRecipe(
    List<String> ingredients, {
    required String diet,
    required String difficulty,
    required int maxMinutes,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/receta/generar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ingredientes': ingredients,
            'preferencias': {
              'dieta': diet,
              'dificultad': difficulty,
              'tiempo_maximo': maxMinutes,
            },
          }),
        )
        .timeout(const Duration(seconds: 40));
    final body = _decode(response);
    return Recipe.fromJson(body['receta'] as Map<String, dynamic>);
  }

  Future<Recipe> setFavorite(int id, bool favorite) async {
    final response = await _client
        .put(
          Uri.parse('${ApiConfig.baseUrl}/api/historial/favorito'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': id, 'favorito': favorite}),
        )
        .timeout(const Duration(seconds: 12));
    final body = _decode(response);
    return Recipe.fromJson(body['receta'] as Map<String, dynamic>);
  }

  Future<List<Recipe>> getFavorites() async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/api/historial/favoritos'))
        .timeout(const Duration(seconds: 12));
    final body = _decode(response);
    return (body['recetas'] as List)
        .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteRecipe(int id) async {
    final response = await _client
        .delete(Uri.parse('${ApiConfig.baseUrl}/api/historial/$id'))
        .timeout(const Duration(seconds: 12));
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        body['error'] as String? ?? 'Error ${response.statusCode}',
      );
    }
    return body;
  }
}
