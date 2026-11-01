import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

class UploadService {
  final ImagePicker _picker = ImagePicker();

  /// Pick up to 5 compressed images from gallery (70% quality, max 1080p for fast uploads)
  Future<List<XFile>> pickImages({int currentCount = 0}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      final maxAllowed = 5 - currentCount;
      if (images.length > maxAllowed) {
        return images.sublist(0, maxAllowed);
      }
      return images;
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  /// Pick single compressed image from camera
  Future<XFile?> captureImage() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
      );
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  /// Pick or record short video (max 30s)
  Future<XFile?> pickVideo({required ImageSource source}) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );
      return video;
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Upload file using high-performance Multipart streaming with fallback host
  Future<String?> uploadToCloudinary(XFile file, {required String resourceType}) async {
    try {
      final primaryUrl = Uri.parse(ApiConfig.upload);
      final altUrl = Uri.parse(
        ApiConfig.upload.contains('10.0.2.2')
            ? ApiConfig.upload.replaceAll('10.0.2.2', 'localhost')
            : ApiConfig.upload.replaceAll('localhost', '10.0.2.2'),
      );

      final Stopwatch stopwatch = Stopwatch()..start();

      // 1. Try Multipart upload (Fastest binary streaming)
      try {
        final request = http.MultipartRequest('POST', primaryUrl);
        request.fields['resourceType'] = resourceType;
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['url'] != null) {
            debugPrint('[FAST MULTIPART UPLOAD SUCCESS] Uploaded in ${stopwatch.elapsedMilliseconds}ms: ${data['url']}');
            return data['url'] as String;
          }
        }
      } catch (mErr) {
        debugPrint('[MULTIPART FAILED] $mErr. Retrying with fallback server...');
      }

      // 2. Fallback to alternate host multipart upload
      try {
        final request = http.MultipartRequest('POST', altUrl);
        request.fields['resourceType'] = resourceType;
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['url'] != null) {
            debugPrint('[ALT HOST MULTIPART SUCCESS] Uploaded in ${stopwatch.elapsedMilliseconds}ms: ${data['url']}');
            return data['url'] as String;
          }
        }
      } catch (altErr) {
        debugPrint('[ALT MULTIPART FAILED] $altErr. Trying base64 backup...');
      }

      // 3. Last fallback: base64 payload
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = resourceType == 'video' ? 'video/mp4' : 'image/jpeg';

      final response = await http.post(
        primaryUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'base64': base64String,
          'mimeType': mimeType,
          'resourceType': resourceType,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['url'] != null) {
          return data['url'] as String;
        }
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Service Exception: $e');
    }
    return null;
  }
}
