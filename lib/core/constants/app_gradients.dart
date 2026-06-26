import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  static const screenBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF120810), Color(0xFF0A0A0A)],
  );

  static const screenBackgroundAlt = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF120810), Color(0xFF0A0A0A), Color(0xFF0A0A0A)],
  );

  static const brandText = LinearGradient(
    colors: [Colors.white, AppColors.accentLight],
  );

  static const accentCard = LinearGradient(
    colors: [AppColors.accent, AppColors.accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
