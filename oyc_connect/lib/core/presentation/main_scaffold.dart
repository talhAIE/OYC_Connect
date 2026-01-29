import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when switching branches is to support
      // navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for floating effect over body
      body: navigationShell,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 12, 214, 19),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1B5E20),
            unselectedItemColor: Colors.black.withAlpha(135),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            currentIndex: navigationShell.currentIndex,
            onTap: _goBranch,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: "HOME",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                label: "COMMUNITY",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                label: "DONATE",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: "PROFILE",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
