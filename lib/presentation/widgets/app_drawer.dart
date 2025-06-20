import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  final String apkLink =
      'https://drive.google.com/drive/folders/15ohVxoWS5C-sy11jBrxi8qS57MatzC8k?usp=sharing';

  Future<void> shareApp() async {

    final message = '''
Check out TriviQ - The Ultimate Quiz Showdown!

Challenge your friends, practice quizzes in various categories and more!

📲 Download the APK:
$apkLink
''';

    try {
      // Load image bytes from assets
      final bytes = await rootBundle.load('assets/images/applogo.png');

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/triviq_logo.png');

      // Write image to temp file
      await file.writeAsBytes(bytes.buffer.asUint8List());

      // Share image + message
      await Share.shareXFiles([XFile(file.path)], text: message);
    } catch (e) {
      print(' Error sharing app: $e');
    }
  }

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
              context.pop();
              context.go('/mode-selection');
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.person,
            text: 'My Profile',
            onTap: () {
              context.pop();
              context.go('/profile');
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.psychology,
            text: 'Practice Mode',
            onTap: () {
              context.pop();
              context.go('/category');
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.flash_on,
            text: 'Challenge Mode',
            onTap: () {
              context.pop();
              context.go('/custom-room-setup');
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.info_outline,
            text: 'About App',
            onTap: () {
              context.pop();
              context.go('/about');
            },
          ),

          // 👇 Share option added here
          buildDrawerItem(
            context,
            icon: Icons.share,
            text: 'Share App',
            onTap: () {
              context.pop();
              shareApp(); // Call share function
            },
          ),

          const Spacer(),

          buildDrawerItem(
            context,
            icon: Icons.logout,
            text: 'Logout',
            onTap: () async {
              context.pop();
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;

              context.go('/login');

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
