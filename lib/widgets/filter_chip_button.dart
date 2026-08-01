import 'package:flutter/material.dart';

/// A small pill-shaped selectable chip, shared by the fuel and distance
/// filter rows so both stay visually consistent.
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Align(
          // widthFactor keeps the chip hugging its content even when a
          // parent (e.g. Wrap) hands it bounded width, while the default
          // null heightFactor still lets it fill+center within a taller
          // forced height (e.g. a fixed-height horizontal ListView row).
          alignment: Alignment.center,
          widthFactor: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
