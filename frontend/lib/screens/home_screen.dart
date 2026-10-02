import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'favorites_screen.dart';
import 'result_screen.dart';

const _coral = Color(0xFFF04D3E);
const _orange = Color(0xFFFF7A35);
const _ink = Color(0xFF2D2926);
const _cream = Color(0xFFFFF8EF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _api = ApiService();
  final List<String> _ingredients = [];
  List<String> _suggestions = [];
  bool _loading = false;
  String? _error;
  String _diet = 'Sin restricciones';
  String _difficulty = 'Fácil';
  int _maxMinutes = 30;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final result = await _api.getSuggestions();
      if (mounted) setState(() => _suggestions = result);
    } catch (_) {
      // La entrada manual sigue disponible si el backend no está iniciado.
    }
  }

  void _addIngredient([String? value]) {
    final ingredient = (value ?? _controller.text).trim().toLowerCase();
    if (ingredient.isEmpty || _ingredients.contains(ingredient)) return;
    setState(() {
      _ingredients.add(ingredient);
      _error = null;
    });
    _controller.clear();
  }

  Future<void> _generate() async {
    if (_ingredients.isEmpty) {
      setState(() => _error = 'Agrega al menos un ingrediente para comenzar.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipe = await _api.generateRecipe(
        _ingredients,
        diet: _diet,
        difficulty: _difficulty,
        maxMinutes: _maxMinutes,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(recipe: recipe, api: _api),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos crear tu receta. Revisa la conexión e inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showSettings() async {
    var diet = _diet;
    var difficulty = _difficulty;
    var minutes = _maxMinutes;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: _cream,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 14, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Configuración',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Personaliza lo que prepara tu chef con IA.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                _SettingGroup(
                  title: 'Preferencia alimentaria',
                  values: const [
                    'Sin restricciones',
                    'Vegetariana',
                    'Vegana',
                    'Sin gluten',
                  ],
                  selected: diet,
                  onSelected: (value) => setModalState(() => diet = value),
                ),
                const SizedBox(height: 18),
                _SettingGroup(
                  title: 'Dificultad',
                  values: const ['Fácil', 'Media', 'Avanzada'],
                  selected: difficulty,
                  onSelected: (value) =>
                      setModalState(() => difficulty = value),
                ),
                const SizedBox(height: 18),
                _SettingGroup(
                  title: 'Tiempo máximo',
                  values: const ['15 min', '30 min', '60 min'],
                  selected: '$minutes min',
                  onSelected: (value) => setModalState(
                    () => minutes = int.parse(value.split(' ').first),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
          actions: [
            SizedBox(
              width: double.infinity,
              child: _GradientButton(
                label: 'Guardar',
                icon: Icons.check,
                onPressed: () {
                  setState(() {
                    _diet = diet;
                    _difficulty = difficulty;
                    _maxMinutes = minutes;
                  });
                  Navigator.pop(dialogContext);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFavorites() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FavoritesScreen(api: _api)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _Header(
                  onFavorites: _showFavorites,
                  onSettings: _showSettings,
                ),
                const SizedBox(height: 26),
                const Text(
                  'TU CHEF CON IA',
                  style: TextStyle(
                    color: _coral,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '¿Qué tienes en\ncasa?',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 37,
                    height: .98,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tú pones los ingredientes. Nosotros, la inspiración para cocinar algo rico.',
                  style: TextStyle(color: Colors.black54, height: 1.35),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addIngredient(),
                  decoration: InputDecoration(
                    hintText: 'Agrega un ingrediente...',
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(5),
                      child: IconButton.filled(
                        onPressed: _addIngredient,
                        style: IconButton.styleFrom(backgroundColor: _coral),
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'A un toque de tu receta',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _suggestions
                        .where((item) => !_ingredients.contains(item))
                        .take(8)
                        .map(
                          (item) => ActionChip(
                            label: Text('$item  +'),
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                            onPressed: () => _addIngredient(item),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'En tu despensa',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              '${_ingredients.length} ingredientes',
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_ingredients.isEmpty)
                          const Text(
                            'Agrega ingredientes para llenar tu despensa.',
                            style: TextStyle(color: Colors.black45),
                          )
                        else
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: _ingredients
                                .map(
                                  (item) => InputChip(
                                    label: Text(item),
                                    backgroundColor: const Color(0xFFFFE6DE),
                                    side: BorderSide.none,
                                    deleteIconColor: _coral,
                                    onDeleted: () => setState(
                                      () => _ingredients.remove(item),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: _orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: _generate,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                _GradientButton(
                  label: 'Generar receta',
                  icon: Icons.auto_awesome,
                  onPressed: _loading ? null : _generate,
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco_outlined, size: 15, color: Colors.black45),
                    SizedBox(width: 5),
                    Text(
                      'Más sabor. Menos desperdicio.',
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_loading) const _LoadingOverlay(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onFavorites, required this.onSettings});
  final VoidCallback onFavorites;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _coral,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_menu,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 9),
          const Text(
            'EcoEat',
            style: TextStyle(
              color: _coral,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Mis favoritos',
            onPressed: onFavorites,
            icon: const Icon(Icons.favorite_border, color: _coral),
          ),
          IconButton.filledTonal(
            tooltip: 'Configuración',
            onPressed: onSettings,
            icon: const Icon(Icons.tune),
          ),
        ],
      );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(colors: [_coral, _orange]),
          color: onPressed == null ? Colors.black12 : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _SettingGroup extends StatelessWidget {
  const _SettingGroup({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });
  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: value == selected,
                    selectedColor: const Color(0xFFFFD8CF),
                    side: value == selected
                        ? const BorderSide(color: _coral)
                        : BorderSide.none,
                    onSelected: (_) => onSelected(value),
                  ),
                )
                .toList(),
          ),
        ],
      );
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: _cream.withValues(alpha: .86),
        child: Center(
          child: Container(
            width: 300,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, 8)),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child:
                      CircularProgressIndicator(color: _coral, strokeWidth: 3),
                ),
                SizedBox(height: 24),
                Text(
                  'Creando tu receta...',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Buscando la mejor combinación para tus ingredientes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                SizedBox(height: 14),
                Text(
                  'Un poco de magia, unos segundos.',
                  style: TextStyle(
                    color: _coral,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
