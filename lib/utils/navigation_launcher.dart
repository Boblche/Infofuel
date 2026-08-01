import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/station.dart';

class _NavigationApp {
  const _NavigationApp({
    required this.label,
    required this.icon,
    required this.urlFor,
  });

  final String label;
  final IconData icon;
  final Uri Function(Station station) urlFor;
}

final _navigationApps = [
  _NavigationApp(
    label: 'Waze',
    icon: Icons.navigation,
    urlFor: (station) => Uri.parse(
      'https://waze.com/ul?ll=${station.latitude},${station.longitude}&navigate=yes',
    ),
  ),
  _NavigationApp(
    label: 'Google Maps',
    icon: Icons.map,
    urlFor: (station) => Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}',
    ),
  ),
];

/// Shows a bottom sheet letting the user pick which external GPS app should
/// open directions to [station].
Future<void> openNavigationChooser(BuildContext context, Station station) {
  return showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final app in _navigationApps)
            ListTile(
              leading: Icon(app.icon),
              title: Text(app.label),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                var launched = false;
                try {
                  launched = await launchUrl(
                    app.urlFor(station),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {
                  launched = false;
                }
                if (!launched && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Impossible d\'ouvrir ${app.label}.'),
                    ),
                  );
                }
              },
            ),
        ],
      ),
    ),
  );
}
