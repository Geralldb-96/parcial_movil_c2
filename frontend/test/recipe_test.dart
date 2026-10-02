import 'package:ecoeat_mobile/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Recipe convierte la respuesta JSON del backend', () {
    final recipe = Recipe.fromJson({
      'id': 7,
      'titulo': 'Arroz de aprovechamiento',
      'descripcion': 'Rápido y delicioso',
      'tiempo_minutos': 20,
      'porciones': 2,
      'ingredientes': ['arroz', 'tomate'],
      'pasos': ['Mezclar', 'Servir'],
      'consejo_anti_desperdicio': 'Guardar una porción',
      'fuente': 'gemini',
      'advertencia': '',
      'favorito': true,
    });

    expect(recipe.id, 7);
    expect(recipe.minutes, 20);
    expect(recipe.servings, 2);
    expect(recipe.ingredients, contains('tomate'));
    expect(recipe.favorite, isTrue);
    expect(recipe.warning, isEmpty);
  });
}
