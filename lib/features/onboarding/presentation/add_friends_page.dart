import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user.dart';
import '../../../shared/photos/avatar.dart';
import '../../../shared/widgets/buttons.dart';
import '../../quests/data/mock_data.dart';
import '../../../core/l10n/labels.dart';

/// Écran 05 (§69) : recherche par pseudo, lien d'invitation, suggestions.
class AddFriendsPage extends ConsumerStatefulWidget {
  const AddFriendsPage({super.key});

  @override
  ConsumerState<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends ConsumerState<AddFriendsPage> {
  final _added = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final suggestions = MockData.suggestions
        .where((f) =>
            _query.isEmpty ||
            f.displayName.toLowerCase().contains(_query.toLowerCase()) ||
            f.username.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(context.l.addFriendsTitle, style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(context.l.addFriendsSubtitle, style: AppTypography.body),
              const SizedBox(height: AppSpacing.md),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                style: AppTypography.bodyStrong,
                decoration: InputDecoration(
                  hintText: context.l.searchUsername,
                  hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface1,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.buttonR,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.buttonR,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.buttonR,
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: context.l.qrCode,
                      icon: Icons.qr_code_rounded,
                      height: 46,
                      onPressed: () => _notImplemented(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: SecondaryButton(
                      label: context.l.inviteLink,
                      icon: Icons.link_rounded,
                      height: 46,
                      onPressed: () => _notImplemented(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: SecondaryButton(
                      label: context.l.contacts,
                      icon: Icons.contacts_outlined,
                      height: 46,
                      onPressed: () => _notImplemented(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l.suggestions,
                style: AppTypography.label.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, i) => _SuggestionRow(
                    friend: suggestions[i],
                    added: _added.contains(suggestions[i].id),
                    onTap: () => setState(() {
                      if (!_added.remove(suggestions[i].id)) _added.add(suggestions[i].id);
                    }),
                  ),
                ),
              ),
              PrimaryButton(
                label: _added.isEmpty
                    ? context.l.later
                    : context.l.continueWithFriends(_added.length),
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _notImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l.backendOnly)),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.friend, required this.added, required this.onTap});

  final Friend friend;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          UserAvatar(seed: friend.id, name: friend.displayName, size: 44),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.displayName, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '@${friend.username} · ${context.l.level(friend.level)}',
                  style: AppTypography.metadata,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppMotion.micro,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 9),
              decoration: BoxDecoration(
                gradient: added ? null : AppColors.primaryGradient,
                color: added ? AppColors.surface2 : null,
                borderRadius: AppRadius.chipR,
                border: Border.all(color: added ? AppColors.border : Colors.transparent),
              ),
              child: Text(
                added ? context.l.added : context.l.add,
                style: AppTypography.metadata.copyWith(
                  color: added ? AppColors.textSecondary : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
