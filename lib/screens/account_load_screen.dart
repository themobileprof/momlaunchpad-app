import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/widgets.dart';

/// Shown when the user is signed in but their profile could not be loaded.
/// Prevents skipping onboarding or entering Home with a broken session.
class AccountLoadScreen extends ConsumerWidget {
  const AccountLoadScreen({
    super.key,
    required this.errorMessage,
  });

  final String errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.account_circle_outlined,
        title: 'We couldn\'t load your account',
        description: errorMessage,
        actionLabel: 'Try again',
        onAction: () => ref.read(profileProvider.notifier).loadProfile(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Sign out and start over',
            variant: AppButtonVariant.secondary,
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ),
      ),
    );
  }
}
