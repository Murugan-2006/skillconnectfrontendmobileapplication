import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/worker_model.dart';

class AiService extends ChangeNotifier {
  bool _isLoading = false;
  List<WorkerModel> _recommendedWorkers = [];
  List<WorkerModel> _workers = [];
  String _assistantReply = '';

  bool get isLoading => _isLoading;
  List<WorkerModel> get recommendedWorkers => _recommendedWorkers;
  List<WorkerModel> get workers => _workers;
  String get assistantReply => _assistantReply;

  Future<void> fetchWorkersBySkill(
    String skill, {
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String queryParam = 'skill=$skill';
      if (latitude != null && longitude != null) {
        queryParam += '&latitude=$latitude&longitude=$longitude';
      }

      // Build target URLs to try for backend compatibility
      final urlsToTry = [
        '${ApiConfig.baseUrl}/workers?$queryParam',
        '${ApiConfig.baseUrl}/workers',
        'http://127.0.0.1:5000/api/workers?$queryParam',
        'http://10.0.2.2:5000/api/workers?$queryParam',
      ];

      http.Response? response;
      for (final targetUrl in urlsToTry) {
        try {
          final res = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            response = res;
            debugPrint('Successfully fetched workers from $targetUrl');
            break;
          }
        } catch (e) {
          debugPrint('Tried $targetUrl failed: $e');
        }
      }

      if (response != null && response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final fetched = responseData.map((w) => WorkerModel.fromJson(w)).toList();
        if (fetched.isNotEmpty) {
          _workers = fetched;
          debugPrint('Successfully loaded ${_workers.length} workers!');
        }
      }
    } catch (e) {
      debugPrint('Fetch Workers Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getRecommendations({
    required double latitude,
    required double longitude,
    required String skill,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.aiRecommend),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'skill': skill,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _recommendedWorkers = responseData
            .map((w) => WorkerModel.fromJson(w))
            .toList();
      }
    } catch (e) {
      debugPrint('AI Recommendations Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String> queryAssistant(String query) async {
    _isLoading = true;
    _assistantReply = '';
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.aiChat),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _assistantReply = responseData['reply'] ?? '';
      } else {
        _assistantReply = 'Sorry, could not process your query at this moment.';
      }
    } catch (e) {
      debugPrint('AI Assistant Error: $e');
      _assistantReply = 'Connection error. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return _assistantReply;
  }
}
