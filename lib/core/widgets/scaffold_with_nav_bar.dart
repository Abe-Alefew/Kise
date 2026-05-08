import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'kise_bottom_nav_bar.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Navigates logic back to initial route if the branch is already active
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: KiseBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onItemSelected: _goBranch,
      ),
    );
  }
}
