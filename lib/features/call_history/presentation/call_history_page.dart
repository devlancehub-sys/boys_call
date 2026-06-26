import 'package:flutter/material.dart';

import '../../../modules/call_history/call_history_view.dart';

class CallHistoryPage extends StatelessWidget {
  const CallHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CallHistoryView(embeddedInShell: true);
  }
}
