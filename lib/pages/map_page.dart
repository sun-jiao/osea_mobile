import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../entities/localization_mixin.dart';
import '../tools/device_tool.dart';
import '../tools/shared_pref_tool.dart';
import '../entities/map_tiles.dart';
import '../tools/location_tool.dart';
import '../widgets/location_marker_layer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin {
  static const _edgeInsets = EdgeInsets.fromLTRB(8, 8, 8, 8);
  late Widget _tile;
  final MapController _mapController = MapController();

  LocationMarker _currentLocationLayer = const LocationMarker(
    locationData: null,
  );
  final prefs = SharedPrefTool.prefs;
  StreamSubscription? subscription;

  @override
  bool get wantKeepAlive => true; // this is must

  @override
  void initState() {
    _tile = MapTiles.osm;

    // _getMapStates();

    _getCurrentLocation(context, animate: true);
    startSubscription();
    super.initState();
  }

  String _locationText = '';
  String _getLocationText(double lat, double lng) {

    return "${lat.abs()}${lat.sign == -1 ? '°S' : '°N'}\r\n${lng.abs()}${lng.sign == -1 ? '°W' : '°E'}";
  }

  Future<LocationSettings> getLocationSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        forceLocationManager: await DeviceTool().isGoogleAval,
      );
    } else {
      return const LocationSettings();
    }
  }

  startSubscription() async {
    subscription = Geolocator.getPositionStream(
            locationSettings: await getLocationSettings())
        .listen((position) {
      _setMapLocation(position);
    });
  }

  stopSubscription() {
    subscription?.cancel();
    subscription = null;
  }

  @override
  Future<void> dispose() async {
    // onDestroy()
    //something.dispose();
    if (kDebugMode) {
      print("dispose");
    }
    stopSubscription();
    LatLng center = _mapController.camera.center;
    double zoom = _mapController.camera.zoom;
    Position? locationData = _currentLocationLayer.locationData;
    await _saveMapStates(center, zoom, locationData);
    super.dispose();
  }

  Future<void> _saveMapStates(
      LatLng center, double zoom, Position? locationData) async {
    if (locationData != null) {
      final prefs = SharedPrefTool.prefs!;

      await prefs.setDouble('center_latitude', center.latitude);
      await prefs.setDouble('center_longitude', center.longitude);
      await prefs.setDouble('zoom', zoom);
      await prefs.setDouble('latitude', locationData.latitude);
      await prefs.setDouble('longitude', locationData.longitude);
      await prefs.setDouble('heading', locationData.heading);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.locationSelection.getString(context)),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(0, 0),
          initialZoom: 4,
          maxZoom: 18.0,
          minZoom: 2,
          cameraConstraint: const CameraConstraint.unconstrained(),
          keepAlive: true,
          initialRotation: 0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
          ),
          // onPositionChanged: (MapPosition position, bool hasGesture) {},
          backgroundColor: Colors.transparent,
        ),
        mapController: _mapController,
        children: [
          // rotated children
          _tile,  //.call(context),
          _currentLocationLayer,
          // non-rotated children
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap'),
            ],
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(0, 20, 15, 0),
            alignment: Alignment.topRight,
            child: FloatingActionButton.small(
              heroTag: Icons.my_location_outlined,
              backgroundColor: Colors.white,
              onPressed: () => {_getCurrentLocation(context, animate: true)},
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
                  borderRadius: BorderRadius.circular(8)),
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
                    _locationText,
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
  }

  void _setMapLocation(Position locationData, {animate = false}) {
    setState(() {
          _locationText = _getLocationText(
              locationData.latitude,
              locationData.longitude,
          );
          _currentLocationLayer = LocationMarker(locationData: locationData);
          if (animate)
            {
              _mapController.move(
                  LatLng(locationData.latitude, locationData.longitude), 15);
            }
        });
  }

  Future<void> _getCurrentLocation(BuildContext context,
      {animate = false}) async {
    Position? locationData = await getCurrentLocation(context);
    if (locationData != null) {
      _setMapLocation(locationData, animate: animate);
    }
  }
}
