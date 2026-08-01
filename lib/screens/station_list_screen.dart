import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/favorites_provider.dart';
import '../state/stations_provider.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/fuel_filter_bar.dart';
import '../widgets/station_card.dart';
import 'station_detail_sheet.dart';

class StationListScreen extends StatelessWidget {
  const StationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stationsProvider = context.watch<StationsProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Column(
      children: [
        const FuelFilterBar(),
        Expanded(child: _buildBody(context, stationsProvider, favoritesProvider)),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    StationsProvider stationsProvider,
    FavoritesProvider favoritesProvider,
  ) {
    switch (stationsProvider.status) {
      case StationsStatus.idle:
      case StationsStatus.loading:
        return const _LoadingView();

      case StationsStatus.error:
        return EmptyState(
          icon: Icons.wifi_off_rounded,
          iconColor: Theme.of(context).colorScheme.error,
          iconBackgroundColor: Theme.of(context).colorScheme.errorContainer,
          title: 'Impossible de charger les stations',
          message: stationsProvider.errorMessage,
          action: FilledButton.icon(
            onPressed: stationsProvider.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        );

      case StationsStatus.loaded:
        final stations = stationsProvider.stations;
        if (stations.isEmpty) {
          return const EmptyState(
            icon: Icons.local_gas_station_outlined,
            title: 'Aucune station trouvée',
            message: 'Essayez un autre carburant ou tirez pour actualiser.',
          );
        }

        return RefreshIndicator(
          onRefresh: stationsProvider.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: stations.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ListHeader(
                  count: stations.length,
                  lastUpdated: stationsProvider.lastUpdated,
                );
              }
              final station = stations[index - 1];
              return StationCard(
                station: station,
                highlightedFuel: stationsProvider.selectedFuel,
                isFavorite: favoritesProvider.isFavorite(station.id),
                onTap: () => StationDetailSheet.show(context, station),
                onToggleFavorite: () => favoritesProvider.toggle(station),
              );
            },
          ),
        );
    }
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.count, required this.lastUpdated});

  final int count;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count station${count > 1 ? 's' : ''} à proximité',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (lastUpdated != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.update, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  formatRelativeTime(lastUpdated!),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Recherche des stations…',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
