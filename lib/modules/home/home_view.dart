import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_refresh_indicator.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand_title_text.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glowing_avatar.dart';
import '../../core/widgets/section_header.dart';
import 'home_notifier.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    return AppScreen(
      embeddedInShell: embeddedInShell,
      safeBottom: !embeddedInShell,
      body: AppRefreshIndicator(
        onRefresh: notifier.loadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _TopBar(
                balance: state.balance,
                onWalletTap: () => _openWallet(context),
              ),
            ),
            SliverToBoxAdapter(
              child: _SearchBar(onChanged: notifier.setSearchQuery),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader.primary(
                title: 'Online Now',
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              ),
            ),
            _OnlineHostsGrid(
              hosts: state.filteredOnlineHosts,
              onHostTap: notifier.openHostProfile,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  void _openWallet(BuildContext context) {
    if (embeddedInShell) {
      final shell = StatefulNavigationShell.maybeOf(context);
      shell?.goBranch(2);
    } else {
      context.go(AppRoutes.wallet);
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.balance, required this.onWalletTap});

  final double balance;
  final VoidCallback onWalletTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          const BrandTitleText(),
          const Spacer(),
          _WalletChip(balance: balance, onTap: onWalletTap),
        ],
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.balance, required this.onTap});

  final double balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.diamond_outlined, color: AppColors.accent, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                  boxShadow: [
                    BoxShadow(color: AppColors.glow.withValues(alpha: 0.5), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: AppTextField.search(
        onChanged: onChanged,
        suffixIcon: Icon(Icons.tune_rounded, color: AppColors.accent.withValues(alpha: 0.8)),
      ),
    );
  }
}

class _OnlineHostsGrid extends StatelessWidget {
  const _OnlineHostsGrid({required this.hosts, required this.onHostTap});

  final List<Map<String, dynamic>> hosts;
  final void Function(Map<String, dynamic> host) onHostTap;

  @override
  Widget build(BuildContext context) {
    if (hosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 48),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 56, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text(
                'No hosts online right now',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final host = hosts[index];
            return _OnlineHostTile(host: host, onTap: () => onHostTap(host));
          },
          childCount: hosts.length,
        ),
      ),
    );
  }
}

class _OnlineHostTile extends StatelessWidget {
  const _OnlineHostTile({required this.host, required this.onTap});

  final Map<String, dynamic> host;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = host['name']?.toString() ?? 'Host';
    final isOnline = host['is_online'] == 1 || host['is_online'] == true;
    final isBusy = host['is_busy'] == 1 || host['is_busy'] == true;
    final rate = host['effective_rate_per_minute'] ?? host['rate_per_minute'];
    final rateText = rate != null ? '₹$rate/min' : null;

    return GlassCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlowingAvatar(
            avatarUrl: host['avatar_url']?.toString(),
            name: name,
            radius: 34,
            online: isOnline,
            busy: isBusy,
          ),
          const SizedBox(height: 10),
          Text(
            name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (rateText != null) ...[
            const SizedBox(height: 4),
            Text(
              rateText,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          if (isBusy) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.busy.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Busy',
                style: TextStyle(color: AppColors.busy, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
