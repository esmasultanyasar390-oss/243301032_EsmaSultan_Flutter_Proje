import 'package:flutter/material.dart';

void main() {
  runApp(MyWidget());
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _LoginScreen();
}

class _LoginScreen extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Kosmetic'),
          backgroundColor: Color.fromARGB(255, 176, 9, 214),
          centerTitle: true,
        ),
        body: Text('Hosgeldiniz'),
        centerTitle: true,
      ),
    );
  }
}
