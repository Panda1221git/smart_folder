import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() {
  runApp(const SmartFolderApp());
}

class SmartFolderApp extends StatelessWidget {
  const SmartFolderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartFolder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
