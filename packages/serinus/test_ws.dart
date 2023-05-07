// main.dart
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  // Connect to the remote WebSocket endpoint.
  final uri = Uri.parse('ws://localhost:3000/');
  final channel = WebSocketChannel.connect(uri);

  // Listen to incoming messages from the server.
  channel.stream.listen(print);

  // Send messages to the server.
  channel.sink.add('ping');
}