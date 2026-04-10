import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// Simple location picker without Google Maps dependency
/// Uses current location and manual coordinate input
class SimpleLocationPicker extends StatefulWidget {
  final Function(String address, double lat, double lon) onLocationSelected;

  const SimpleLocationPicker({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoadingCurrentLocation = false;
  bool _isLoadingAddress = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Library Location'),
        backgroundColor: AppColors.getPrimary(context),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current location option
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.my_location, color: AppColors.getPrimary(context)),
                        const SizedBox(width: 8),
                        const Text(
                          'Use Current Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get your current GPS location automatically',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoadingCurrentLocation ? null : _getCurrentLocation,
                        icon: _isLoadingCurrentLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.gps_fixed),
                        label: Text(_isLoadingCurrentLocation ? 'Getting Location...' : 'Use Current Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(context),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Manual coordinate input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_location, color: AppColors.getPrimary(context)),
                        const SizedBox(width: 8),
                        const Text(
                          'Enter Coordinates Manually',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter latitude and longitude if you know the exact coordinates',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              hintText: 'e.g., 28.6139',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _onCoordinatesChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lonController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              hintText: 'e.g., 77.2090',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _onCoordinatesChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address (Optional)',
                        hintText: 'Enter address for this location',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isLoadingAddress
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _canGetAddressFromCoordinates() ? _getAddressFromCoordinates : null,
                            icon: const Icon(Icons.search),
                            label: const Text('Get Address'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _canConfirmManualLocation() ? _confirmManualLocation : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getPrimary(context),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to find coordinates:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. Open Google Maps on your phone\n'
                    '2. Long press on the library location\n'
                    '3. Copy the coordinates that appear\n'
                    '4. Paste them in the fields above',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
      _errorMessage = null;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Please enable in device settings.');
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Get address from coordinates
      String address = 'Current location';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = [
            if (placemark.street?.isNotEmpty == true) placemark.street,
            if (placemark.locality?.isNotEmpty == true) placemark.locality,
            if (placemark.administrativeArea?.isNotEmpty == true) placemark.administrativeArea,
            if (placemark.country?.isNotEmpty == true) placemark.country,
          ].where((part) => part != null && part.isNotEmpty).join(', ');
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      // Confirm location
      widget.onLocationSelected(address, position.latitude, position.longitude);
      Navigator.of(context).pop();

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingCurrentLocation = false;
      });
    }
  }

  void _onCoordinatesChanged(String value) {
    setState(() {
      _errorMessage = null;
    });
  }

  bool _canGetAddressFromCoordinates() {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    return lat != null && lon != null && !_isLoadingAddress;
  }

  bool _canConfirmManualLocation() {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    return lat != null && lon != null && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  Future<void> _getAddressFromCoordinates() async {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    if (lat == null || lon == null) return;

    setState(() {
      _isLoadingAddress = true;
      _errorMessage = null;
    });

    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          if (placemark.street?.isNotEmpty == true) placemark.street,
          if (placemark.locality?.isNotEmpty == true) placemark.locality,
          if (placemark.administrativeArea?.isNotEmpty == true) placemark.administrativeArea,
          if (placemark.country?.isNotEmpty == true) placemark.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');

        setState(() {
          _addressController.text = address.isNotEmpty ? address : 'Address not available';
        });
      } else {
        setState(() {
          _addressController.text = 'Address not available';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get address: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  void _confirmManualLocation() {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    if (lat == null || lon == null) return;

    final address = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : 'Lat: ${lat.toStringAsFixed(6)}, Lon: ${lon.toStringAsFixed(6)}';

    widget.onLocationSelected(address, lat, lon);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}