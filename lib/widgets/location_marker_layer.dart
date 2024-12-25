// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

class LocationMarker extends StatefulWidget {
  const LocationMarker({Key? key, required this.locationData})
      : super(key: key);
  final Position? locationData;

  @override
  State<LocationMarker> createState() => _LocationMarkerState();
}

class _LocationMarkerState extends State<LocationMarker> {
  @override
  Widget build(BuildContext context) {
    var locationData = widget.locationData;
    if (locationData == null) {
      return Container();
    }
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(locationData.latitude, locationData.longitude),
          child: Transform.rotate(
            angle: 180 + locationData.heading,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 0),
                          blurRadius: 10,
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 23,
                  child: ClipPath(
                    clipper: TriangleClipper(),
                    child: Container(
                      color: Colors.blueAccent,
                      height: 7,
                      width: 7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0.0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}
