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
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  static const _edgeInsets = EdgeInsets.fromLTRB(8, 8, 8, 8);
  final MapController _mapController = MapController();
  StreamSubscription? subscription;

  double? _lat;
  double? _lng;
  double? _heading;

  @override
  bool get wantKeepAlive => true; // this is must

  @override
  void initState() {
    switch (SharedPrefTool.locationFilter) {
      case AppLocale.locationFilterOff:
        break;
      case AppLocale.locationFilterFix:
        Future.delayed(Duration(milliseconds: 500)).then((e) {
          _setMapCoord(SharedPrefTool.locationFilterLat,
              SharedPrefTool.locationFilterLng, animate: true);
        });
        break;
      case AppLocale.locationFilterAuto:
        _getCurrentLocation(context, animate: true);
        startSubscription();
        break;
      default:
        break;
    }
    super.initState();
  }

  String _locationText(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return '';
    }

    return "${lat.abs()}${lat.sign == -1 ? '°S' : '°N'}\r\n${lng.abs()}${lng.sign == -1 ? '°W' : '°E'}";
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
    stopSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.locationSelection.getString(context)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(0, 0),
                initialZoom: 4,
                maxZoom: 18.0,
                minZoom: 2,
                cameraConstraint: const CameraConstraint.unconstrained(),
                keepAlive: true,
                initialRotation: 0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
                backgroundColor: Colors.transparent,
                onTap: (tap, point) {
                  if (SharedPrefTool.locationFilter != AppLocale.locationFilterFix) {
                    return;
                  }

                  SharedPrefTool.locationFilterLat = point.latitude;
                  SharedPrefTool.locationFilterLng = point.longitude;

                  _setMapCoord(point.latitude, point.longitude, heading: null, animate: true);
                },
              ),
              mapController: _mapController,
              children: [
                // rotated children
                MapTiles.osm,
                LocationMarker(
                  lat: _lat,
                  lng: _lng,
                  heading: _heading,
                ),
                // non-rotated children
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap.Fr'),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 15, 0),
                  alignment: Alignment.topRight,
                  child: FloatingActionButton.small(
                    heroTag: Icons.my_location_outlined,
                    backgroundColor: Colors.white,
                    onPressed: () =>
                        {_getCurrentLocation(context, animate: true)},
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
          ),
          Expanded(
            flex: 2,
            child: ListView(
              children: [
                ListTile(
                  title: Text(AppLocale.locationFilter.getString(context),
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                RadioListTile<String>(
                  title: Text(AppLocale.locationFilterAuto.getString(context)),
                  value: AppLocale.locationFilterAuto,
                  groupValue: SharedPrefTool.locationFilter,
                  onChanged: (value) {
                    _getCurrentLocation(context, animate: true);
                    startSubscription();
                    setState(() {
                      SharedPrefTool.locationFilter = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppLocale.locationFilterFix.getString(context)),
                  value: AppLocale.locationFilterFix,
                  groupValue: SharedPrefTool.locationFilter,
                  onChanged: (value) {
                    stopSubscription();
                    setState(() {
                      _setMapCoord(SharedPrefTool.locationFilterLat,
                          SharedPrefTool.locationFilterLng, animate: true);

                      SharedPrefTool.locationFilter = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppLocale.locationFilterOff.getString(context)),
                  value: AppLocale.locationFilterOff,
                  groupValue: SharedPrefTool.locationFilter,
                  onChanged: (value) {
                    stopSubscription();
                    setState(() {
                      _lat = null;
                      _lng = null;
                      SharedPrefTool.locationFilter = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setMapCoord(double lat, double lng, {double? heading, animate = false}) {
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
    _setMapCoord(locationData.latitude, locationData.longitude, heading: locationData.heading, animate: animate);
  }

  Future<void> _getCurrentLocation(BuildContext context,
      {animate = false}) async {
    Position? locationData = await getCurrentLocation(context);
    if (locationData != null) {
      _setMapLocation(locationData, animate: animate);
    }
  }
}
