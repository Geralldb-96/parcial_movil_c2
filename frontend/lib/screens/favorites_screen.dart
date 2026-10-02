import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

const _coral = Color(0xFFF04D3E);
const _orange = Color(0xFFFF7A35);
const _ink = Color(0xFF2D2926);

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({required this.api, super.key});
  final ApiService api;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> _favorites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipes = await widget.api.getFavorites();
      if (mounted) setState(() => _favorites = recipes.reversed.toList());
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar tus favoritos.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRecipe(Recipe recipe) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(recipe: recipe, api: widget.api),
      ),
    );
    await _loadFavorites();
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text(
          '¿Quieres eliminar “${recipe.title}” de tu historial?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _coral),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.api.deleteRecipe(recipe.id);
      if (!mounted) return;
      setState(() => _favorites.removeWhere((item) => item.id == recipe.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receta eliminada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la receta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Mis favoritos',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: _coral,
        onRefresh: _loadFavorites,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _coral));
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.black26),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loadFavorites,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    if (_favorites.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 86),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE2D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border, size: 48, color: _coral),
          ),
          const SizedBox(height: 22),
          const Text(
            'Aún no tienes favoritos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Abre una receta y toca el corazón para guardarla aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 22),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Crear una receta'),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      itemCount: _favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recipe = _favorites[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openRecipe(recipe),
            child: Row(
              children: [
                Container(
                  width: 104,
                  height: 132,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFC899), _orange],
                    ),
                  ),
                  child: const Icon(
                    Icons.ramen_dining,
                    size: 52,
                    color: Colors.white70,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 17,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 16, color: _coral),
                            const SizedBox(width: 4),
                            Text('${recipe.minutes} min'),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.people_outline,
                              size: 16,
                              color: _coral,
                            ),
                            const SizedBox(width: 4),
                            Text('${recipe.servings}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Toca para ver la receta',
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar receta',
                  onPressed: () => _deleteRecipe(recipe),
                  icon: const Icon(Icons.delete_outline, color: _coral),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
