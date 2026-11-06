import 'package:flutter/material.dart';

/// AppBar principale della dashboard, con callback fornite dalla schermata.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    required this.backgroundColor,
    required this.showBackButton,
    required this.onBack,
    required this.onProfileTap,
    required this.onAppearanceTap,
    required this.onLogout,
  });

  final Color backgroundColor;
  final bool showBackButton;
  final VoidCallback onBack;
  final VoidCallback onProfileTap;
  final VoidCallback onAppearanceTap;
  final VoidCallback onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: showBackButton
            ? IconButton(
                tooltip: 'Torna alla dashboard',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: const Text('COLLECTION by VALORA', style: TextStyle(
          fontWeight: FontWeight.bold, letterSpacing: 1,
        )),
        actions: [
          IconButton(
            tooltip: 'Profilo utente',
            onPressed: onProfileTap,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Personalizza interfaccia',
            onPressed: onAppearanceTap,
            icon: const Icon(Icons.palette_outlined),
          ),
          IconButton(
            tooltip: 'Esci',
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      );
}
