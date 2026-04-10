import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// Map-based location picker for precise library address selection
class MapLocationPicker extends StatefulWidget {
  final Function(String address, double lat, double lon) onLocationSelected;
  final double? initialLatitude;
  final double? initialLongitude;

  const MapLocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingAddress = false;
  bool _isLoadingCurrentLocation = false;

  // Default location (India center) if no initial location provided
  static const LatLng _defaultLocation = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _getAddressFromCoordinates(_selectedLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Library Location'),
        backgroundColor: AppColors.getPrimary(context),
        foregroundColor: Colors.white,
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: _confirmLocation,
              child: const Text(
                'CONFIRM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? _defaultLocation,
              zoom: _selectedLocation != null ? 16.0 : 5.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onTap: _onMapTapped,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedLocation!,
                      infoWindow: InfoWindow(
                        title: 'Library Location',
                        snippet: _selectedAddress ?? 'Selected location',
                      ),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We'll add our own button
          ),

          // Address display card
          if (_selectedLocation != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.getPrimary(context)),
                          const SizedBox(width: 8),
                          const Text(
                            'Selected Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingAddress)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Getting address...'),
                          ],
                        )
                      else if (_selectedAddress != null)
                        Text(
                          _selectedAddress!,
                          style: const TextStyle(fontSize: 14),
                        )
                      else
                        const Text(
                          'Address not available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Current location button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: AppColors.getPrimary(context),
              child: _isLoadingCurrentLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // Instructions
          if (_selectedLocation == null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                color: AppColors.getPrimary(context).withValues(alpha: 0.9),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Tap on the map to select the library location',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _selectedAddress = null;
    });
    _getAddressFromCoordinates(location);
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          if (placemark.street?.isNotEmpty == true) placemark.street,
          if (placemark.locality?.isNotEmpty == true) placemark.locality,
          if (placemark.administrativeArea?.isNotEmpty == true) placemark.administrativeArea,
          if (placemark.country?.isNotEmpty == true) placemark.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address.isNotEmpty ? address : 'Address not available';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Address not available';
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied');
        return;
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final location = LatLng(position.latitude, position.longitude);

      // Move camera to current location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: location, zoom: 16.0),
          ),
        );
      }

      // Set as selected location
      setState(() {
        _selectedLocation = location;
        _selectedAddress = null;
      });
      _getAddressFromCoordinates(location);

    } catch (e) {
      print('Error getting current location: $e');
      _showError('Failed to get current location: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingCurrentLocation = false;
      });
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      final address = _selectedAddress ?? 'Selected location';
      widget.onLocationSelected(
        address,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}