import 'package:flutter/material.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: const Center(
        child: Text('Your upcoming trips will appear here'),
      ),
    );
  }
}
