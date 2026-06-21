import 'package:flutter/material.dart';

class JasminLogo extends StatelessWidget {
  const JasminLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/images/jasmintopup-admin-logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
