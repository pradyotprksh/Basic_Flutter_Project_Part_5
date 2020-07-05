import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopapp/helpers/custom_route.dart';
import 'package:shopapp/providers/auth_provider.dart';
import 'package:shopapp/providers/cart_provider.dart';
import 'package:shopapp/providers/orders_provider.dart';
import 'package:shopapp/providers/products_provider.dart';
import 'package:shopapp/screens/auth_screen.dart';
import 'package:shopapp/screens/cart_screen.dart';
import 'package:shopapp/screens/orders_screen.dart';
import 'package:shopapp/screens/product_detail_screen.dart';
import 'package:shopapp/screens/product_edit_screen.dart';
import 'package:shopapp/screens/products_overview_screen.dart';
import 'package:shopapp/screens/splash_screen.dart';
import 'package:shopapp/screens/user_products_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProductsProvider>(
          update: (ctx, auth, previousProduct) => ProductsProvider(
              auth.token,
              auth.userId,
              previousProduct == null ? [] : previousProduct.items),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrdersProvider>(
          update: (ctx, auth, previousOrder) => OrdersProvider(auth.token,
              auth.userId, previousOrder == null ? [] : previousOrder.orders),
        ),
      ],
      child: Consumer<AuthProvider>(
          builder: (contextConsumer, authProvider, _) => MaterialApp(
            title: 'MyShop',
                theme: ThemeData(
                  primarySwatch: Colors.purple,
                  accentColor: Colors.deepOrange,
                  fontFamily: 'Lato',
                  pageTransitionsTheme: PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: CustomPageTransitionBuilder(),
                      TargetPlatform.iOS: CustomPageTransitionBuilder(),
                    },
                  ),
                ),
                initialRoute: '/',
                routes: {
                  '/': (context) => authProvider.isAuth
                      ? ProductsOverviewScreen()
                      : FutureBuilder(
                          future: authProvider.tryAutoLogin(),
                          builder: (ctx, authResult) =>
                              authResult.connectionState ==
                                      ConnectionState.waiting
                                  ? SplashScreen()
                                  : AuthScreen(),
                        ),
                  ProductsOverviewScreen.routeName: (context) =>
                      ProductsOverviewScreen(),
                  ProductDetailScreen.routeName: (context) =>
                      ProductDetailScreen(),
                  CartScreen.routeName: (context) => CartScreen(),
                  OrdersScreen.routeName: (context) => OrdersScreen(),
                  UserProductsScreen.routeName: (context) =>
                      UserProductsScreen(),
                  ProductEditScreen.routeName: (context) => ProductEditScreen(),
                  AuthScreen.routeName: (context) => AuthScreen(),
                },
              )),
    );
  }
}
