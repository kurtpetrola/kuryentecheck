import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/language_provider.dart';
import '../shared/app_strings.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFF0F4C45),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: Colors.grey);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF0F4C45),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return const TextStyle(color: Colors.grey, fontSize: 12);
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          backgroundColor: Colors.white,
          destinations: [
            NavigationDestination(
              icon: const Icon(LucideIcons.home),
              label: AppStrings.tr('nav_report', locale),
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.mapPin),
              label: AppStrings.tr('nav_map', locale),
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.fileText),
              label: AppStrings.tr('nav_feed', locale),
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.user),
              label: AppStrings.tr('nav_profile', locale),
            ),
          ],
        ),
      ),
    );
  }
}
