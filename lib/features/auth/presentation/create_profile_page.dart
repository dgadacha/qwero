import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/photos/avatar.dart';
import '../../../shared/widgets/buttons.dart';
import '../data/auth_repository.dart';
import '../domain/auth_controller.dart';

/// Choix du pseudo (§164).
///
/// Le pseudo est unique et définitif : la réservation passe par une Cloud
/// Function, seule capable de garantir qu'il n'est pris qu'une fois.
class CreateProfilePage extends ConsumerStatefulWidget {
  const CreateProfilePage({super.key});

  @override
  ConsumerState<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends ConsumerState<CreateProfilePage> {
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _busy = false;
  String? _error;

  static final _pattern = RegExp(r'^[a-z0-9_]{3,20}$');

  @override
  void initState() {
    super.initState();
    // L'aperçu de l'avatar suit la saisie : le joueur voit tout de suite à quoi
    // il ressemblera dans le fil de ses amis.
    _displayName.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).createProfile(
            username: _username.text.trim().toLowerCase(),
            displayName: _displayName.text.trim(),
            timezone: DateTime.now().timeZoneName,
            locale: Localizations.localeOf(context).languageCode,
          );
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final name = _displayName.text.trim();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: UserAvatar(
                    seed: _username.text.isEmpty ? 'preview' : _username.text,
                    name: name.isEmpty ? '?' : name,
                    size: 84,
                    ring: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l.profileTitle, style: AppTypography.screenTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(l.profileBody, style: AppTypography.body),
                const SizedBox(height: AppSpacing.lg),
                _ProfileField(
                  controller: _displayName,
                  hint: l.displayName,
                  icon: Icons.badge_outlined,
                  maxLength: 40,
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? l.displayNameRequired : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileField(
                  controller: _username,
                  hint: l.username,
                  icon: Icons.alternate_email_rounded,
                  maxLength: 20,
                  // Le pseudo est stocké en minuscules : le champ doit montrer
                  // ce qui sera réellement enregistré, pas autre chose.
                  capitalization: TextCapitalization.none,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                    _LowerCaseFormatter(),
                  ],
                  onChanged: (_) => setState(() {}),
                  validator: (value) =>
                      _pattern.hasMatch((value ?? '').trim().toLowerCase())
                          ? null
                          : l.usernameRules,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l.usernameRules, style: AppTypography.metadata),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.hard.withValues(alpha: 0.12),
                      borderRadius: AppRadius.buttonR,
                      border: Border.all(color: AppColors.hard.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 18, color: AppColors.hard),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTypography.body.copyWith(fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l.profileCta,
                  loading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => ref.read(authRepositoryProvider).signOut(),
                    child: Text(
                      l.signOut,
                      style: AppTypography.metadata.copyWith(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLength,
    this.formatters,
    this.validator,
    this.onChanged,
    this.capitalization = TextCapitalization.words,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int? maxLength;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      textCapitalization: capitalization,
      autocorrect: capitalization != TextCapitalization.none,
      inputFormatters: formatters,
      validator: validator,
      onChanged: onChanged,
      style: AppTypography.bodyStrong,
      cursorColor: AppColors.primaryLight,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
        counterText: '',
        filled: true,
        fillColor: AppColors.surface1,
        errorStyle: AppTypography.metadata.copyWith(color: AppColors.hard),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
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
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.buttonR,
          borderSide: BorderSide(color: AppColors.hard),
        ),
      ),
    );
  }
}

/// Passe la saisie en minuscules sans déplacer le curseur.
class _LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final lowered = next.text.toLowerCase();
    if (lowered == next.text) return next;
    return next.copyWith(text: lowered, selection: next.selection);
  }
}
