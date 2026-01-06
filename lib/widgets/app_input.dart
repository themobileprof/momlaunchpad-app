import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Reusable text input field with consistent styling
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceSM),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          enabled: enabled,
          autofocus: autofocus,
          focusNode: focusNode,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          inputFormatters: inputFormatters,
          style: AppTypography.bodyText,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textLight, size: 20)
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled ? AppColors.white : AppColors.backgroundLight,
            contentPadding: const EdgeInsets.all(AppSpacing.spaceMD),
            hintStyle: AppTypography.bodyText.copyWith(
              color: AppColors.textLight.withOpacity(0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primaryPink, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.1)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Password field with visibility toggle
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  const AppPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint ?? '••••••••',
      errorText: widget.errorText,
      prefixIcon: Icons.lock_outlined,
      obscureText: !_isVisible,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
      suffix: IconButton(
        icon: Icon(
          _isVisible ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textLight,
          size: 20,
        ),
        onPressed: () => setState(() => _isVisible = !_isVisible),
      ),
    );
  }
}

/// Search bar with consistent styling
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        style: AppTypography.bodyText,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textLight,
            size: 20,
          ),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceMD,
            vertical: AppSpacing.spaceMD,
          ),
          hintStyle: AppTypography.bodyText.copyWith(
            color: AppColors.textLight.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
