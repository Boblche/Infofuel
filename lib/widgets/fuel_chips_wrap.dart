import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/stations_provider.dart';
import '../utils/fuel_type.dart';
import 'filter_chip_button.dart';

/// Wrapping row of fuel-type chips (Tous, Gazole, SP95...), used inside the
/// Liste and Carte screens' filter bottom sheets.
class FuelChipsWrap extends StatelessWidget {
  const FuelChipsWrap({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationsProvider>();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChipButton(
          label: 'Tous',
          selected: provider.selectedFuel == null,
          onTap: () => provider.setFuelFilter(null),
        ),
        for (final fuel in FuelType.values)
          FilterChipButton(
            label: fuel.label,
            selected: provider.selectedFuel == fuel,
            onTap: () => provider.setFuelFilter(fuel),
          ),
      ],
    );
  }
}
