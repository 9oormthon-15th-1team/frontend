import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/state/plus_menu_state.dart';
import 'package:frontend/core/theme/design_system.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return ValueListenableBuilder<bool>(
      valueListenable: PlusMenuState.isExpanded,
      builder: (context, isExpanded, child) {
        final navBar = BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onBottomNavTap,
          selectedItemColor: AppColors.orange.normal,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    'assets/svg/FoldOutlineIcon.svg',
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 0
                          ? AppColors.orange.normal
                          : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: '지도',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: '목록',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
        );

        if (!isExpanded) {
          return navBar;
        }

        return Stack(
          children: [
            navBar,
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => PlusMenuState.isExpanded.value = false,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/pothole');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  void _updateCurrentIndex(String location) {
    int newIndex = 0;
    if (location.startsWith('/home')) {
      newIndex = 0;
    } else if (location.startsWith('/pothole')) {
      newIndex = 1;
    } else if (location.startsWith('/settings')) {
      newIndex = 2;
    }

    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    _updateCurrentIndex(location);
  }
}
