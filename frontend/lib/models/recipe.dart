class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.minutes,
    required this.ingredients,
    required this.steps,
    required this.tip,
    required this.source,
    required this.favorite,
  });

  final int id;
  final String title;
  final int minutes;
  final List<String> ingredients;
  final List<String> steps;
  final String tip;
  final String source;
  final bool favorite;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'] as int,
    title: json['titulo'] as String,
    minutes: json['tiempo_minutos'] as int,
    ingredients: List<String>.from(json['ingredientes'] as List),
    steps: List<String>.from(json['pasos'] as List),
    tip: json['consejo_anti_desperdicio'] as String? ?? '',
    source: json['fuente'] as String? ?? 'ia',
    favorite: json['favorito'] as bool? ?? false,
  );
}
