import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'waiting_room_screen.dart';

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

  // TODO: Adjust your backend URL and imported route paths
  static const _baseUrl = 'https://quiz-backend-lnrb.onrender.com/api/match';

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<void> _handleCreate() async {
    if (!_formKeyCreate.currentState!.validate()) return;
    final cap = int.tryParse(_capacityController.text) ?? 0;
    if (cap < 2) return;
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) throw 'Not signed in';

      final uri = Uri.parse('$_baseUrl/create');
      final res = await http.post(uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'capacity': cap}));

      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['roomId'] != null) {
        final id = data['roomId'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomScreen(
              roomId: id,
              capacity: cap,
              isHost: true,
            ),
          ),
        );
      } else {
        throw data['message'] ?? 'Create failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

      final uri = Uri.parse('$_baseUrl/join');
      final res = await http.post(uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'roomId': rid}));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final cap = data['capacity'] ?? 2; // fallback to 2 if not returned
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomScreen(
              roomId: rid,
              capacity: cap,
              isHost: false,
            ),
          ),
        );
      }
      else {
        throw data['message'] ?? 'Join failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
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
      appBar: AppBar(title: const Text('Custom Match Room')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(children: [
            _buildCreateForm(),
            const Divider(),
            _buildJoinForm(),
          ]),
        ),
      ),
    );
  }

  Form _buildCreateForm() => Form(
    key: _formKeyCreate,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Create Room', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      TextFormField(
        controller: _capacityController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Capacity (min 2)'),
        validator: (val) {
          final n = int.tryParse(val ?? '');
          if (n == null || n < 2) return 'Enter valid number ≥ 2';
          return null;
        },
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _isLoading ? null : _handleCreate,
        child: _isLoading ? const CircularProgressIndicator() : const Text('Create'),
      ),
    ]),
  );

  Form _buildJoinForm() => Form(
    key: _formKeyJoin,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Join Room', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      TextFormField(
        controller: _roomIdController,
        decoration: const InputDecoration(labelText: 'Room ID'),
        validator: (val) => val?.isEmpty == true ? 'Enter room ID' : null,
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _isLoading ? null : _handleJoin,
        child: _isLoading ? const CircularProgressIndicator() : const Text('Join'),
      ),
    ]),
  );
}
