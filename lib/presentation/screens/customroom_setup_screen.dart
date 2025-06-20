import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';

class CustomRoomSetupScreen extends StatefulWidget {
  const CustomRoomSetupScreen({Key? key}) : super(key: key);

  @override
  State<CustomRoomSetupScreen> createState() => _CustomRoomSetupScreenState();
}

class _CustomRoomSetupScreenState extends State<CustomRoomSetupScreen> {
  final _formKeyCreate = GlobalKey<FormState>();
  final _formKeyJoin = GlobalKey<FormState>();
  final TextEditingController _capacityController = TextEditingController(text: '2');
  final TextEditingController _roomIdController = TextEditingController();
  bool _isLoading = false;

  static const _baseUrl = 'https://quiz-backend-lnrb.onrender.com/api/match';

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  Future<void> _handleCreate() async {
    if (!_formKeyCreate.currentState!.validate()) return;
    final cap = int.tryParse(_capacityController.text) ?? 0;
    if (cap < 2) return;

    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw 'Not signed in';

      final res = await http.post(
        Uri.parse('$_baseUrl/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'capacity': cap}),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['roomId'] != null) {
        final id = data['roomId'];
        if (!mounted) return;

        context.goNamed(
          'waitingRoom',
          pathParameters: {'roomId': id},
          queryParameters: {
            'isHost': 'true',
            'capacity': cap.toString(),
          },
        );
      } else {
        throw data['message'] ?? 'Create failed';
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJoin() async {
    if (!_formKeyJoin.currentState!.validate()) return;
    final rid = _roomIdController.text.trim();
    if (rid.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw 'Not signed in';

      final res = await http.post(
        Uri.parse('$_baseUrl/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'roomId': rid}),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final cap = data['capacity'] ?? 2;
        if (!mounted) return;

        context.goNamed(
          'waitingRoom',
          pathParameters: {'roomId': rid},
          queryParameters: {
            'isHost': 'false',
            'capacity': cap.toString(),
          },
        );
      } else {
        throw data['message'] ?? 'Join failed';
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E3F),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Custom Match Room'),
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCreateForm(),
              const SizedBox(height: 30),
              Divider(color: Colors.white54),
              const SizedBox(height: 20),
              _buildJoinForm(),
            ],
          ),
        ),
      ),
    );
  }

  Form _buildCreateForm() {
    return Form(
      key: _formKeyCreate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎮 Create Room',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Capacity (min 2)'),
            validator: (val) {
              final n = int.tryParse(val ?? '');
              if (n == null || n < 2) return 'Enter a valid number ≥ 2';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildActionButton(label: 'Create', onTap: _handleCreate),
        ],
      ),
    );
  }

  Form _buildJoinForm() {
    return Form(
      key: _formKeyJoin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔗 Join Room',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _roomIdController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Room ID'),
            validator: (val) => val?.isEmpty == true ? 'Enter room ID' : null,
          ),
          const SizedBox(height: 16),
          _buildActionButton(label: 'Join', onTap: _handleJoin),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      )
          : Text(label, style: const TextStyle(fontSize: 16)),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
