import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/buttons.dart';
import '../../auth/domain/auth_controller.dart';
import '../../../core/backend/backend_mode.dart';
import '../../../core/l10n/labels.dart';

/// Écran 17 — réglages. Les valeurs par défaut protègent la vie privée (§165).
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  QuestVisibility _visibility = QuestVisibility.friends;
  bool _worldVisible = false;
  bool _sound = true;
  bool _haptics = true;
  bool _dailyPush = true;
  bool _friendPush = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(context.l.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        children: [
          _Section(
            title: context.l.privacy,
            children: [
              _Choice<QuestVisibility>(
                label: context.l.whoSeesMyEntries,
                value: _visibility,
                options: {
                  QuestVisibility.private: context.l.visibilityPrivate,
                  QuestVisibility.friends: context.l.visibilityFriends,
                  QuestVisibility.public: context.l.visibilityPublic,
                },
                onChanged: (value) => setState(() => _visibility = value),
              ),
              _Switch(
                label: context.l.joinPublicWorldQuests,
                subtitle: context.l.joinPublicWorldQuestsBody,
                value: _worldVisible,
                onChanged: (value) => setState(() => _worldVisible = value),
              ),
            ],
          ),
          _Section(
            title: context.l.notifications,
            children: [
              _Switch(
                label: context.l.morningQuests,
                value: _dailyPush,
                onChanged: (value) => setState(() => _dailyPush = value),
              ),
              _Switch(
                label: context.l.friendActivity,
                value: _friendPush,
                onChanged: (value) => setState(() => _friendPush = value),
              ),
            ],
          ),
          _Section(
            title: context.l.feedback,
            children: [
              _Switch(
                label: context.l.sounds,
                value: _sound,
                onChanged: (value) => setState(() => _sound = value),
              ),
              _Switch(
                label: context.l.haptics,
                value: _haptics,
                onChanged: (value) => setState(() => _haptics = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (Backend.isFirebase)
            SecondaryButton(
              label: context.l.signOut,
              icon: Icons.logout_rounded,
              color: AppColors.hard,
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(context.l.prototypeFooter, style: AppTypography.metadata),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(
          title.toUpperCase(),
          style: AppTypography.label.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: AppRadius.cardR,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      title: Text(label, style: AppTypography.bodyStrong.copyWith(fontSize: 14.5)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: AppTypography.metadata),
    );
  }
}

class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodyStrong.copyWith(fontSize: 14.5)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final entry in options.entries)
                GestureDetector(
                  onTap: () => onChanged(entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 7),
                    decoration: BoxDecoration(
                      color: entry.key == value
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surface2,
                      borderRadius: AppRadius.chipR,
                      border: Border.all(
                        color: entry.key == value ? AppColors.borderPrimary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      entry.value,
                      style: AppTypography.metadata.copyWith(
                        color: entry.key == value
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
