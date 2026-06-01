import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/community.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Large "+" action anchored above the home bottom navigation (transparent background).
class CommunityComposeFab extends StatelessWidget {
  final CommunityFeedFilter filter;
  final VoidCallback onPressed;

  const CommunityComposeFab({
    super.key,
    required this.filter,
    required this.onPressed,
  });

  bool get _isEventMode => filter == CommunityFeedFilter.events;

  @override
  Widget build(BuildContext context) {
    final label = _isEventMode ? 'Create event' : 'New post';
    final color = context.appPrimary;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(AppRadius.radiusCircle),
          splashColor: color.withValues(alpha: 0.12),
          highlightColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spaceSM),
            child: Icon(
              Icons.add_rounded,
              size: 52,
              weight: 700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical offset so [CommunityComposeFab] sits above the glass bottom nav.
double communityComposeFabBottomOffset(BuildContext context) {
  const navContentHeight = 56.0;
  return AppSpacing.spaceMD +
      navContentHeight +
      AppSpacing.spaceSM +
      MediaQuery.paddingOf(context).bottom;
}
