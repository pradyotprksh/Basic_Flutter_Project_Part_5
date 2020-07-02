import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopapp/model/http_exception.dart';
import 'package:shopapp/providers/product.dart';

class ProductsProvider with ChangeNotifier {
  final String authToken;
  final String userId;

  List<Product> _items = [];

  ProductsProvider(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favItems {
    return _items.where((element) => element.isFavorite).toList();
  }

  Product findById(String id) {
    print(id);
    return _items.firstWhere((element) => element.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    var url = "";
    if (filterByUser) {
      url =
          'https://flutter-update-5c7c6.firebaseio.com/products.json?auth=$authToken&orderBy="userId"&equalTo="$userId"';
    } else {
      url =
      'https://flutter-update-5c7c6.firebaseio.com/products.json?auth=$authToken';
    }
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final List<Product> dummyProduct = [];
      if (extractedData == null) return;
      url =
          'https://flutter-update-5c7c6.firebaseio.com/userFavourites/$userId.json?auth=$authToken';
      final favouriteResponse = await http.get(url);
      final favData = json.decode(favouriteResponse.body);
      extractedData.forEach((productId, productValue) {
        dummyProduct.add(Product(
          id: productId,
          title: productValue['title'],
          description: productValue['description'],
          price: productValue['price'],
          imageUrl: productValue['imageUrl'],
          isFavorite: favData == null ? false : favData[productId] ?? false,
        ));
      });
      _items = dummyProduct;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product editedProduct) async {
    final url =
        'https://flutter-update-5c7c6.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(url,
          body: json.encode({
            'title': editedProduct.title,
            'description': editedProduct.description,
            'imageUrl': editedProduct.imageUrl,
            'price': editedProduct.price,
            'userId': userId
          }));

      final newProduct = Product(
          id: json.decode(response.body)['name'],
          title: editedProduct.title,
          price: editedProduct.price,
          description: editedProduct.description,
          imageUrl: editedProduct.imageUrl);
      _items.insert(0, newProduct);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product updatedProduct) async {
    final index = _items.indexWhere((element) => element.id == id);
    if (index >= 0) {
      final url =
          'https://flutter-update-5c7c6.firebaseio.com/products/$id.json?auth=$authToken';
      try {
        await http.patch(url,
            body: json.encode({
              'title': updatedProduct.title,
              'description': updatedProduct.description,
              'imageUrl': updatedProduct.imageUrl,
              'price': updatedProduct.price
            }));
      } catch (error) {
        throw error;
      }
      _items[index] = updatedProduct;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://flutter-update-5c7c6.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex =
        _items.indexWhere((element) => element.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    var response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException("Could not delete.");
    }
    existingProduct = null;
  }
}
