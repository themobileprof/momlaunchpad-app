import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/image_url.dart';

/// Avatar sizes
enum AppAvatarSize { small, medium, large, xlarge }

/// Reusable avatar widget
class AppAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final AppAvatarSize size;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool showOnlineIndicator;
  final bool isOnline;

  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = AppAvatarSize.medium,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  double get _size {
    switch (size) {
      case AppAvatarSize.small:
        return 32;
      case AppAvatarSize.medium:
        return 48;
      case AppAvatarSize.large:
        return 64;
      case AppAvatarSize.xlarge:
        return 96;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppAvatarSize.small:
        return 14;
      case AppAvatarSize.medium:
        return 18;
      case AppAvatarSize.large:
        return 24;
      case AppAvatarSize.xlarge:
        return 36;
    }
  }

  String get _initials {
    if (name == null || name!.isEmpty) return 'U';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveMediaUrl(imageUrl);
    Widget avatar = Stack(
      children: [
        Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.primaryPurple.withOpacity(0.15),
            shape: BoxShape.circle,
            image: resolvedUrl != null
                ? DecorationImage(
                    image: NetworkImage(resolvedUrl),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  )
                : null,
          ),
          child: resolvedUrl == null
              ? Center(
                  child: Text(
                    _initials,
                    style: AppTypography.headingMedium.copyWith(
                      fontSize: _fontSize,
                      color: textColor ?? AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: _size * 0.3,
              height: _size * 0.3,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.textLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
