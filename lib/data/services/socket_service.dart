import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  late IO.Socket socket;

  SocketService._internal();

  void connect(String userId) {
    socket = IO.io(
      'https://quiz-backend-lnrb.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'uid': userId})
          .build(),
    );

    socket.connect();

    socket.onConnect((_) => print('🟢 Connected to socket server'));
    socket.onDisconnect((_) => print('🔴 Disconnected from socket server'));
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  void off(String event) {
    socket.off(event);
  }

  void disconnect() {
    socket.disconnect();
  }
}
