import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_final_66111741/screens/home_screen.dart';
import 'package:flutter_final_66111741/database/database_helper.dart';
import 'package:flutter_final_66111741/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseService().initialize();
  await DatabaseHelper.instance.init();
  runApp(const ElectionReportApp());
}

class ElectionReportApp extends StatelessWidget {
  const ElectionReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Election Incident Report',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const HomeScreen(),
    );
  }
}
