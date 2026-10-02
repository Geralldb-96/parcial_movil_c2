import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';

const _coral = Color(0xFFF04D3E);
const _ink = Color(0xFF2D2926);

class ResultScreen extends StatefulWidget {
  const ResultScreen({required this.recipe, required this.api, super.key});
  final Recipe recipe;
  final ApiService api;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late bool _favorite = widget.recipe.favorite;
  bool _saving = false;

  Future<void> _toggleFavorite() async {
    if (_saving) return;
    final next = !_favorite;
    setState(() {
      _favorite = next;
      _saving = true;
    });
    try {
      await widget.api.setFavorite(widget.recipe.id, next);
    } catch (_) {
      if (!mounted) return;
      setState(() => _favorite = !next);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el favorito.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Tu receta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
            color: _favorite ? _coral : _ink,
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            height: 210,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD0A8), Color(0xFFF0714F)],
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.ramen_dining,
                    size: 112,
                    color: Colors.white70,
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 14,
                  child: Chip(
                    avatar:
                        const Icon(Icons.auto_awesome, size: 15, color: _coral),
                    label: Text(
                      recipe.source == 'modo_demo'
                          ? 'Modo demo'
                          : 'Generado con IA',
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                  ),
                ),
                if (recipe.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    recipe.description,
                    style: const TextStyle(color: Colors.black54, height: 1.45),
                  ),
                ],
                const SizedBox(height: 15),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _Meta(icon: Icons.schedule, label: '${recipe.minutes} min'),
                    const _Meta(
                        icon: Icons.signal_cellular_alt, label: 'Fácil'),
                    _Meta(
                      icon: Icons.people_outline,
                      label: '${recipe.servings} porciones',
                    ),
                  ],
                ),
                if (recipe.warning.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4DE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: _coral),
                        const SizedBox(width: 10),
                        Expanded(child: Text(recipe.warning)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                _RecipeSection(
                  title: 'Ingredientes',
                  children: recipe.ingredients
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Color(0xFFF0E7DD))),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  size: 18, color: _coral),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 26),
                _RecipeSection(
                  title: 'Preparación',
                  children: [
                    for (var i = 0; i < recipe.steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFFFE2D9),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: _coral,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                recipe.steps[i],
                                style: const TextStyle(height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (recipe.tip.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9E1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, color: _coral),
                        const SizedBox(width: 10),
                        Expanded(child: Text(recipe.tip)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                FilledButton.icon(
                  onPressed: _saving ? null : _toggleFavorite,
                  style: FilledButton.styleFrom(backgroundColor: _coral),
                  icon:
                      Icon(_favorite ? Icons.favorite : Icons.favorite_border),
                  label: Text(_favorite
                      ? 'Guardada en favoritos'
                      : 'Guardar en favoritos'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Color(0xFFE8D9CE)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.refresh, color: _coral),
                  label: const Text('Generar otra receta',
                      style: TextStyle(color: _coral)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _coral, size: 17),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      );
}

class _RecipeSection extends StatelessWidget {
  const _RecipeSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      );
}
