import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/labels.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/photos/scene.dart';
import '../../../shared/photos/scene_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/logo.dart';
import '../data/auth_repository.dart';
import '../domain/auth_controller.dart';

/// Écran 03 — compte (§65).
///
/// Un seul écran pour se connecter ou créer un compte : l'étape doit rester
/// courte, elle se glisse entre le choix des intérêts et l'ajout d'amis.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key, this.startOnRegister = false});

  final bool startOnRegister;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late bool _registering = widget.startOnRegister;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = ref.read(authRepositoryProvider);
    try {
      if (_registering) {
        await auth.register(email: _email.text, password: _password.text);
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
      // La redirection est pilotée par l'état d'authentification : rien à
      // pousser ici, le routeur suit.
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _anonymously() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SceneImage(Scene.nightCity),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xE6080C14), Color(0xCC080C14), Color(0xFF080C14)],
                stops: [0.0, 0.4, 0.85],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/splash'),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          const Center(child: QuestLogo(size: 34)),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            _registering ? l.createAccountTitle : l.signInTitle,
                            style: AppTypography.screenTitle,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _registering ? l.createAccountBody : l.signInBody,
                            style: AppTypography.body,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _Field(
                            controller: _email,
                            hint: l.email,
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty || !text.contains('@')) {
                                return l.invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _Field(
                            controller: _password,
                            hint: l.password,
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            autofillHints: [
                              _registering
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            onSubmitted: (_) => _submit(),
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.textTertiary,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            validator: (value) {
                              final text = value ?? '';
                              if (text.isEmpty) return l.passwordRequired;
                              if (_registering && text.length < 6) {
                                return l.passwordTooShort;
                              }
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _ErrorBanner(message: _error!),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            label: _registering ? l.createAccountCta : l.signInCta,
                            loading: _busy,
                            onPressed: _busy ? null : _submit,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _registering = !_registering;
                                        _error = null;
                                      }),
                              child: Text(
                                _registering ? l.switchToSignIn : l.switchToRegister,
                                style: AppTypography.bodyStrong.copyWith(
                                  fontSize: 14,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: AppColors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: Text(l.or, style: AppTypography.metadata),
                              ),
                              const Expanded(child: Divider(color: AppColors.border)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SecondaryButton(
                            label: l.tryWithoutAccount,
                            icon: Icons.bolt_rounded,
                            onPressed: _busy ? null : _anonymously,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Center(
                            child: Text(
                              l.privacyNote,
                              style: AppTypography.metadata,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      textInputAction:
          onSubmitted != null ? TextInputAction.done : TextInputAction.next,
      style: AppTypography.bodyStrong,
      cursorColor: AppColors.primaryLight,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
        suffixIcon: suffix,
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
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.buttonR,
          borderSide: BorderSide(color: AppColors.hard),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.hard.withValues(alpha: 0.12),
        borderRadius: AppRadius.buttonR,
        border: Border.all(color: AppColors.hard.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.hard),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
