import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Handles profile image picking and uploading to Cloudinary (free tier).
///
/// Setup steps for Cloudinary:
/// 1. Sign up at https://cloudinary.com (free — 25GB storage, 25GB bandwidth).
/// 2. Go to Settings → Upload → Add upload preset.
///    - Name: `profile_pics`  (or anything you like)
///    - Signing Mode: **Unsigned**
///    - Folder: `profile_pics`
///    - Save.
/// 3. Copy your **Cloud Name** from the Dashboard.
/// 4. Paste it below in [_cloudName].
class ProfileService {
  // ── Cloudinary credentials ──
  // TODO: Replace with your Cloudinary cloud name
  static const String _cloudName = 'dr84u6h1p';
  static const String _uploadPreset = 'profile_pics';

  final ImagePicker _picker;

  ProfileService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  /// Pick an image from gallery or camera.
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Upload profile pic to Cloudinary. Returns the secure URL.
  /// Uses unsigned upload with a public_id based on the user's UID
  /// so re-uploads overwrite the old image automatically.
  Future<String> uploadProfilePic(String uid, File imageFile) async {
    final url = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
    debugPrint('☁️ Cloudinary upload → $url');
    debugPrint('☁️ File: ${imageFile.path} (exists: ${imageFile.existsSync()}, size: ${imageFile.lengthSync()} bytes)');
    debugPrint('☁️ Preset: $_uploadPreset | public_id: profile_$uid');

    final uri = Uri.parse(url);

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = 'profile_$uid'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    debugPrint('☁️ Response status: ${response.statusCode}');
    debugPrint('☁️ Response body: $body');

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${response.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = json['secure_url'] as String;
    debugPrint('☁️ Upload success! URL: $secureUrl');
    return secureUrl;
  }
}
