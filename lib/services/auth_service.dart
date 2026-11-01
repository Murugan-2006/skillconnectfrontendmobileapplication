import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthService() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    _token = prefs.getString('token');
    final userDataStr = prefs.getString('userData');
    if (userDataStr != null) {
      _currentUser = UserModel.fromJson(json.decode(userDataStr));
      notifyListeners();

      // Refresh FCM token on startup
      try {
        FirebaseMessaging.instance.getToken().then((fcmToken) {
          if (fcmToken != null) {
            updateFcmToken(fcmToken);
          }
        }).catchError((err) {
          debugPrint('Async FCM Token get error: $err');
        });
      } catch (fcmErr) {
        debugPrint('Failed to refresh FCM Token: $fcmErr');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['token'];
        _currentUser = UserModel.fromJson(responseData['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userData', json.encode(_currentUser!.toJson()));

        // Safely fetch and register FCM token asynchronously
        try {
          FirebaseMessaging.instance.getToken().then((fcmToken) {
            if (fcmToken != null) {
              updateFcmToken(fcmToken);
            }
          }).catchError((fcmErr) {
            debugPrint('Failed to register FCM Token during login: $fcmErr');
          });
        } catch (fcmErr) {
          debugPrint('FCM Token get error: $fcmErr');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Login status failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Login Error: $e');
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }

    return false;
  }

  // Request OTP for registration
  Future<Map<String, String>?> requestRegisterOtp({
    required String email,
    required String phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _isLoading = false;
        notifyListeners();
        return {
          'emailOtp': responseData['emailOtp'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Request OTP Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String password,
    required String street,
    required String district,
    required String taluk,
    required String city,
    required String emailOtp,
    String skill = '',
    String experience = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'role': role,
          'password': password,
          'address': {
            'street': street,
            'district': district,
            'taluk': taluk,
            'city': city,
          },
          'skill': skill,
          'experience': experience,
          'emailOtp': emailOtp,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['token'];
        _currentUser = UserModel.fromJson(responseData['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userData', json.encode(_currentUser!.toJson()));

        // Fetch and register FCM token asynchronously in background
        FirebaseMessaging.instance.getToken().then((fcmToken) {
          if (fcmToken != null) {
            updateFcmToken(fcmToken);
          }
        }).catchError((fcmErr) {
          debugPrint('Failed to register FCM Token during register: $fcmErr');
        });

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Registration Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateFcmToken(String fcmToken) async {
    if (_currentUser == null || _token == null) return false;

    try {
      final response = await http.put(
        Uri.parse(ApiConfig.updateFcmToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'userId': _currentUser!.id,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        _currentUser = UserModel(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          role: _currentUser!.role,
          street: _currentUser!.street,
          district: _currentUser!.district,
          taluk: _currentUser!.taluk,
          city: _currentUser!.city,
          skill: _currentUser!.skill,
          fcmToken: fcmToken,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(_currentUser!.toJson()));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Update FCM Token Error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userData');
    notifyListeners();
  }
}
