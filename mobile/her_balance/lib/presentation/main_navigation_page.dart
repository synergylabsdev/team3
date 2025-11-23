import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/activity/presentation/pages/activity_page.dart';
import '../features/nutrition/presentation/pages/nutrition_page.dart';
import '../features/calendar/presentation/pages/calendar_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../shared/widgets/svg_icon.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();

  static final GlobalKey<_MainNavigationPageState> navigatorKey =
      GlobalKey<_MainNavigationPageState>();

  static void switchToTab(int index) {
    navigatorKey.currentState?.switchToTab(index);
  }
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = const [
    HomePage(),
    ActivityPage(),
    NutritionPage(),
    CalendarPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.inactiveColor,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        items: [
          BottomNavigationBarItem(
            icon: SvgIcon(
              assetPath: 'assets/home-hashtag.svg',
              color: AppTheme.inactiveColor,
            ),
            activeIcon: SvgIcon(
              assetPath: 'assets/home-hashtag.svg',
              color: AppTheme.primaryColor,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgIcon(
              assetPath: 'assets/chart-2.svg',
              color: AppTheme.inactiveColor,
            ),
            activeIcon: SvgIcon(
              assetPath: 'assets/chart-2.svg',
              color: AppTheme.primaryColor,
            ),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: SvgIcon(
              assetPath: 'assets/nutritions.svg',
              color: AppTheme.inactiveColor,
            ),
            activeIcon: SvgIcon(
              assetPath: 'assets/nutritions.svg',
              color: AppTheme.primaryColor,
            ),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: SvgIcon(
              assetPath: 'assets/calendar.svg',
              color: AppTheme.inactiveColor,
            ),
            activeIcon: SvgIcon(
              assetPath: 'assets/calendar.svg',
              color: AppTheme.primaryColor,
            ),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: SvgIcon(
              assetPath: 'assets/profile-circle.svg',
              color: AppTheme.inactiveColor,
            ),
            activeIcon: SvgIcon(
              assetPath: 'assets/profile-circle.svg',
              color: AppTheme.primaryColor,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
