import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  void _navigateWithMode(BuildContext context, String mode) {
    if (mode == 'custom_room') {
      context.push('/custom-room-setup');
    } else {
      context.push('/category', extra: mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E3F),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Select Game Mode'),
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Choose how you want to play:",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildModeButton(
              context,
              icon: Icons.person_outline,
              label: "Single Player(Practice)",
              onPressed: () => _navigateWithMode(context, 'practice'),
              gradientColors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            ),
            const SizedBox(height: 24),
            _buildModeButton(
              context,
              icon: Icons.group_outlined,
              label: "Multiplayer",
              onPressed: () => _navigateWithMode(context, 'custom_room'),
              gradientColors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onPressed,
        required List<Color> gradientColors,
      }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
