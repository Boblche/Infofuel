import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/station.dart';
import '../state/stations_provider.dart';
import '../utils/format.dart';
import '../utils/fuel_type.dart';
import '../utils/station_search.dart';
import '../widgets/empty_state.dart';
import '../widgets/map_fuel_filter_button.dart';
import 'station_detail_sheet.dart';

class StationMapScreen extends StatefulWidget {
  const StationMapScreen({super.key});

  @override
  State<StationMapScreen> createState() => _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _hasCenteredOnUser = false;
  List<Station> _visibleStations = const [];
  List<CitySearchResult> _searchResults = const [];

  @override
  void initState() {
    super.initState();
    _mapController.mapEventStream.listen((event) {
      // Gesture-driven moves (drag, fling, pinch...) only settle the
      // viewport once MapEventMoveEnd fires. Programmatic moves (e.g. a
      // search result selection via mapController.move()) never emit a
      // MoveEnd — they emit a single MapEventMove instead — so those must
      // be handled separately.
      final isGestureEnd = event is MapEventMoveEnd;
      final isProgrammaticMove =
          event is MapEventMove && event.source == MapEventSource.mapController;
      if (isGestureEnd || isProgrammaticMove) _refreshVisibleStations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _refreshVisibleStations() {
    if (!mounted) return;
    final bounds = _mapController.camera.visibleBounds;
    final stations = context.read<StationsProvider>().stationsInBounds(
          south: bounds.south,
          west: bounds.west,
          north: bounds.north,
          east: bounds.east,
        );
    setState(() => _visibleStations = stations);
  }

  void _onSearchChanged(String query) {
    final allStations = context.read<StationsProvider>().allStations;
    setState(() => _searchResults = searchLocations(allStations, query));
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchResults = const []);
  }

  void _selectSearchResult(CitySearchResult result) {
    _searchFocusNode.unfocus();
    _clearSearch();

    final station = result.station;
    _mapController.move(
      LatLng(result.latitude, result.longitude),
      station != null ? 16 : 13,
    );
    if (station != null) {
      StationDetailSheet.show(context, station);
    }
  }

  void _recenterOnUser(Position position) {
    _mapController.move(LatLng(position.latitude, position.longitude), 14);
  }

  @override
  Widget build(BuildContext context) {
    final stationsProvider = context.watch<StationsProvider>();
    final position = stationsProvider.userPosition;

    if (position == null) {
      if (stationsProvider.status == StationsStatus.error) {
        return EmptyState(
          icon: Icons.location_off_outlined,
          iconColor: Theme.of(context).colorScheme.error,
          iconBackgroundColor: Theme.of(context).colorScheme.errorContainer,
          title: 'Impossible de vous localiser',
          message: stationsProvider.errorMessage,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final center = LatLng(position.latitude, position.longitude);

    if (!_hasCenteredOnUser) {
      _hasCenteredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshVisibleStations());
    }

    final focusStation = stationsProvider.focusStation;
    if (focusStation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(
          LatLng(focusStation.latitude, focusStation.longitude),
          16,
        );
        context.read<StationsProvider>().clearMapFocus();
        _refreshVisibleStations();
      });
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            // Rotating the map would rotate the price/text markers with it
            // (upside down at 180°), so the twist gesture is disabled —
            // pan/zoom stay available.
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.infofuel.infofuel',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 26,
                  height: 26,
                  child: const _UserLocationDot(),
                ),
              ],
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 60,
                size: const Size(40, 40),
                markers: [
                  for (final station in _visibleStations)
                    Marker(
                      point: LatLng(station.latitude, station.longitude),
                      width: 90,
                      height: 48,
                      child: _StationMarker(
                        station: station,
                        fuel: stationsProvider.selectedFuel,
                        onTap: () => StationDetailSheet.show(context, station),
                      ),
                    ),
                ],
                builder: (context, markers) => _ClusterMarker(count: markers.length),
              ),
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
              _SearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                results: _searchResults,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
                onSelect: _selectSearchResult,
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: MapFuelFilterButton(),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            onPressed: () => _recenterOnUser(position),
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.results,
    required this.onChanged,
    required this.onClear,
    required this.onSelect,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<CitySearchResult> results;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<CitySearchResult> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Material(
          elevation: 3,
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(28),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher une ville, une adresse…',
              prefixIcon: Icon(Icons.search, color: scheme.primary),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        if (results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 56,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              itemBuilder: (context, index) {
                final result = results[index];
                final isStation = result.station != null;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isStation ? scheme.tertiaryContainer : scheme.primaryContainer,
                    child: Icon(
                      isStation ? Icons.local_gas_station : Icons.location_city,
                      size: 18,
                      color:
                          isStation ? scheme.onTertiaryContainer : scheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(result.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: isStation
                      ? null
                      : Text('${result.stationCount} station(s)'),
                  onTap: () => onSelect(result),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.2),
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
        ),
      ],
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _StationMarker extends StatelessWidget {
  const _StationMarker({
    required this.station,
    required this.fuel,
    required this.onTap,
  });

  final Station station;
  final FuelType? fuel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayedFuel = fuel ?? station.cheapestFuel;
    final price = displayedFuel != null ? station.priceFor(displayedFuel) : null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.tertiary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
            ),
            child: Text(
              price != null ? formatPrice(price) : '?',
              style: TextStyle(
                color: scheme.onTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(Icons.location_on, color: scheme.tertiary, size: 24),
        ],
      ),
    );
  }
}
