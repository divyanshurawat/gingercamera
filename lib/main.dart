import 'package:flutter/material.dart';

import 'camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ginger Camera',
      theme: ThemeData(

        primarySwatch: Colors.red,
      ),
      home: Camera(),
    );
  }
}

