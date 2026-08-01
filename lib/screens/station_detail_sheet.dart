import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/station.dart';
import '../state/favorites_provider.dart';
import '../state/stations_provider.dart';
import '../utils/format.dart';
import '../utils/fuel_type.dart';
import '../utils/navigation_launcher.dart';

class StationDetailSheet extends StatelessWidget {
  const StationDetailSheet({super.key, required this.station});

  final Station station;

  static Future<void> show(BuildContext context, Station station) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StationDetailSheet(station: station),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = station.prices.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
    final cheapestFuel = station.cheapestFuel;
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(station.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.adresse.isEmpty ? station.ville : station.adresse,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.place, size: 15, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${station.ville} ${station.codePostal}'.trim(),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          if (station.distanceMeters != null) ...[
                            const SizedBox(width: 8),
                            Text('· ${formatDistance(station.distanceMeters)}',
                                style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _FavoriteButton(
                  isFavorite: isFavorite,
                  onTap: () => favorites.toggle(station),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => openNavigationChooser(context, station),
                    icon: const Icon(Icons.directions),
                    label: const Text('Itinéraire'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<StationsProvider>().focusOnMap(station);
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Voir sur la carte'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Carburants',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(
                'Aucun prix disponible pour cette station.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    for (final (i, entry) in entries.indexed)
                      _PriceRow(
                        fuel: entry.key,
                        price: entry.value,
                        isCheapest: entry.key == cheapestFuel && entries.length > 1,
                        showDivider: i != entries.length - 1,
                      ),
                  ],
                ),
              ),
            if (station.isOpen24h) ...[
              const SizedBox(height: 12),
              _InfoPill(
                icon: Icons.schedule,
                label: 'Ouvert 24h/24',
                color: scheme.primaryContainer,
                onColor: scheme.onPrimaryContainer,
              ),
            ],
            if (station.services.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Services',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final service in station.services)
                    _InfoPill(
                      icon: Icons.check_circle_outline,
                      label: service,
                      color: scheme.surfaceContainerHigh,
                      onColor: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isFavorite ? scheme.errorContainer : scheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? scheme.onErrorContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.fuel,
    required this.price,
    required this.isCheapest,
    required this.showDivider,
  });

  final FuelType fuel;
  final double price;
  final bool isCheapest;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(fuel.label, style: const TextStyle(fontSize: 15)),
                    if (isCheapest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Moins cher',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                formatPrice(price),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isCheapest ? scheme.tertiary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: onColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: onColor),
          ),
        ],
      ),
    );
  }
}
