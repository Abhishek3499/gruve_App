enum SocketState { disconnected, connecting, connected, reconnecting, failed }

enum SocketEventType {
  connected,
  disconnected,
  message,
  error,
  reconnecting,
  failed,
}

class SocketEvent {
  final SocketEventType type;
  final dynamic data;
  final DateTime timestamp;

  SocketEvent({required this.type, this.data, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}
