import 'package:flutter_map/flutter_map.dart';

import 'cache_tile_provider.dart'; // Suitable for most situations

class MapTiles {
  static const _packageName = 'com.example.birdid';

  static final TileLayer osm = TileLayer(
    tileProvider: CacheTileProvider('osm'),
    urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    userAgentPackageName: _packageName,
    subdomains: const ['a', 'b', 'c'],
  );
}
