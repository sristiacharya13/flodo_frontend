import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flodo_frontend/providers/task_provider.dart';
import 'package:flodo_frontend/screens/home_screen.dart'; // <--- Import your real UI

void main() {
  // Ensures all Flutter bindings are ready before the app starts
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      // The ..fetchTasks() ensures data loads from FastAPI immediately
      create: (_) => TaskProvider()..fetchTasks(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flodo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo, // Professional look for your Galaxy A04
      ),
      // THIS IS THE KEY CHANGE:
      // We removed the Scaffold/Column/ElevatedButton that was here
      // and replaced it with the HomeScreen widget.
      home: const HomeScreen(), 
    );
  }
}