import 'package:flutter/material.dart';
import 'package:partiu/features/web_dashboard/screens/events_table_screen.dart';
import 'package:partiu/features/web_dashboard/screens/users_table_screen.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const UsersTableScreen(),
    const EventsTableScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.people),
                selectedIcon: Icon(Icons.people_alt),
                label: Text('Usuários'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event),
                selectedIcon: Icon(Icons.event_available),
                label: Text('Eventos'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
