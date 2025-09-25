import 'package:flutter/material.dart';
import 'lib/core/theme/tokens/app_colors.dart';
import 'lib/core/theme/tokens/app_typography.dart';

void main() {
  runApp(const DesignSystemExampleApp());
}

class DesignSystemExampleApp extends StatelessWidget {
  const DesignSystemExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design System Tokens Example',
      theme: ThemeData(useMaterial3: true),
      home: const DesignSystemExamplePage(),
    );
  }
}

class DesignSystemExamplePage extends StatefulWidget {
  const DesignSystemExamplePage({Key? key}) : super(key: key);

  @override
  State<DesignSystemExamplePage> createState() =>
      _DesignSystemExamplePageState();
}

class _DesignSystemExamplePageState extends State<DesignSystemExamplePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Design System Tokens'),
        centerTitle: true,

        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typography Section
            _buildTypographySection(),
            const SizedBox(height: 32),

            // Color Palette Section
            _buildColorPaletteSection(),
            const SizedBox(height: 32),

            // Basic UI Elements Section
            _buildBasicUISection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),

            boxShadow: [BoxShadow(blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title Large (24px)'),
              const SizedBox(height: 8),
              Text('Title Medium (20px)'),
              const SizedBox(height: 8),
              Text('Title Small (18px)'),
              const SizedBox(height: 8),
              Text('Body Default Primary (16px)'),
              const SizedBox(height: 8),
              Text('Body Default Secondary (16px)'),
              const SizedBox(height: 8),
              Text('Body Default Bold (16px)'),
              const SizedBox(height: 8),

              const SizedBox(height: 8),

              const SizedBox(height: 16),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.normal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Text on Primary Background'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorPaletteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Orange Palette
        _buildColorPaletteCard('Orange (Primary)', AppColors.orange),
        const SizedBox(height: 12),

        // Red Palette
        _buildColorPaletteCard('Red (Error)', AppColors.red),
        const SizedBox(height: 12),

        // Yellow Palette
        _buildColorPaletteCard('Yellow', AppColors.yellow),
        const SizedBox(height: 12),

        // Black Palette
        _buildColorPaletteCard('Black (Secondary)', AppColors.black),
      ],
    );
  }

  Widget _buildColorPaletteCard(String name, ColorPalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),

        boxShadow: [BoxShadow(blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              _buildColorSwatch('Light', palette.light),
              const SizedBox(width: 8),
              _buildColorSwatch('Normal', palette.normal),
              const SizedBox(width: 8),
              _buildColorSwatch('Dark', palette.dark),
              const SizedBox(width: 8),
              _buildColorSwatch('Darker', palette.darker),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBasicUISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic UI Elements Using Tokens'),
        const SizedBox(height: 16),

        // Basic Buttons
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),

            boxShadow: [BoxShadow(blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Primary Button
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.normal,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text('Primary Button', textAlign: TextAlign.center),
                ),
              ),

              const SizedBox(height: 12),

              // Outlined Button
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.normal),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Outlined Button', textAlign: TextAlign.center),
                ),
              ),

              const SizedBox(height: 12),

              // Error Button
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.normal,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text('Error Button', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Basic Input Field
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),

            boxShadow: [BoxShadow(blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Input Field Examples'),
              const SizedBox(height: 12),

              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('이메일을 입력하세요'),
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Information Cards
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.light,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.normal),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: AppColors.primary.normal, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('토큰을 사용한 알림 카드입니다.'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.light,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.normal),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: AppColors.error.normal, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('에러 토큰을 사용한 알림 카드입니다.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
