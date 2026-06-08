import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/auth_screen_widgets.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/auth_error_banner.dart';
import '../providers/auth_provider.dart';
import '../utils/password_validation.dart';
import 'register_screen.dart';

/// Login screen — email/password + Google Sign-In
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _googleSignInInProgress = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (_) {
      // Error message is shown via [AuthErrorBanner] from auth state.
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleSignInInProgress = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (_) {
      // Error message is shown via [AuthErrorBanner] from auth state.
    } finally {
      if (mounted) setState(() => _googleSignInInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final emailLoginLoading = authState.isLoading && !_googleSignInInProgress;
    final googleLoginLoading = authState.isLoading && _googleSignInInProgress;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.spaceLG),
                AuthLogoHeader(
                  title: 'Welcome back',
                  subtitle: 'Your pregnancy companion — also here if you\'re trying to conceive.',
                  logoSize: 96,
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
                  borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
                  padding: const EdgeInsets.all(AppSpacing.spaceLG),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sign in with email',
                          style: AppTypography.label.copyWith(
                            color: context.appPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            helperText:
                                'At least $minPasswordLength characters',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                          ),
                          validator: validateLoginPassword,
                        ),
                        const SizedBox(height: AppSpacing.spaceXL),
                        GradientButton(
                          label: 'Sign in',
                          onPressed: emailLoginLoading ? null : _handleLogin,
                          isLoading: emailLoginLoading,
                          icon: Icons.arrow_forward_rounded,
                        ),
                        const SizedBox(height: AppSpacing.spaceLG),
                        const AuthOrDivider(),
                        const SizedBox(height: AppSpacing.spaceLG),
                        GoogleSignInButton(
                          onPressed: _handleGoogleSignIn,
                          isLoading: googleLoginLoading,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceLG),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTypography.bodyTextMedium.copyWith(
                        color: context.appInkMuted,
                      ),
                      children: [
                        const TextSpan(text: 'New here? '),
                        TextSpan(
                          text: 'Create an account',
                          style: AppTypography.bodyTextMedium.copyWith(
                            color: AppColors.rose,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
