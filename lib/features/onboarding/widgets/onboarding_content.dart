import 'package:flutter/material.dart';
import 'package:frontend/core/theme/design_system.dart';
import '../onboarding_page.dart';

class OnboardingContent extends StatelessWidget {
  final OnboardingData data;

  const OnboardingContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(
          context,
        ).textTheme.apply(fontFamily: 'KakaoSmallSans'),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon/Image placeholder
            Container(
              width: 250,
              height: 250,

              child: ClipRRect(
                child: Image.asset(
                  data.imagePath,
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Title
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLg,
            ),

            const SizedBox(height: 18),

            // Description
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyDefaultBold,
            ),
          ],
        ),
      ),
    );
  }
}
