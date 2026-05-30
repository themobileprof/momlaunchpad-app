import 'package:flutter/material.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Brand row plus page title for use in [MomAppBar] or custom app bars.
class MomAppBarTitle extends StatelessWidget {
  final String pageTitle;
  final Widget? subtitle;

  const MomAppBarTitle({
    super.key,
    required this.pageTitle,
    this.subtitle,
  });

  static const double _logoSize = 36;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: _logoSize,
            height: _logoSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: AppSpacing.spaceSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MomLaunchPad',
                style: AppTypography.appBarBrand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                pageTitle,
                style: AppTypography.pageTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                subtitle!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Consistent app bar with logo, brand name, and page title.
class MomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;
  final Widget? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  const MomAppBar({
    super.key,
    required this.pageTitle,
    this.subtitle,
    this.actions,
    this.leading,
    this.bottom,
    this.automaticallyImplyLeading = true,
  });

  static const double _toolbarHeight = 64;
  static const double _toolbarHeightWithSubtitle = 72;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final toolbarHeight =
        subtitle != null ? _toolbarHeightWithSubtitle : _toolbarHeight;
    return Size.fromHeight(toolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final toolbarHeight =
        subtitle != null ? _toolbarHeightWithSubtitle : _toolbarHeight;
    return AppBar(
      toolbarHeight: toolbarHeight,
      titleSpacing: AppSpacing.spaceSM,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: MomAppBarTitle(
        pageTitle: pageTitle,
        subtitle: subtitle,
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
