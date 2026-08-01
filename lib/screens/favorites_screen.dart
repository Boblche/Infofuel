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
          title: favoritesProvider.displayName(station),
          isFavorite: true,
          onTap: () => StationDetailSheet.show(context, station),
          onToggleFavorite: () => favoritesProvider.toggle(station),
          onRename: () async {
            final name = await showDialog<String>(
              context: context,
              builder: (_) => _RenameStationDialog(
                initialName: favoritesProvider.customNameFor(station.id) ?? '',
              ),
            );
            if (name == null) return;
            await favoritesProvider.setCustomName(station.id, name);
          },
        );
      },
    );
  }
}

class _RenameStationDialog extends StatefulWidget {
  const _RenameStationDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameStationDialog> createState() => _RenameStationDialogState();
}

class _RenameStationDialogState extends State<_RenameStationDialog> {
  // Owned by this widget's own lifecycle rather than the async showDialog
  // call, so it's only disposed once the dialog is truly unmounted (after
  // its closing transition) — disposing it right when the Future resolves
  // is too early and crashes the still-animating-out TextField.
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renommer la station'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Ex : Total du travail',
          helperText: 'Laisser vide pour revenir à l\'adresse',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
