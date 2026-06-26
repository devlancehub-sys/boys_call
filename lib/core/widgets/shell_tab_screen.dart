import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_screen.dart';
import 'screen_title.dart';

class ShellTabScreen extends StatelessWidget {
  const ShellTabScreen({
    super.key,
    required this.title,
    required this.body,
    this.embeddedInShell = false,
  });

  final String title;
  final Widget body;
  final bool embeddedInShell;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      embeddedInShell: embeddedInShell,
      safeBottom: !embeddedInShell,
      appBar: embeddedInShell ? null : _appBar(title),
      body: body,
    );
  }

  static PreferredSizeWidget _appBar(String title) {
    return AppBar(
      backgroundColor: AppColors.background,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
    );
  }

  /// Embedded shell title + spacing for scrollable tab content.
  static List<Widget> embeddedHeader(String title) {
    return [
      ScreenTitle(title: title),
      const SizedBox(height: 20),
    ];
  }
}
