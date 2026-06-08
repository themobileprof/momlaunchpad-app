import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/auth_screen_widgets.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/auth_error_banner.dart';
import '../providers/service_providers.dart';
import '../utils/referral_helpers.dart';
import '../utils/password_validation.dart';

/// Registration screen — email/password + Google Sign-In
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _googleSignInInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPendingReferral());
  }

  Future<void> _loadPendingReferral() async {
    final pending =
        await ref.read(storageServiceProvider).getPendingReferralCode();
    if (pending != null && pending.isNotEmpty && mounted) {
      _referralController.text = pending;
    }
  }

  Future<void> _persistReferralInput() async {
    final code = referralCodeFromInput(_referralController.text);
    await ref.read(storageServiceProvider).savePendingReferralCode(code ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    await _persistReferralInput();

    try {
      await ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            referralCode: referralCodeFromInput(_referralController.text),
          );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      // Error message is shown via [AuthErrorBanner] from auth state.
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await _persistReferralInput();
    setState(() => _googleSignInInProgress = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      // Error message is shown via [AuthErrorBanner] from auth state.
    } finally {
      if (mounted) setState(() => _googleSignInInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final emailRegisterLoading = authState.isLoading && !_googleSignInInProgress;
    final googleRegisterLoading = authState.isLoading && _googleSignInInProgress;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded),
                  color: context.appPrimary,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.spaceLG,
                    0,
                    AppSpacing.spaceLG,
                    AppSpacing.spaceLG,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthLogoHeader(
                        title: 'Join MomLaunchpad',
                        subtitle: 'Your pregnancy companion — also here if you\'re trying to conceive.',
                        logoSize: 80,
                      ),
                      const SizedBox(height: AppSpacing.spaceXL),
                      if (authState.error != null)
                        AuthErrorBanner(
                          message: authState.error!,
                          onDismiss: () =>
                              ref.read(authProvider.notifier).clearError(),
                        ),
                      GlassContainer(
                        blur: 18,
                        opacity: 0.92,
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusLarge),
                        padding: const EdgeInsets.all(AppSpacing.spaceLG),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create with email',
                                style: AppTypography.label.copyWith(
                                  color: context.appPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.spaceMD),
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  hintText: 'Jane Doe',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  if (value.length < 2) {
                                    return 'Name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.spaceMD),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.spaceMD),
                              TextFormField(
                                controller: _referralController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Referral code (optional)',
                                  hintText: 'Paste code or invite link',
                                  prefixIcon:
                                      Icon(Icons.card_giftcard_outlined),
                                ),
                                onChanged: (_) => _persistReferralInput(),
                              ),
                              const SizedBox(height: AppSpacing.spaceMD),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: '••••••••',
                                  helperText:
                                      'At least $minPasswordLength characters',
                                  prefixIcon:
                                      Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
                                    ),
                                  ),
                                ),
                                validator: validateRegistrationPassword,
                              ),
                              const SizedBox(height: AppSpacing.spaceMD),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Confirm password',
                                  hintText: '••••••••',
                                  prefixIcon:
                                      Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.spaceXL),
                              GradientButton(
                                label: 'Create account',
                                onPressed:
                                    emailRegisterLoading ? null : _handleRegister,
                                isLoading: emailRegisterLoading,
                              ),
                              const SizedBox(height: AppSpacing.spaceLG),
                              const AuthOrDivider(),
                              const SizedBox(height: AppSpacing.spaceLG),
                              GoogleSignInButton(
                                onPressed: _handleGoogleSignIn,
                                isLoading: googleRegisterLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spaceMD),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Already have an account? Sign in',
                          style: AppTypography.bodyTextMedium.copyWith(
                            color: AppColors.rose,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
