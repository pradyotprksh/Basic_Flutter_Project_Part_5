import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopapp/providers/cart_provider.dart';
import 'package:shopapp/providers/orders_provider.dart';
import 'package:shopapp/widgets/cart_item.dart' as SingleCartItem;

class CartScreen extends StatefulWidget {
  static const routeName = 'cart_screen';

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  var _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart'),
      ),
      body: Column(
        children: <Widget>[
          Card(
            margin: EdgeInsets.all(15),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 20),
                  ),
                  Spacer(),
                  Chip(
                    label: Text(
                      '\$${cartProvider.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color:
                            Theme.of(context).primaryTextTheme.headline1.color,
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  FlatButton(
                    onPressed: (cartProvider.totalAmount <= 0 || _isLoading)
                        ? null
                        : () async {
                            try {
                              setState(() {
                                _isLoading = true;
                              });
                              await Provider.of<OrdersProvider>(context,
                                      listen: false)
                                  .addOrders(cartProvider.items.values.toList(),
                                      cartProvider.totalAmount);
                              cartProvider.clearCart();
                            } catch (error) {
                              await showDialog(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertDialog(
                                      title: Text('An Error Occurred'),
                                      content: Text(error.toString()),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text('Okay'),
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                          },
                                        )
                                      ],
                                    );
                                  });
                            }
                            setState(() {
                              _isLoading = false;
                            });
                          },
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text(
                            'Order Now',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor),
                          ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                return SingleCartItem.CartItem(
                    cartProvider.items.keys.toList()[index],
                    cartProvider.items.values.toList()[index].id,
                    cartProvider.items.values.toList()[index].price,
                    cartProvider.items.values.toList()[index].quantity,
                    cartProvider.items.values.toList()[index].title);
              },
              itemCount: cartProvider.items.length,
            ),
          )
        ],
      ),
    );
  }
}
