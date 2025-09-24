import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_config.dart';
import '../../core/services/debug/debug_helper.dart';
import 'settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsController _controller = SettingsController();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Info Section
          _buildAppInfoCard(context),
          const SizedBox(height: 16),

          // Settings Section
          _buildSettingsCard(context),
          const SizedBox(height: 16),

          // Debug Section (only in debug mode)
          if (AppConfig.enableDebugTools) ...[
            _buildDebugCard(context),
            const SizedBox(height: 16),
          ],

          // Actions Section
          _buildActionsCard(context),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('App Name: ${AppConfig.appName}'),
              subtitle: Text('Version: ${AppConfig.version}'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text('Environment: ${AppConfig.environmentName}'),
              subtitle: Text('Debug Mode: ${AppConfig.isDebug}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: _controller.notificationsEnabledNotifier,
              builder: (context, enabled, child) {
                return SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable push notifications'),
                  value: enabled,
                  onChanged: _controller.setNotificationsEnabled,
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _controller.darkModeEnabledNotifier,
              builder: (context, enabled, child) {
                return SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: enabled,
                  onChanged: _controller.setDarkModeEnabled,
                );
              },
            ),
            ValueListenableBuilder<double>(
              valueListenable: _controller.textScaleNotifier,
              builder: (context, scale, child) {
                return ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Text Size'),
                  subtitle: Slider(
                    value: scale,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: '${(scale * 100).round()}%',
                    onChanged: _controller.setTextScale,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Tools',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Log Device Info'),
              subtitle: const Text('Print device information to console'),
              onTap: () => DebugHelper.logDeviceInfo(context),
            ),
            ListTile(
              leading: const Icon(Icons.memory),
              title: const Text('Log Memory Usage'),
              subtitle: const Text('Print memory information to console'),
              onTap: () => DebugHelper.logMemoryUsage(),
            ),
            ListTile(
              leading: const Icon(Icons.border_outer),
              title: const Text('Toggle Debug Paint'),
              subtitle: const Text('Show widget boundaries'),
              onTap: () => DebugHelper.toggleDebugPaintSizeEnabled(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Go to Home'),
              subtitle: const Text('Return to the main screen'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/home'),
            ),
            ListTile(
              leading: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Reset Settings',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              subtitle: const Text('Reset all settings to default'),
              onTap: () {
                _controller.resetSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to default'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}