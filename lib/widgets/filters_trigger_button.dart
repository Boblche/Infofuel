import 'package:flutter/material.dart';

/// Compact pill button that opens a filters bottom sheet, showing a badge
/// with the number of active filters when non-zero. Shared by the Liste
/// screen's "Filtres" button and the Carte screen's fuel-only variant.
class FiltersTriggerButton extends StatelessWidget {
  const FiltersTriggerButton({
    super.key,
    required this.label,
    required this.activeCount,
    required this.onTap,
    this.elevated = false,
  });

  final String label;
  final int activeCount;
  final VoidCallback onTap;

  /// Whether to float the button with a shadow, for use over a map or
  /// other busy background instead of a plain list background.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = activeCount > 0;

    return Material(
      elevation: elevated ? 3 : 0,
      shadowColor: Colors.black38,
      color: active ? scheme.primary : scheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 16, color: active ? scheme.onPrimary : scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: scheme.onPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$activeCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
