import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopapp/model/http_exception.dart';

class AuthProvider with ChangeNotifier {
  String _token;
  DateTime _expireToken;
  String _userId;
  Timer _authTimer;

  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_expireToken != null &&
        _expireToken.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String get userId {
    if (_expireToken != null &&
        _expireToken.isAfter(DateTime.now()) &&
        _userId != null) {
      return _userId;
    }
    return null;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expireToken = null;
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void _autoLogOut() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    final timeToExpiry = _expireToken.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }

  Future<void> authentication(
      String email, String password, String endpoint) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$endpoint?key=<ENTER_API_KEY>';
    try {
      final response = await http.post(url,
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true
          }));
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expireToken = DateTime.now()
          .add(Duration(seconds: int.parse(responseData['expiresIn'])));
      _autoLogOut();
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
          {"_token": _token, "_userId": _userId, "_expireToken": _expireToken.toIso8601String()});

      prefs.setString("userData", userData);
    } catch (error) {
      throw error;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("userData")) {
      return false;
    }
    final extractedUserData = json.decode(prefs.getString("userData")) as Map<String, Object>;
    final expiryDate = DateTime.parse(extractedUserData["_expireToken"]);
    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _token = extractedUserData["_token"];
    _userId = extractedUserData["_userId"];
    _expireToken = expiryDate;
    notifyListeners();
    _autoLogOut();
    return true;
  }

  Future<void> signUp(String email, String password) async {
    return authentication(email, password, 'signUp');
  }

  Future<void> signIn(String email, String password) async {
    return authentication(email, password, 'signInWithPassword');
  }
}
