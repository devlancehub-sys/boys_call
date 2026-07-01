import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/widgets/pulsing_glow_rings.dart';
import '../../core/widgets/user_avatar.dart';
import 'calling_notifier.dart';

class CallingView extends ConsumerStatefulWidget {
  const CallingView({super.key, this.args});

  final Map<String, dynamic>? args;

  @override
  ConsumerState<CallingView> createState() => _CallingViewState();
}

class _CallingViewState extends ConsumerState<CallingView> {
  @override
  void initState() {
    super.initState();
    ref.read(callingProvider.notifier).init(widget.args);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callingProvider);
    final notifier = ref.read(callingProvider.notifier);
    final connected = state.status == CallStatus.connected;
    final ended = state.status == CallStatus.ended;

    return PopScope(
      canPop: ended,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && ended) notifier.dismissCall();
      },
      child: AppScreen(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.screenBackgroundAlt),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    connected
                        ? 'On Call'
                        : ended
                            ? 'Call ended'
                            : 'Calling...',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.favorite_rounded, color: AppColors.accent.withValues(alpha: 0.8), size: 16),
                ],
              ),
              const Spacer(),
              PulsingGlowRings(
                size: connected ? 220 : 200,
                child: ClipOval(
                  child: UserAvatarImage(
                    avatarUrl: state.hostAvatarUrl,
                    name: state.hostName,
                    size: connected ? 150 : 130,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                state.hostName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${state.ratePerMinute.toStringAsFixed(0)} / min',
                style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              if (connected)
                Text(
                  state.formattedDuration,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 42,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                )
              else
                Text(
                  _statusText(state.status),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              const SizedBox(height: 8),
              if (!ended)
                Text(
                  connected
                      ? (state.voiceConnected
                          ? 'Billed per full minute (rounded up)'
                          : (state.voiceConnecting || state.voiceAutoRetrying)
                              ? 'Connecting voice...'
                              : 'Voice not connected — tap Retry Voice')
                      : 'Waiting for host to accept...',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              if (connected && !state.voiceConnected && state.voiceLastError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.voiceLastError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error, fontSize: 11),
                  ),
                ),
              const Spacer(),
              if (connected && !state.voiceConnected && !state.voiceConnecting && !state.voiceAutoRetrying)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlowButton(
                    label: 'Retry Voice',
                    icon: Icons.refresh,
                    outlined: true,
                    onPressed: notifier.retryVoice,
                  ),
                ),
              if (connected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CallActionButton(
                      icon: state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: 'Mute',
                      onTap: notifier.toggleMute,
                      active: state.isMuted,
                    ),
                    const SizedBox(width: 36),
                    _EndCallButton(
                      loading: state.isEnding,
                      onTap: notifier.endCall,
                    ),
                    const SizedBox(width: 36),
                    _CallActionButton(
                      icon: state.isSpeakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      label: 'Speaker',
                      onTap: notifier.toggleSpeaker,
                      active: state.isSpeakerOn,
                    ),
                  ],
                )
              else if (ended)
                GlowButton(
                  label: 'Close',
                  icon: Icons.close_rounded,
                  outlined: true,
                  onPressed: notifier.dismissCall,
                )
              else
                GlowButton(
                  label: 'Cancel',
                  icon: Icons.call_end_rounded,
                  outlined: true,
                  loading: state.isEnding,
                  onPressed: notifier.endCall,
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _statusText(CallStatus status) {
    switch (status) {
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call ended';
    }
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.accent.withValues(alpha: 0.18) : AppColors.surface,
              border: Border.all(color: active ? AppColors.accent : AppColors.border),
            ),
            child: Icon(icon, color: active ? AppColors.accent : AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _EndCallButton extends StatelessWidget {
  const _EndCallButton({required this.onTap, required this.loading});

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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error, 
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: AppLoadingIndicator.inline(),
                  )
                : const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        const Text('End Call', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
