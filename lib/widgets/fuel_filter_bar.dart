import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/stations_provider.dart';
import 'list_filters_sheet.dart';

/// Top filter row for the Liste screen: a Distance/Prix sort toggle on the
/// left, and a "Filtres" button on the right that opens a sheet with the
/// fuel-type and distance-radius filters.
class FuelFilterBar extends StatelessWidget {
  const FuelFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SegmentedButton<StationSort>(
                segments: const [
                  ButtonSegment(
                    value: StationSort.distance,
                    label: Text('Distance'),
                    icon: Icon(Icons.near_me),
                  ),
                  ButtonSegment(
                    value: StationSort.price,
                    label: Text('Prix'),
                    icon: Icon(Icons.local_offer),
                  ),
                ],
                selected: {provider.sort},
                onSelectionChanged: (selection) => provider.setSort(selection.first),
              ),
              const ListFiltersButton(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ],
    );
  }
}
