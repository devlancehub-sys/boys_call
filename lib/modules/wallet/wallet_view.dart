import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/async_body.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/selectable_tile.dart';
import '../../core/widgets/shell_tab_screen.dart';
import 'wallet_notifier.dart';

class WalletView extends ConsumerWidget {
  const WalletView({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletProvider);
    final notifier = ref.read(walletProvider.notifier);

    return ShellTabScreen(
      title: 'Recharge Wallet',
      embeddedInShell: embeddedInShell,
      body: AsyncBody(
        isLoading: state.isLoading,
        loadingWhen: () => state.isLoading && state.transactions.isEmpty,
        builder: () => AppRefreshIndicator(
          onRefresh: notifier.loadAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (embeddedInShell) ...ShellTabScreen.embeddedHeader('Recharge Wallet'),
                _BalanceCard(balance: state.balance),
                const SizedBox(height: 28),
                const SectionHeader.secondary(title: 'Select Amount'),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: WalletNotifier.rechargeAmounts.map((amount) {
                    final isOther = amount == 0;
                    final label = isOther ? 'Other' : '₹$amount';
                    return SelectableTile(
                      label: label,
                      centerLabel: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      selected: isOther
                          ? !WalletNotifier.rechargeAmounts
                              .where((a) => a > 0)
                              .contains(state.selectedAmount)
                          : state.selectedAmount == amount,
                      onTap: () => isOther
                          ? notifier.selectAmount(1000)
                          : notifier.selectAmount(amount),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                const SectionHeader.secondary(title: 'UPI Recommended'),
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _UpiBrand(label: 'GPay', color: Color(0xFF4285F4)),
                    _UpiBrand(label: 'PhonePe', color: Color(0xFF5F259F)),
                    _UpiBrand(label: 'Paytm', color: Color(0xFF00BAF2)),
                  ],
                ),
                const SizedBox(height: 28),
                GlowButton(
                  label: state.selectedAmount > 0
                      ? 'Pay ₹${state.selectedAmount}'
                      : 'Pay',
                  loading: state.isRecharging,
                  onPressed: notifier.paySelected,
                ),
                const SizedBox(height: 32),
                const SectionHeader.secondary(title: 'Recent Transactions'),
                const SizedBox(height: 12),
                ...state.transactions.map((t) => _TransactionTile(transaction: t)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppGradients.accentCard,
        boxShadow: [
          BoxShadow(
            color: AppColors.glow.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpiBrand extends StatelessWidget {
  const _UpiBrand({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Text(
              label[0],
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'] as String? ?? '';
    final amount = transaction['amount'];
    final status = transaction['status'] as String? ?? '';
    final desc = transaction['description'] as String? ?? type;
    final createdAt = transaction['created_at'] as String?;

    final numAmount = amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0;
    final isCredit = numAmount > 0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isCredit ? AppColors.online : AppColors.error).withValues(alpha: 0.12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? AppColors.online : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(color: AppColors.textPrimary)),
                if (createdAt != null)
                  Text(
                    DateFormatter.dateWithTime(createdAt),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : ''}₹${numAmount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: isCredit ? AppColors.online : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(status, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
