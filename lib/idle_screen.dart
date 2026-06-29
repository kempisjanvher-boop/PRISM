import 'package:flutter/material.dart';

class IdleScreen extends StatefulWidget {
  final VoidCallback onDismiss;

  const IdleScreen({super.key, required this.onDismiss});

  @override
  State<IdleScreen> createState() => _IdleScreenState();
}

class _IdleScreenState extends State<IdleScreen> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Scaffold(
        body: Image.asset(
          'asset/IDLE SCREEN.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
