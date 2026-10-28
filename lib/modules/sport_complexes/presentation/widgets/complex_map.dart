import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sport_platform/core/config/app_config.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

/// El mapa de un complejo: su ubicación marcada sobre teselas de OpenStreetMap. Se puede mover y
/// acercar, pero no elegir otro punto: solo el organizador marca dónde queda.
class ComplexMap extends StatelessWidget {
  static const double _height = 240;
  static const double _markerSize = 44;

  final double latitude;
  final double longitude;

  const ComplexMap({super.key, required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    final position = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: _height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: position,
            initialZoom: AppConfig.mapComplexZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConfig.mapTileUrlTemplate,
              userAgentPackageName: AppConfig.mapUserAgentPackageName,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: position,
                  width: _markerSize,
                  height: _markerSize,
                  // La punta del icono es lo que señala el punto, no su centro.
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.error,
                    size: _markerSize,
                  ),
                ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text(AppConfig.mapAttribution),
            ),
          ],
        ),
      ),
    );
  }
}
