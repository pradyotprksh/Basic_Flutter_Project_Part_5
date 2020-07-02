import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopapp/model/http_exception.dart';

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product(
      {@required this.id,
      @required this.title,
      @required this.description,
      @required this.price,
      @required this.imageUrl,
      this.isFavorite = false});

  Future<void> toggleFavStatus(String authToken, String userId) async {
    var previousVal = isFavorite;
    final url =
        'https://flutter-update-5c7c6.firebaseio.com/userFavourites/$userId/$id.json?auth=$authToken';
    try {
      isFavorite = !isFavorite;
      notifyListeners();
      final response = await http.put(url, body: json.encode(isFavorite));
      if (response.statusCode >= 400) {
        isFavorite = previousVal;
        notifyListeners();
        throw HttpException('Not able to toggle fav.');
      }
      previousVal = null;
    } catch (error) {
      isFavorite = previousVal;
      notifyListeners();
      throw HttpException(error.toString());
    }
  }
}
