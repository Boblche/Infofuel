import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/stations_provider.dart';
import 'filter_chip_button.dart';
import 'filters_trigger_button.dart';
import 'fuel_chips_wrap.dart';

const _distanceOptionsKm = [5.0, 10.0, 20.0, 50.0];

/// Compact button that opens a bottom sheet with the secondary Liste
/// filters (fuel type, distance radius), keeping the always-visible top row
/// down to just the sort toggle.
class ListFiltersButton extends StatelessWidget {
  const ListFiltersButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationsProvider>();
    final activeCount = (provider.selectedFuel != null ? 1 : 0) +
        (provider.maxDistanceKm != null ? 1 : 0);

    return FiltersTriggerButton(
      label: 'Filtres',
      activeCount: activeCount,
      onTap: () => _showFiltersSheet(context),
    );
  }
}

void _showFiltersSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _FiltersSheet(),
  );
}

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final hasActiveFilters =
        provider.selectedFuel != null || provider.maxDistanceKm != null;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      provider.setFuelFilter(null);
                      provider.setMaxDistance(null);
                    },
                    child: const Text('Réinitialiser'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Carburant',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const FuelChipsWrap(),
            const SizedBox(height: 24),
            Text(
              'Distance',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChipButton(
                  label: 'Tous',
                  selected: provider.maxDistanceKm == null,
                  onTap: () => provider.setMaxDistance(null),
                ),
                for (final km in _distanceOptionsKm)
                  FilterChipButton(
                    label: '${km.toInt()} km',
                    selected: provider.maxDistanceKm == km,
                    onTap: () => provider.setMaxDistance(km),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
