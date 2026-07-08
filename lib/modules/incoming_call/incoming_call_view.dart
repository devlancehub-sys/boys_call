import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/glowing_avatar.dart';
import 'incoming_call_notifier.dart';

class IncomingCallView extends ConsumerStatefulWidget {
  const IncomingCallView({super.key, this.callData});

  final Map<String, dynamic>? callData;

  @override
  ConsumerState<IncomingCallView> createState() => _IncomingCallViewState();
}

class _IncomingCallViewState extends ConsumerState<IncomingCallView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(incomingCallProvider.notifier);
      notifier.init(widget.callData);
      notifier.startRingtone();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    ref.read(incomingCallProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incomingCallProvider);
    final notifier = ref.read(incomingCallProvider.notifier);

    return PopScope(
      canPop: false,
      child: AppScreen(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1 + (_pulseController.value * 0.18);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 160 * scale,
                          height: 160 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.12),
                          ),
                        ),
                        Container(
                          width: 130 * scale,
                          height: 130 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.18),
                          ),
                        ),
                        child!,
                      ],
                    );
                  },
                  child: GlowingAvatar(
                    avatarUrl: notifier.callerAvatarUrl,
                    name: notifier.callerDisplayName,
                    radius: 57,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Incoming Call',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    notifier.callerDisplayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    '₹${notifier.ratePerMinute.toStringAsFixed(0)}/min from your wallet',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Billed per full minute when you accept',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCircleButton(
                        label: 'Reject',
                        icon: Icons.call_end,
                        color: AppColors.error,
                        loading: state.isLoading,
                        onTap: notifier.rejectCall,
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _ActionCircleButton(
                        label: 'Accept',
                        icon: Icons.call,
                        color: AppColors.online,
                        loading: state.isLoading,
                        onTap: notifier.acceptCall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: AppLoadingIndicator.inline(),
                  )
                : Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
