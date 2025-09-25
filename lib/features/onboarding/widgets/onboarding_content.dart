import 'package:flutter/material.dart';
import '../onboarding_page.dart';

class OnboardingContent extends StatelessWidget {
  final OnboardingData data;

  const OnboardingContent({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Image placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: data.color,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}