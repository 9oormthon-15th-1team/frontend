import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTextStyles {
  // Title Large styles
  static final TextStyle titleLargePrimary = AppTypography.titleLg.copyWith(
    color: AppColors.textPrimary,
  );

  static final TextStyle titleLargeSecondary = AppTypography.titleLg.copyWith(
    color: AppColors.textSecondary,
  );

  static final TextStyle titleLargeError = AppTypography.titleLg.copyWith(
    color: AppColors.error.normal,
  );

  static final TextStyle titleLargeOnPrimary = AppTypography.titleLg.copyWith(
    color: AppColors.textOnPrimary,
  );

  // Title Medium styles
  static final TextStyle titleMediumPrimary = AppTypography.titleMd.copyWith(
    color: AppColors.textPrimary,
  );

  static final TextStyle titleMediumSecondary = AppTypography.titleMd.copyWith(
    color: AppColors.textSecondary,
  );

  static final TextStyle titleMediumError = AppTypography.titleMd.copyWith(
    color: AppColors.error.normal,
  );

  static final TextStyle titleMediumOnPrimary = AppTypography.titleMd.copyWith(
    color: AppColors.textOnPrimary,
  );

  // Title Small styles
  static final TextStyle titleSmallPrimary = AppTypography.titleSm.copyWith(
    color: AppColors.textPrimary,
  );

  static final TextStyle titleSmallSecondary = AppTypography.titleSm.copyWith(
    color: AppColors.textSecondary,
  );

  static final TextStyle titleSmallError = AppTypography.titleSm.copyWith(
    color: AppColors.error.normal,
  );

  static final TextStyle titleSmallOnPrimary = AppTypography.titleSm.copyWith(
    color: AppColors.textOnPrimary,
  );

  // Body Default styles
  static final TextStyle bodyDefaultPrimary = AppTypography.bodyDefault
      .copyWith(color: AppColors.textPrimary);

  static final TextStyle bodyDefaultSecondary = AppTypography.bodyDefault
      .copyWith(color: AppColors.textSecondary);

  static final TextStyle bodyDefaultError = AppTypography.bodyDefault.copyWith(
    color: AppColors.error.normal,
  );

  static final TextStyle bodyDefaultOnPrimary = AppTypography.bodyDefault
      .copyWith(color: AppColors.textOnPrimary);

  // Body Default Bold styles
  static final TextStyle bodyDefaultBoldPrimary = AppTypography.bodyDefaultBold
      .copyWith(color: AppColors.textPrimary);

  static final TextStyle bodyDefaultBoldSecondary = AppTypography
      .bodyDefaultBold
      .copyWith(color: AppColors.textSecondary);

  static final TextStyle bodyDefaultBoldError = AppTypography.bodyDefaultBold
      .copyWith(color: AppColors.error.normal);

  static final TextStyle bodyDefaultBoldOnPrimary = AppTypography
      .bodyDefaultBold
      .copyWith(color: AppColors.textOnPrimary);

  // Body Small styles
  static final TextStyle bodySmallPrimary = AppTypography.bodySm.copyWith(
    color: AppColors.textPrimary,
  );

  static final TextStyle bodySmallSecondary = AppTypography.bodySm.copyWith(
    color: AppColors.textSecondary,
  );

  static final TextStyle bodySmallError = AppTypography.bodySm.copyWith(
    color: AppColors.error.normal,
  );

  static final TextStyle bodySmallOnPrimary = AppTypography.bodySm.copyWith(
    color: AppColors.textOnPrimary,
  );

  // Caption styles
  static final TextStyle captionPrimary = AppTypography.caption.copyWith(
    color: AppColors.textPrimary,
  );

  static final TextStyle captionSecondary = AppTypography.caption.copyWith(
    color: AppColors.textSecondary,
  );

  static final TextStyle captionError = AppTypography.caption.copyWith(
    color: AppColors.error.normal,
  );

  static final TextStyle captionOnPrimary = AppTypography.caption.copyWith(
    color: AppColors.textOnPrimary,
  );

  // Helper method to get all text styles
  static Map<String, TextStyle> get styles => {
    // Title Large
    'titleLargePrimary': titleLargePrimary,
    'titleLargeSecondary': titleLargeSecondary,
    'titleLargeError': titleLargeError,
    'titleLargeOnPrimary': titleLargeOnPrimary,

    // Title Medium
    'titleMediumPrimary': titleMediumPrimary,
    'titleMediumSecondary': titleMediumSecondary,
    'titleMediumError': titleMediumError,
    'titleMediumOnPrimary': titleMediumOnPrimary,

    // Title Small
    'titleSmallPrimary': titleSmallPrimary,
    'titleSmallSecondary': titleSmallSecondary,
    'titleSmallError': titleSmallError,
    'titleSmallOnPrimary': titleSmallOnPrimary,

    // Body Default
    'bodyDefaultPrimary': bodyDefaultPrimary,
    'bodyDefaultSecondary': bodyDefaultSecondary,
    'bodyDefaultError': bodyDefaultError,
    'bodyDefaultOnPrimary': bodyDefaultOnPrimary,

    // Body Default Bold
    'bodyDefaultBoldPrimary': bodyDefaultBoldPrimary,
    'bodyDefaultBoldSecondary': bodyDefaultBoldSecondary,
    'bodyDefaultBoldError': bodyDefaultBoldError,
    'bodyDefaultBoldOnPrimary': bodyDefaultBoldOnPrimary,

    // Body Small
    'bodySmallPrimary': bodySmallPrimary,
    'bodySmallSecondary': bodySmallSecondary,
    'bodySmallError': bodySmallError,
    'bodySmallOnPrimary': bodySmallOnPrimary,

    // Caption
    'captionPrimary': captionPrimary,
    'captionSecondary': captionSecondary,
    'captionError': captionError,
    'captionOnPrimary': captionOnPrimary,
  };
}
