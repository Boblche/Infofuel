import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/favorites_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/station_card.dart';
import 'station_detail_sheet.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favorites = favoritesProvider.favorites;

    if (favorites.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        title: 'Aucun favori pour l\'instant',
        message: 'Ajoutez des stations depuis la liste ou la carte\n'
            'pour les retrouver ici rapidement.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final station = favorites[index];
        return StationCard(
          station: station,
          isFavorite: true,
          onTap: () => StationDetailSheet.show(context, station),
          onToggleFavorite: () => favoritesProvider.toggle(station),
        );
      },
    );
  }
}
