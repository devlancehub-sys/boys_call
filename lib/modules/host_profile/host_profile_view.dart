import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/widgets/glowing_avatar.dart';
import 'host_profile_notifier.dart';

class HostProfileView extends ConsumerStatefulWidget {
  const HostProfileView({super.key, this.host});

  final Map<String, dynamic>? host;

  @override
  ConsumerState<HostProfileView> createState() => _HostProfileViewState();
}

class _HostProfileViewState extends ConsumerState<HostProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hostProfileProvider.notifier).init(widget.host);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hostProfileProvider);
    final notifier = ref.read(hostProfileProvider.notifier);
    final h = state.host;

    if (state.isLoading && h.isEmpty) {
      return const AppScreen(body: AppLoadingIndicator.center());
    }

    final name = h['name']?.toString() ?? 'Host';
    final age = h['age'];
    final about = h['about']?.toString() ?? '';
    final isOnline = h['is_online'] == 1 || h['is_online'] == true;
    final isBusy = h['is_busy'] == 1 || h['is_busy'] == true;
    final rate = h['effective_rate_per_minute'] ?? h['rate_per_minute'];
    final languages = h['languages'] as List? ?? [];
    final langLabel = languages.isNotEmpty
        ? languages.map((l) => l is Map ? l['name']?.toString() : null).whereType<String>().join(', ')
        : 'Hindi';

    return AppScreen(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 340,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.accent.withValues(alpha: 0.25),
                                AppColors.background,
                              ],
                            ),
                          ),
                          child: Center(
                            child: GlowingAvatar(
                              avatarUrl: h['avatar_url']?.toString(),
                              name: name,
                              radius: 80,
                              online: isOnline,
                              busy: isBusy,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.background.withValues(alpha: 0.9),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (age != null) ...[
                              const SizedBox(width: 8),
                              Text('$age', style: const TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                            ],
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent,
                              ),
                              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.accent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$langLabel · Mumbai',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.call_rounded, color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '₹$rate / min',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _TagChip(label: 'Voice Call Only'),
                            _TagChip(label: 'No Chat'),
                          ],
                        ),
                        if (about.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'About Me',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            about,
                            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          isBusy
                              ? 'Busy on a call'
                              : isOnline
                                  ? 'Available now'
                                  : 'Currently offline',
                          style: TextStyle(
                            color: isBusy
                                ? AppColors.busy
                                : isOnline
                                    ? AppColors.online
                                    : AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: isBusy ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glow.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: GlowButton(
              label: isBusy
                  ? 'Call (may be busy)'
                  : isOnline
                      ? 'Call Now'
                      : 'Call (check availability)',
              icon: Icons.call_rounded,
              loading: state.isCalling,
              onPressed: state.isCalling ? null : notifier.startCall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    );
  }
}
