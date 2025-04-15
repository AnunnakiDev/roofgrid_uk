import 'package:flutter/material.dart';

class TilesScreen extends StatelessWidget {
  const TilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiles')),
      body: const Center(child: Text('Tiles Screen')),
    );
  }
}
