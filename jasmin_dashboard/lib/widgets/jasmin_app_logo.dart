import 'package:flutter/material.dart';

class JasminAppLogo extends StatelessWidget {
  const JasminAppLogo({super.key, this.size = 88, this.full = false});

  final double size;
  final bool full;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      full
          ? 'assets/images/jasmin_logo_full.png'
          : 'assets/images/jasmin_logo_icon_opaque.png',
      width: full ? size * 1.9 : size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.admin_panel_settings_rounded, size: size);
      },
    );
  }
}
