// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

class LocationMarker extends StatefulWidget {
  const LocationMarker({Key? key, this.lat, this.lng, this.heading})
      : super(key: key);
  final double? lat;
  final double? lng;
  final double? heading;

  @override
  State<LocationMarker> createState() => _LocationMarkerState();
}

class _LocationMarkerState extends State<LocationMarker> {
  @override
  Widget build(BuildContext context) {
    if (widget.lat == null || widget.lng == null) {
      return Container();
    }
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(widget.lat!, widget.lng!),
          child: Transform.rotate(
            angle: 180 + (widget.heading ?? 0),
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
                if (widget.heading != null)
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
