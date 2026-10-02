import 'package:ecoeat_mobile/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Recipe convierte la respuesta JSON del backend', () {
    final recipe = Recipe.fromJson({
      'id': 7,
      'titulo': 'Arroz de aprovechamiento',
      'tiempo_minutos': 20,
      'ingredientes': ['arroz', 'tomate'],
      'pasos': ['Mezclar', 'Servir'],
      'consejo_anti_desperdicio': 'Guardar una porción',
      'fuente': 'gemini',
      'favorito': true,
    });

    expect(recipe.id, 7);
    expect(recipe.minutes, 20);
    expect(recipe.ingredients, contains('tomate'));
    expect(recipe.favorite, isTrue);
  });
}
