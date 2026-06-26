import 'package:flutter/material.dart';

import '../constants/app_gradients.dart';

class BrandTitleText extends StatelessWidget {
  const BrandTitleText({
    super.key,
    this.fontSize = 22,
    this.italic = true,
  });

  final double fontSize;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppGradients.brandText.createShader(bounds),
      child: Text(
        'Love Call',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          letterSpacing: fontSize >= 32 ? 1.2 : 0,
        ),
      ),
    );
  }
}
