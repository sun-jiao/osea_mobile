import 'package:flutter_map/flutter_map.dart';

class MapTiles {
  static const _packageName = 'net.sunjiao.birdid';

  static TileLayer get osm => TileLayer(
    tileProvider: NetworkTileProvider(silenceExceptions: true),
    urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    userAgentPackageName: _packageName,
    subdomains: const ['a', 'b', 'c'],
  );
}
