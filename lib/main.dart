import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loyalty_card_wallet/providers/card_provider.dart';
import 'package:loyalty_card_wallet/screens/home_screen.dart';
import 'package:loyalty_card_wallet/screens/add_card_screen.dart';
import 'package:loyalty_card_wallet/screens/card_details_screen.dart';
import 'package:loyalty_card_wallet/services/camera_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize camera service
  await CameraService.initCameras();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CardProvider(),
      child: MaterialApp(
        title: 'Loyalty Card Wallet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/add-card': (context) => const AddCardScreen(),
          '/card-details': (context) => const CardDetailsScreen(),
        },
      ),
    );
  }
}
