import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../entities/localization_mixin.dart';
import '../tools/shared_pref_tool.dart';
import '../entities/map_tiles.dart';
import '../tools/location_tool.dart';
import '../widgets/location_marker_layer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.tileLayer});

  final TileLayer? tileLayer;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  static const _edgeInsets = EdgeInsets.fromLTRB(8, 8, 8, 8);
  final MapController _mapController = MapController();
  late final TileLayer _tiles = widget.tileLayer ?? MapTiles.osm;
  StreamSubscription<Position>? subscription;
  int _subscriptionGeneration = 0;
  bool _locating = false;

  double? _lat;
  double? _lng;
  double? _heading;

  @override
  bool get wantKeepAlive => true; // this is must

  void _onMapReady() {
    switch (SharedPrefTool.locationFilter) {
      case AppLocale.locationFilterFix:
        _setMapCoord(
          SharedPrefTool.locationFilterLat,
          SharedPrefTool.locationFilterLng,
          animate: true,
        );
      case AppLocale.locationFilterAuto:
        startSubscription();
    }
  }

  String _locationText(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return '';
    }

    return "${lat.abs()}${lat.sign == -1 ? '°S' : '°N'}\r\n${lng.abs()}${lng.sign == -1 ? '°W' : '°E'}";
  }

  Future<void> startSubscription() async {
    stopSubscription();
    final generation = _subscriptionGeneration;
    try {
      final permission = await locationAvailabilityChecker(context);
      if (!mounted ||
          generation != _subscriptionGeneration ||
          !permission.isTrue()) {
        return;
      }
      final settings = await getLocationSettings();
      if (!mounted || generation != _subscriptionGeneration) return;
      bool first = true;
      subscription = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
            (position) {
              if (!mounted || generation != _subscriptionGeneration) return;
              _setMapLocation(position, animate: first);
              first = false;
            },
            onError: (Object error) {
              if (!mounted || generation != _subscriptionGeneration) return;
              stopSubscription();
              _showLocationError();
            },
            cancelOnError: true,
          );
    } catch (_) {
      if (mounted && generation == _subscriptionGeneration) {
        _showLocationError();
      }
    }
  }

  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocale.locationRetrieveFailed.getString(context)),
      ),
    );
  }

  void stopSubscription() {
    _subscriptionGeneration++;
    unawaited(subscription?.cancel());
    subscription = null;
  }

  @override
  void dispose() {
    stopSubscription();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        SharedPrefTool.saveSettings();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocale.locationSelection.getString(context)),
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            final mapWidget = Expanded(
              flex: 3,
              child: FlutterMap(
                options: MapOptions(
                  onMapReady: _onMapReady,
                  initialCenter: const LatLng(0, 0),
                  initialZoom: 4,
                  maxZoom: 18.0,
                  minZoom: 2,
                  cameraConstraint: const CameraConstraint.unconstrained(),
                  keepAlive: true,
                  initialRotation: 0,
                  interactionOptions: const InteractionOptions(
                    flags:
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.doubleTapZoom,
                  ),
                  backgroundColor: Colors.transparent,
                  onTap: (tap, point) {
                    if (SharedPrefTool.locationFilter !=
                        AppLocale.locationFilterFix) {
                      return;
                    }

                    SharedPrefTool.locationFilterLat = point.latitude;
                    SharedPrefTool.locationFilterLng = point.longitude;

                    _setMapCoord(
                      point.latitude,
                      point.longitude,
                      heading: null,
                      animate: true,
                    );
                  },
                ),
                mapController: _mapController,
                children: [
                  // rotated children
                  _tiles,
                  LocationMarker(lat: _lat, lng: _lng, heading: _heading),
                  // non-rotated children
                  RichAttributionWidget(
                    attributions: [TextSourceAttribution('OpenStreetMap.Fr')],
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 15, 0),
                    alignment: Alignment.topRight,
                    child: FloatingActionButton.small(
                      heroTag: Icons.my_location_outlined,
                      backgroundColor: Colors.white,
                      onPressed: () => {
                        _getCurrentLocation(context, animate: true),
                      },
                      shape: const CircleBorder(),
                      child: const IconTheme(
                        data: IconThemeData(color: Colors.black54),
                        child: Icon(Icons.my_location_outlined),
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: _edgeInsets,
                      margin: _edgeInsets,
                      transformAlignment: Alignment.bottomLeft,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        direction: Axis.vertical,
                        children: [
                          Text(
                            _locationText(_lat, _lng),
                            textAlign: TextAlign.left,
                            key: const Key('location_text'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
            final listWidget = Expanded(
              flex: 2,
              child: RadioGroup<String>(
                groupValue: SharedPrefTool.locationFilter,
                onChanged: _changeLocationFilter,
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(
                        AppLocale.locationFilter.getString(context),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    RadioListTile<String>(
                      title: Text(
                        AppLocale.locationFilterAuto.getString(context),
                      ),
                      value: AppLocale.locationFilterAuto,
                    ),
                    RadioListTile<String>(
                      title: Text(
                        AppLocale.locationFilterFix.getString(context),
                      ),
                      value: AppLocale.locationFilterFix,
                    ),
                    RadioListTile<String>(
                      title: Text(
                        AppLocale.locationFilterOff.getString(context),
                      ),
                      value: AppLocale.locationFilterOff,
                    ),
                  ],
                ),
              ),
            );
            return Flex(
              direction: orientation == Orientation.portrait
                  ? Axis.vertical
                  : Axis.horizontal,
              children: [mapWidget, listWidget],
            );
          },
        ),
      ),
    );
  }

  void _changeLocationFilter(String? value) {
    if (value == null || value == SharedPrefTool.locationFilter) return;
    stopSubscription();
    setState(() {
      SharedPrefTool.locationFilter = value;
      _lat = null;
      _lng = null;
      _heading = null;
    });
    if (value == AppLocale.locationFilterAuto) {
      startSubscription();
    } else if (value == AppLocale.locationFilterFix) {
      _setMapCoord(
        SharedPrefTool.locationFilterLat,
        SharedPrefTool.locationFilterLng,
        animate: true,
      );
    }
  }

  void _setMapCoord(
    double lat,
    double lng, {
    double? heading,
    animate = false,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _lat = lat;
      _lng = lng;
      _heading = heading;
    });
    if (animate) {
      _mapController.move(
        LatLng(lat, lng),
        _mapController.camera.zoom > 10 ? _mapController.camera.zoom : 10,
      );
    }
  }

  void _setMapLocation(Position locationData, {animate = false}) {
    _setMapCoord(
      locationData.latitude,
      locationData.longitude,
      heading: locationData.heading,
      animate: animate,
    );
  }

  Future<void> _getCurrentLocation(
    BuildContext context, {
    animate = false,
  }) async {
    if (_locating) return;
    _locating = true;
    final generation = _subscriptionGeneration;
    try {
      final locationData = await getCurrentLocation(context);
      if (!mounted || generation != _subscriptionGeneration) return;
      if (locationData != null) {
        _setMapLocation(locationData, animate: animate);
      } else {
        _showLocationError();
      }
    } finally {
      _locating = false;
    }
  }
}
