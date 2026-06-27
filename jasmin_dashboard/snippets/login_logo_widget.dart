import 'package:flutter/material.dart';

// Put this above the login form in your admin login screen.
Widget buildJasminLoginLogo() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Image.asset(
      'assets/images/jasmin_logo_icon_opaque.png',
      width: 82,
      height: 82,
      fit: BoxFit.contain,
    ),
  );
}
