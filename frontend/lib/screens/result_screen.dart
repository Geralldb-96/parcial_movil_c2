import 'package:flutter/material.dart';

import '../models/recipe.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.recipe, super.key});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu receta')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(recipe.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 20),
              const SizedBox(width: 6),
              Text('${recipe.minutes} minutos'),
              const Spacer(),
              Chip(label: Text(recipe.source == 'modo_demo' ? 'Demo' : 'IA')),
            ],
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Ingredientes',
            children: recipe.ingredients
                .map((item) => Text('• $item'))
                .toList(),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Preparación',
            children: [
              for (var i = 0; i < recipe.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('${i + 1}. ${recipe.steps[i]}'),
                ),
            ],
          ),
          if (recipe.tip.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Consejo anti-desperdicio',
              children: [Text(recipe.tip)],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}
