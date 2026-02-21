import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationTrackingService {
  static StreamSubscription<Position>? _sub;

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Starts tracking and writing to `responderLocations/{responderUid}`.
  /// Writes every location update emitted by Geolocator stream.
  StreamSubscription<Position>? startTracking({required String responderUid, int distanceFilterMeters = 15}) {
    stopTracking(); // ensure single stream

    _ensurePermission().then((ok) {
      if (!ok) return;
      final settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilterMeters,
      );

      _sub = Geolocator.getPositionStream(locationSettings: settings).listen((pos) async {
        await FirebaseFirestore.instance.collection('responderLocations').doc(responderUid).set({
          'responderUid': responderUid,
          'location': GeoPoint(pos.latitude, pos.longitude),
          'heading': pos.heading,
          'speed': pos.speed,
          'updatedAt': FieldValue.serverTimestamp(),
          'isTracking': true,
        }, SetOptions(merge: true));
      });
    });

    return _sub;
  }

  Future<void> stopTracking() async {
    await _sub?.cancel();
    _sub = null;
  }
}
