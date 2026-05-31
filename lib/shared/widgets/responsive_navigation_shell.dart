import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_system.dart';

class ResponsiveNavigationShell extends StatelessWidget {
  final String currentPath;
  final Widget child;

  const ResponsiveNavigationShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  int _getSelectedIndex() {
    switch (currentPath) {
      case '/dashboard':
        return 0;
      case '/tasks':
        return 1;
      case '/habits':
        return 2;
      case '/journal':
        return 3;
      case '/settings':
        return 4;
      default:
        return 0;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/tasks');
        break;
      case 2:
        context.go('/habits');
        break;
      case 3:
        context.go('/journal');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth >= 900;
    final int selectedIndex = _getSelectedIndex();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isLargeScreen) ...[
            _buildSidebar(context, selectedIndex),
            const VerticalDivider(width: 1, color: Colors.white10),
          ],
          Expanded(
            child: SafeArea(
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isLargeScreen ? _buildBottomNavigationBar(context, selectedIndex) : null,
    );
  }

  // Sidebar Layout for Web/Tablet Landscape/Desktop
  Widget _buildSidebar(BuildContext context, int selectedIndex) {
    return Container(
      width: 260,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bubble_chart, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                "LifeFlow",
                style: AppTextStyles.titleMedium.copyWith(fontSize: 24, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 36),
          // Navigation Items
          Expanded(
            child: ListView(
              children: [
                _buildSidebarItem(context, Icons.dashboard_outlined, Icons.dashboard, "Dashboard", 0, selectedIndex),
                _buildSidebarItem(context, Icons.task_alt_outlined, Icons.task_alt, "Tasks", 1, selectedIndex),
                _buildSidebarItem(context, Icons.autorenew_outlined, Icons.autorenew, "Habits", 2, selectedIndex),
                _buildSidebarItem(context, Icons.book_outlined, Icons.book, "Journal", 3, selectedIndex),
                _buildSidebarItem(context, Icons.settings_outlined, Icons.settings, "Settings", 4, selectedIndex),
              ],
            ),
          ),
          // User profile card preview at the bottom
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppDecorations.glassDecoration(borderRadius: 14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Achiever",
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        "Level 15 Pro",
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int index,
    int selectedIndex,
  ) {
    final bool isSelected = index == selectedIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(context, index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: AppTransitions.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Glassmorphic Bottom Navigation Bar for Mobile and Tablet (Portrait)
  Widget _buildBottomNavigationBar(BuildContext context, int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.8),
        border: const Border(
          top: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(context, Icons.dashboard_outlined, Icons.dashboard, "Home", 0, selectedIndex),
              _buildBottomNavItem(context, Icons.task_alt_outlined, Icons.task_alt, "Tasks", 1, selectedIndex),
              _buildBottomNavItem(context, Icons.autorenew_outlined, Icons.autorenew, "Habits", 2, selectedIndex),
              _buildBottomNavItem(context, Icons.book_outlined, Icons.book, "Journal", 3, selectedIndex),
              _buildBottomNavItem(context, Icons.settings_outlined, Icons.settings, "Settings", 4, selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    IconData inactiveIcon,
    IconData activeIcon,
    String label,
    int index,
    int selectedIndex,
  ) {
    final bool isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppTransitions.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
