import 'package:flutter/material.dart';

class NavigationDestinationData {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const NavigationDestinationData({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestinationData> destinations;
  final Widget body;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 768) {
          return Scaffold(
            body: SafeArea(child: body),
            bottomNavigationBar: destinations.isEmpty
                ? null
                : NavigationBar(
                    selectedIndex:
                        selectedIndex.clamp(0, destinations.length - 1),
                    onDestinationSelected: onDestinationSelected,
                    destinations: destinations
                        .map((d) => NavigationDestination(
                              icon: Icon(d.icon),
                              selectedIcon: Icon(d.selectedIcon ?? d.icon),
                              label: d.label,
                            ))
                        .toList(),
                  ),
          );
        }

        final isExtended = width >= 1280;

        return Scaffold(
          body: Row(
            children: [
              if (destinations.isNotEmpty)
                NavigationRail(
                  selectedIndex:
                      selectedIndex.clamp(0, destinations.length - 1),
                  onDestinationSelected: onDestinationSelected,
                  extended: isExtended,
                  minExtendedWidth: 190,
                  destinations: destinations
                      .map((d) => NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.selectedIcon ?? d.icon),
                            label: Text(d.label),
                          ))
                      .toList(),
                ),
              if (destinations.isNotEmpty)
                const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: SafeArea(child: body),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
