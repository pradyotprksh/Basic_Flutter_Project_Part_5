import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shopapp/model/http_exception.dart';
import 'package:shopapp/providers/cart_provider.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem(this.id, this.amount, this.products, this.dateTime);
}

class OrdersProvider with ChangeNotifier {
  final String authToken;
  final String userId;
  List<OrderItem> _orders = [];

  OrdersProvider(this.authToken, this.userId, this._orders);

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    final url = 'https://flutter-update-5c7c6.firebaseio.com/orders/$userId.json?auth=$authToken';
    try {
      final response = await http.get(url);
      final List<OrderItem> loadedOrders = [];
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) return;
      extractedData.forEach((key, value) {
        loadedOrders.add(OrderItem(
            key,
            value['price'],
            (value['products'] as List<dynamic>)
                .map((e) => CartItem(
                      e['id'],
                      e['title'],
                      e['quantity'],
                      e['price'],
                    ))
                .toList(),
            DateTime.parse(value['dateTime'])));
      });
      _orders = loadedOrders.reversed.toList();
      notifyListeners();
    } catch (error) {
      throw HttpException(error.toString());
    }
  }

  Future<void> addOrders(List<CartItem> cartProducts, double price) async {
    var time = DateTime.now();
    final url = 'https://flutter-update-5c7c6.firebaseio.com/orders/$userId.json?auth=$authToken';
    try {
      final response = await http.post(url,
          body: json.encode({
            'price': price,
            'dateTime': time.toIso8601String(),
            'products': cartProducts
                .map((e) => {
                      'id': e.id,
                      'title': e.title,
                      'quantity': e.quantity,
                      'price': e.price,
                    })
                .toList()
          }));
      if (response.statusCode >= 400) {
        throw HttpException('Not able to place order');
      } else {
        _orders.insert(
            0,
            OrderItem(
                json.decode(response.body)['name'], price, cartProducts, time));
      }
      notifyListeners();
    } catch (error) {
      throw HttpException(error.toString());
    }
  }
}
