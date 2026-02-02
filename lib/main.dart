import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/lista_productos.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización robusta para Web
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDrAWkqX5RzkdGTXe4TNgurS0sSCLudYWU",
        authDomain: "bodegapwa.firebaseapp.com",
        projectId: "bodegapwa",
        storageBucket: "bodegapwa.firebasestorage.app",
        messagingSenderId: "418246762612",
        appId: "1:418246762612:web:635e1c669f7f2817a37121",
      ),
    );
  } catch (e) {
    debugPrint("Firebase ya estaba listo: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Bodega 24/7',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed:
            Colors.orange, // Cambia el look "hospital" por algo moderno
        brightness: Brightness.light,
      ),
      home: const ListaProductosScreen(),
    );
  }
}
