
import 'package:agys_depo_yonetim/pages/beyanname_liste_page.dart';
import 'package:flutter/material.dart';
// import 'pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antrepo Yönetim',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BeyannameListePage(), // LoginPage başlangıç sayfası
      debugShowCheckedModeBanner: false,
    );
  }
}