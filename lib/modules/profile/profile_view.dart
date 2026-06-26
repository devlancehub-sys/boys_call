import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_body.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glowing_avatar.dart';
import '../../core/widgets/shell_tab_screen.dart';
import 'profile_notifier.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return ShellTabScreen(
      title: 'Profile',
      embeddedInShell: embeddedInShell,
      body: AsyncBody(
        isLoading: state.isLoading,
        builder: () => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (embeddedInShell) ...ShellTabScreen.embeddedHeader('Profile'),
              Center(
                child: GlowingAvatar(
                  avatarUrl: null,
                  name: notifier.nameController.text.isNotEmpty
                      ? notifier.nameController.text
                      : 'User',
                  radius: 48,
                ),
              ),
              const SizedBox(height: 28),
              GlassCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  title: const Text(
                    'Vibrate on incoming call',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    'Phone vibrates when you receive a call',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  secondary: const Icon(
                    Icons.vibration_rounded,
                    color: AppColors.accent,
                  ),
                  value: state.callVibrateEnabled,
                  activeThumbColor: AppColors.accent,
                  onChanged: notifier.setCallVibrateEnabled,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Name', controller: notifier.nameController),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Age',
                controller: notifier.ageController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'About',
                controller: notifier.aboutController,
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              GlowButton(
                label: 'Save Profile',
                loading: state.isSaving,
                onPressed: notifier.saveProfile,
              ),
              const SizedBox(height: 12),
              GlowButton(
                label: 'Update Languages',
                outlined: true,
                icon: Icons.language_rounded,
                onPressed: notifier.openLanguages,
              ),
              const SizedBox(height: 12),
              GlowButton(
                label: 'Logout',
                outlined: true,
                icon: Icons.logout_rounded,
                onPressed: notifier.logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
