import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glowing_avatar.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/shell_tab_screen.dart';
import 'call_history_notifier.dart';

class CallHistoryView extends ConsumerWidget {
  const CallHistoryView({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  static const _filterLabels = ['All', 'Incoming', 'Outgoing'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(callHistoryProvider);
    final notifier = ref.read(callHistoryProvider.notifier);

    return ShellTabScreen(
      title: 'Call History',
      embeddedInShell: embeddedInShell,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (embeddedInShell) const ScreenTitle(title: 'Call History'),
          const SizedBox(height: 16),
          SegmentedTabs(
            labels: _filterLabels,
            selectedIndex: state.filterTab,
            onChanged: notifier.changeFilter,
          ),
          Expanded(
            child: state.isLoading && state.calls.isEmpty
                ? const AppLoadingIndicator.center()
                : state.filteredCalls.isEmpty
                    ? const EmptyState(message: 'No calls yet')
                    : AppRefreshIndicator(
                        onRefresh: notifier.loadHistory,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: state.filteredCalls.length,
                          itemBuilder: (context, index) =>
                              _CallHistoryTile(call: state.filteredCalls[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  const _CallHistoryTile({required this.call});

  final Map<String, dynamic> call;

  @override
  Widget build(BuildContext context) {
    final partnerName = call['partner_name']?.toString() ?? 'Host';
    final duration = JsonParse.toInt(call['duration_seconds']);
    final status = call['status']?.toString() ?? 'ended';
    final amount = call['amount_deducted'];
    final createdAt = call['created_at']?.toString();

    final numAmount = JsonParse.toDouble(amount);
    final statusLabel = _statusLabel(status);
    final statusColor = _statusColor(status);

    return GlassCard(
      child: Row(
        children: [
          GlowingAvatar(
            avatarUrl: call['partner_avatar']?.toString(),
            name: partnerName,
            radius: 24,
            glow: false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status == 'missed' || status == 'rejected'
                      ? statusLabel
                      : _formatDuration(duration),
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
                if (createdAt != null)
                  Text(
                    DateFormatter.dateTime(createdAt),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (status == 'ended' && numAmount > 0)
            Text(
              '-₹${numAmount.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            )
          else
            Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} min';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'missed':
        return 'Missed';
      case 'rejected':
        return 'Declined';
      case 'ringing':
        return 'Ringing';
      case 'active':
        return 'Active';
      default:
        return 'Completed';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'missed':
        return AppColors.error;
      case 'rejected':
        return AppColors.textMuted;
      default:
        return AppColors.textSecondary;
    }
  }
}
