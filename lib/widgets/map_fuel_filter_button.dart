import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/stations_provider.dart';
import 'filters_trigger_button.dart';
import 'fuel_chips_wrap.dart';

/// Floating "Filtres" button for the Carte screen — same look as the Liste
/// screen's button, but its sheet only offers the fuel-type filter (the
/// Carte already scopes stations to the visible viewport, so a distance
/// radius doesn't apply there).
class MapFuelFilterButton extends StatelessWidget {
  const MapFuelFilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationsProvider>();

    return FiltersTriggerButton(
      label: 'Filtres',
      activeCount: provider.selectedFuel != null ? 1 : 0,
      elevated: true,
      onTap: () => _showFuelSheet(context),
    );
  }
}

void _showFuelSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _FuelSheet(),
  );
}

class _FuelSheet extends StatelessWidget {
  const _FuelSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            Text(
              'Carburant',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            const FuelChipsWrap(),
          ],
        ),
      ),
    );
  }
}
