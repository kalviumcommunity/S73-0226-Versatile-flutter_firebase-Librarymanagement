import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../services/geocoding_service.dart';
import 'simple_location_picker.dart';

/// Professional address input widget with validation and geocoding
class AddressInputWidget extends StatefulWidget {
  final Function(String address, double lat, double lon) onAddressSaved;
  final String? initialAddress;
  final String? hintText;

  const AddressInputWidget({
    super.key,
    required this.onAddressSaved,
    this.initialAddress,
    this.hintText,
  });

  @override
  State<AddressInputWidget> createState() => _AddressInputWidgetState();
}

class _AddressInputWidgetState extends State<AddressInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final GeocodingService _geocodingService = GeocodingService();
  
  bool _isValidating = false;
  String? _errorMessage;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _controller.text = widget.initialAddress!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address input field
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Library Address',
            hintText: widget.hintText ?? 'Enter complete address with street, city, country',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _isValidating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _isValid
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            errorText: _errorMessage,
          ),
          maxLines: 2,
          onChanged: _onAddressChanged,
        ),

        const SizedBox(height: AppDimens.sm),

        // Address format help
        Container(
          padding: const EdgeInsets.all(AppDimens.sm),
          decoration: BoxDecoration(
            color: AppColors.getPrimary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.getPrimary(context),
              ),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Text(
                  'Include street address, city, and country for best results',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getPrimary(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimens.md),

        // Action buttons
        Row(
          children: [
            // Map picker button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map),
                label: const Text('Pick Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.getPrimary(context),
                  side: BorderSide(color: AppColors.getPrimary(context)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Save button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isValid && !_isValidating ? _saveAddress : null,
                icon: _isValidating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isValidating ? 'Validating...' : 'Save Address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimary(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onAddressChanged(String value) {
    setState(() {
      _errorMessage = null;
      _isValid = false;
    });

    // Simple validation - check if address has at least 3 parts
    if (value.trim().isEmpty) return;

    final parts = value.split(',');
    if (parts.length >= 3 && parts.every((part) => part.trim().isNotEmpty)) {
      setState(() {
        _isValid = true;
      });
    }
  }

  Future<void> _saveAddress() async {
    final address = _controller.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final result = await _geocodingService.geocodeAddress(address);

      if (result.success && result.latitude != null && result.longitude != null) {
        // Success - call the callback
        widget.onAddressSaved(
          result.formattedAddress ?? address,
          result.latitude!,
          result.longitude!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address saved successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Failed to validate address';
          _isValid = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating address: ${e.toString()}';
        _isValid = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  void _openMapPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimpleLocationPicker(
          onLocationSelected: (address, lat, lon) {
            setState(() {
              _controller.text = address;
              _isValid = true;
              _errorMessage = null;
            });
            
            // Immediately save the location
            widget.onAddressSaved(address, lat, lon);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location selected successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}