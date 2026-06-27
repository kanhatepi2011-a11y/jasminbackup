import 'package:flutter/material.dart';

// Example AppBar title with small JASMIN logo.
PreferredSizeWidget buildJasminLogoAppBar() {
  return AppBar(
    title: Row(
      children: [
        Image.asset(
          'assets/images/jasmin_logo_icon_opaque.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        const Text('JASMIN Dashboard'),
      ],
    ),
  );
}
