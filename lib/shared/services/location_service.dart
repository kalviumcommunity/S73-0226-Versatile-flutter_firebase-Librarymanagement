import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling location operations, GPS, and distance calculations
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _cachedLocation;
  DateTime? _cacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Request location permission from user
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Permission.location.request();
      return permission == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current user location with caching
  Future<Position?> getCurrentLocation() async {
    try {
      // Return cached location if still valid
      if (_cachedLocation != null && 
          _cacheTime != null && 
          DateTime.now().difference(_cacheTime!).compareTo(_cacheTimeout) < 0) {
        return _cachedLocation;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Cache the location
      _cachedLocation = position;
      _cacheTime = DateTime.now();

      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '${meters}m away';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km away';
    }
  }

  /// Cache user location manually
  void cacheUserLocation(Position position) {
    _cachedLocation = position;
    _cacheTime = DateTime.now();
  }

  /// Get cached location if available
  Position? getCachedLocation() {
    if (_cachedLocation != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!).compareTo(_cacheTimeout) < 0) {
      return _cachedLocation;
    }
    return null;
  }

  /// Clear cached location
  void clearCache() {
    _cachedLocation = null;
    _cacheTime = null;
  }
}