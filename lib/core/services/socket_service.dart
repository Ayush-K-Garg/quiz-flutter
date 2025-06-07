// lib/core/services/socket_service.dart

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();

    socket.onConnect((_) {
      print('Socket connected');
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  void disconnect() {
    socket.disconnect();
  }

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void emit(String event, [dynamic data]) {
    socket.emit(event, data);
  }
}
