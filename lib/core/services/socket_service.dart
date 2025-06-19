import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:quiz/data/models/question_model.dart';
import 'package:quiz/data/models/match_room_model.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket _socket;
  bool _isConnected = false;
  bool _listenersRegistered = false;

  SocketService._internal();

  void connect({
    Function()? onConnected,
    Map<String, Function(dynamic)> listeners = const {},
  }) {
    if (_isConnected) {
      print("⚠️ [SocketService] Already connected.");
      _registerListeners(listeners); // still register listeners if needed
      return;
    }

    print("🔌 [SocketService] Connecting to socket server...");

    _socket = IO.io(
      'https://quiz-backend-lnrb.onrender.com', // 👈 Replace with actual server if needed
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      },
    );

    _socket.connect();

    _socket.onConnect((_) {
      _isConnected = true;
      print('✅ [SocketService] Socket connected');

      _registerListeners(listeners);

      if (onConnected != null) onConnected();
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      _listenersRegistered = false;
      print('❌ [SocketService] Socket disconnected');
    });

    _socket.onConnectError((error) {
      print("🚨 [SocketService] Connect error: $error");
    });

    _socket.onError((error) {
      print("🚨 [SocketService] General socket error: $error");
    });
  }

  void _registerListeners(Map<String, Function(dynamic)> listeners) {
    if (_listenersRegistered) {
      print("ℹ️ [SocketService] Listeners already registered.");
      return;
    }

    if (!_isConnected) {
      print("⚠️ [SocketService] Tried to register listeners before connection.");
      return;
    }

    listeners.forEach((event, handler) {
      _socket.on(event, handler);
      print("✅ [SocketService] Registered listener for '$event'");
    });

    _listenersRegistered = true;
  }

  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
      _listenersRegistered = false;
      print("🔌 [SocketService] Socket manually disconnected");
    } else {
      print("⚠️ [SocketService] Tried to disconnect, but socket already disconnected");
    }
  }

  void on(String event, Function(dynamic) handler) {
    if (!_isConnected) {
      print("⚠️ [SocketService] Tried to register listener before connection: $event");
      return;
    }

    _socket.on(event, handler);
    print("✅ [SocketService] Listener added for '$event'");
  }

  void emit(String event, [dynamic data]) {
    if (!_isConnected) {
      print("❌ [SocketService] Cannot emit '$event', socket not connected.");
      return;
    }

    print("📤 [SocketService] Emitting '$event' with data: $data");
    _socket.emit(event, data);
  }

  // ✅ NEW: Join a specific socket room
  void joinRoom(String roomId) {
    if (!_isConnected) {
      print("⚠️ [SocketService] Tried to join room before socket connection.");
      return;
    }

    print("🏠 [SocketService] Joining room: $roomId");
    _socket.emit('joinRoom', roomId);
  }

  // ✅ NEW: Listen for matchStarted event and pass questions + room
  void listenForMatchStarted(Function(List<Question>, MatchRoom) onMatchStarted) {
    if (!_isConnected) {
      print("⚠️ [SocketService] Cannot listen for 'matchStarted', not connected.");
      return;
    }

    _socket.on('matchStarted', (data) {
      print("📥 [SocketService] Received 'matchStarted' event: $data");

      try {
        final rawQuestions = data['questions'];
        final rawRoom = data['matchRoom'];

        final questions = (rawQuestions as List)
            .map((q) => Question.fromJson(q))
            .toList();

        final matchRoom = MatchRoom.fromJson(rawRoom);

        print("✅ [SocketService] Parsed ${questions.length} questions from matchStarted");
        onMatchStarted(questions, matchRoom);
      } catch (e) {
        print("❌ [SocketService] Error parsing matchStarted data: $e");
      }
    });
  }

  IO.Socket get socket {
    if (!_isConnected) {
      throw Exception("❌ Socket is not connected. Call connect() first.");
    }
    return _socket;
  }

  bool get isConnected => _isConnected;
}
