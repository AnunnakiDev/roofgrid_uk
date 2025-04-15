mkdir lib\screens\support
echo @"
import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: const Center(child: Text('FAQ Screen')),
    );
  }
}
"@ > lib\screens\support\faq_screen.dart