import 'package:flutter/material.dart';
import 'package:quiz/presentation/screens/category_selection_screen.dart';
import 'customroom_setup_screen.dart';
class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  void _navigateWithMode(BuildContext context, String mode) {
    if (mode == 'custom_room') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomRoomSetupScreen(), // new screen to create/join custom room
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategorySelectionScreen(mode: mode),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Game Mode'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _navigateWithMode(context, 'practice'),
              child: const Text('Practice Mode'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateWithMode(context, 'random_match'),
              child: const Text('Random Match'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateWithMode(context, 'custom_room'),
              child: const Text('Custom Match Room'),
            ),
          ],
        ),
      ),
    );
  }
}
