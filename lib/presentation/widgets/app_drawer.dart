import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2C2C54),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/applogo.png'),
                ),
                SizedBox(width: 12),
                Text(
                  'TriviQ',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          buildDrawerItem(
            context,
            icon: Icons.home,
            text: 'Home',
            onTap: () {
              context.pop(); // close drawer
              context.go('/mode-selection'); // GoRouter navigation
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.person,
            text: 'My Profile',
            onTap: () {
              context.pop();
              context.go('/profile'); // Ensure this route exists
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.psychology,
            text: 'Practice Mode',
            onTap: () {
              context.pop();
              context.go('/category'); // Ensure this route exists
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.flash_on,
            text: 'Challenge Mode',
            onTap: () {
              context.pop();
              context.go('/custom-room-setup'); // Ensure this route exists
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.info_outline,
            text: 'About App',
            onTap: () {
              context.pop();
              context.go('/about'); // Ensure this route exists
            },
          ),
          const Spacer(),
          buildDrawerItem(
            context,
            icon: Icons.logout,
            text: 'Logout',
            onTap: () async {
              context.pop(); // Close drawer first
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;

              context.go('/login'); // 👈 Use GoRouter instead of Navigator

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🔒 Logged out")),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String text,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
