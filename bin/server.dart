import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // Tomar el puerto de Render o usar 8080 localmente
  final port = int.parse(Platform.environment['PORT'] ?? '1982');

  // Lista de conexiones activas
  final List<WebSocketChannel> clients = [];

  // Handler para WebSocket
  var handler = webSocketHandler((WebSocketChannel channel) {
    clients.add(channel);
    print('Cliente conectado. Total: ${clients.length}');

    channel.stream.listen((message) {
      print('Mensaje recibido: $message');

      // Reenviar a todos los clientes conectados
      for (var client in clients) {
        if (client != channel) {
          client.sink.add(message);
        }
      }
    }, onDone: () {
      clients.remove(channel);
      print('Cliente desconectado. Total: ${clients.length}');
    });
  });

  // Servir en HTTP simple (opcional)
  var cascade = Cascade().add(handler).handler;

  final server = await io.serve(
    cascade,
    InternetAddress.anyIPv4,
    port,
  );

  print('Servidor WebSocket corriendo en ws://localhost:$port');
}
