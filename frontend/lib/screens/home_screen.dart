import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'result_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final result = await _api.getSuggestions();
      if (mounted) setState(() => _suggestions = result);
    } catch (_) {
      // Las sugerencias son opcionales; la entrada manual sigue disponible.
    }
  }

  void _addIngredient([String? value]) {
    final ingredient = (value ?? _controller.text).trim().toLowerCase();
    if (ingredient.isEmpty || _ingredients.contains(ingredient)) return;
    setState(() => _ingredients.add(ingredient));
    _controller.clear();
  }

  Future<void> _generate() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ingrediente.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final recipe = await _api.generateRecipe(_ingredients);
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ResultScreen(recipe: recipe)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la receta: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EcoEat'), centerTitle: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Cocina lo que tienes',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega ingredientes y crea una receta que reduzca el desperdicio.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addIngredient(),
              decoration: InputDecoration(
                labelText: 'Ingrediente',
                hintText: 'Ej. arroz',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Agregar',
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_ingredients.isNotEmpty) ...[
              Text(
                'Tu despensa',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _ingredients
                    .map(
                      (item) => InputChip(
                        label: Text(item),
                        onDeleted: () =>
                            setState(() => _ingredients.remove(item)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
            ],
            if (_suggestions.isNotEmpty) ...[
              Text(
                'Sugerencias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _suggestions
                    .where((item) => !_ingredients.contains(item))
                    .take(8)
                    .map(
                      (item) => ActionChip(
                        label: Text(item),
                        onPressed: () => _addIngredient(item),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Creando receta...' : 'Generar receta'),
            ),
          ],
        ),
      ),
    );
  }
}
