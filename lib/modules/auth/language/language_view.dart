import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/parse_utils.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/async_body.dart';
import '../../../core/widgets/glow_button.dart';
import '../../../core/widgets/pulsing_glow_rings.dart';
import '../../../core/widgets/selectable_tile.dart';
import 'language_notifier.dart';

class LanguageView extends ConsumerStatefulWidget {
  const LanguageView({super.key, this.fromProfile = false});

  final bool fromProfile;

  @override
  ConsumerState<LanguageView> createState() => _LanguageViewState();
}

class _LanguageViewState extends ConsumerState<LanguageView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(languageProvider.notifier).init(fromProfile: widget.fromProfile);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(languageProvider);
    final notifier = ref.read(languageProvider.notifier);

    return AppScreen(
      body: AsyncBody(
        isLoading: state.isLoading,
        builder: () => Column(
          children: [
            const SizedBox(height: 32),
            PulsingGlowRings(
              size: 100,
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                child: const Icon(Icons.language_rounded, color: AppColors.accent, size: 36),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Language',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your preferred language(s)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: state.languages.length,
                itemBuilder: (context, index) {
                  final lang = state.languages[index];
                  final id = JsonParse.toInt(lang['id']);
                  final name = lang['name'] as String? ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableTile(
                      label: name,
                      selected: state.selectedIds.contains(id),
                      onTap: () => notifier.toggleLanguage(id),
                      borderRadius: 16,
                      showCheck: true,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: GlowButton(
                label: state.fromProfile ? 'Save Languages' : 'Continue',
                loading: state.isSaving,
                onPressed: notifier.saveLanguages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
