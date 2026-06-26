import 'package:flutter/material.dart';

import '../../../modules/wallet/wallet_view.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WalletView(embeddedInShell: true);
  }
}
