import 'package:flutter/material.dart';

import '../../../modules/profile/profile_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileView(embeddedInShell: true);
  }
}
