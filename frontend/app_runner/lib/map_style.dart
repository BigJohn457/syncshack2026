import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Softens standard OSM tiles to match Hey's cream and lavender interface.
Widget heyPastelTileBuilder(
  BuildContext context,
  Widget tileWidget,
  TileImage tile,
) {
  return ColoredBox(
    color: const Color(0xFFF3F1FA),
    child: ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.64,
        0.32,
        0.04,
        0,
        18,
        0.10,
        0.84,
        0.06,
        0,
        14,
        0.10,
        0.34,
        0.56,
        0,
        22,
        0,
        0,
        0,
        0.94,
        0,
      ]),
      child: tileWidget,
    ),
  );
}
