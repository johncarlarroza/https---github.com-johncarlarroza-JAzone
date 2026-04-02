import 'dart:convert';
import 'package:http/http.dart' as http;

class RoutePoint {
  final double lat;
  final double lng;

  RoutePoint({required this.lat, required this.lng});
}

class RouteService {
  Future<List<RoutePoint>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '$startLng,$startLat;$endLng,$endLat'
        '?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;

    if (routes == null || routes.isEmpty) return [];

    final geometry = routes.first['geometry'] as Map<String, dynamic>?;
    final coords = geometry?['coordinates'] as List<dynamic>?;

    if (coords == null) return [];

    return coords.map((e) {
      final pair = e as List<dynamic>;
      return RoutePoint(
        lat: (pair[1] as num).toDouble(),
        lng: (pair[0] as num).toDouble(),
      );
    }).toList();
  }
}
