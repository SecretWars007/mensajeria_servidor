import 'dart:convert';
import 'dart:io';
import 'package:mensajeria_servidor/jwt_helper.dart';

class WsService {
  final Map<String, Set<WebSocket>> rooms = {}; // salas -> sockets
  final Map<WebSocket, String> socketUsernames = {}; // socket -> username

  void handleConnection(WebSocket socket) {
    String? username;
    String? currentRoom;

    void broadcastUserList(String room) {
      if (!rooms.containsKey(room)) return;
      final users =
          rooms[room]!.map((s) => socketUsernames[s] ?? 'anon').toList();
      final msg = jsonEncode({'type': 'user_list', 'users': users});
      for (var s in rooms[room]!) {
        if (s.readyState == WebSocket.open) s.add(msg);
      }
    }

    void broadcastMessage(String room, Map<String, dynamic> message) {
      if (!rooms.containsKey(room)) return;
      final msg = jsonEncode(message);
      for (var s in rooms[room]!) {
        if (s.readyState == WebSocket.open) s.add(msg);
      }
    }

    socket.listen((message) {
      try {
        final data = jsonDecode(message);

        switch (data['type']) {
          // Autenticación
          case 'auth':
            final token = data['token'];
            final decoded = JwtHelper.verifyToken(token);
            if (decoded != null) {
              username = decoded.payload['username'];
              socketUsernames[socket] = username!;
              socket.add(jsonEncode({'type': 'auth', 'status': 'ok'}));
            } else {
              socket.add(jsonEncode({'type': 'auth', 'status': 'error'}));
              socket.close();
            }
            break;

          // Unirse o crear sala
          case 'join':
            final room = data['room'];
            if (room == null) break;
            rooms.putIfAbsent(room, () => {});
            rooms[room]!.add(socket);
            currentRoom = room;
            socket.add(jsonEncode({'type': 'joined', 'room': room}));
            broadcastUserList(room);
            break;

          // Enviar mensaje
          case 'message':
            final room = data['room'];
            final text = data['text'];
            if (room == null || text == null) break;
            broadcastMessage(room, {
              'type': 'message',
              'user': username ?? 'anon',
              'text': text,
              'ts': DateTime.now().toIso8601String(),
            });
            break;

          default:
            socket.add(jsonEncode({
              'type': 'error',
              'text': 'Tipo de mensaje desconocido: ${data['type']}'
            }));
        }
      } catch (e) {
        socket.add(jsonEncode({'type': 'error', 'text': e.toString()}));
      }
    }, onDone: () {
      // Eliminar socket de sala y lista de usuarios
      if (currentRoom != null && rooms.containsKey(currentRoom)) {
        rooms[currentRoom]!.remove(socket);
        if (rooms[currentRoom]!.isEmpty) {
          rooms.remove(currentRoom);
        } else {
          broadcastUserList(currentRoom!);
        }
      }
      socketUsernames.remove(socket);
    }, onError: (err) {
      print('WebSocket error: $err');
      socket.close();
    });
  }
}

Future<void> main() async {
  final service = WsService();
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 1982);
  print('Servidor WebSocket escuchando en ws://192.168.1.101:1982/ws');

  await for (HttpRequest req in server) {
    if (req.uri.path == '/ws') {
      WebSocketTransformer.upgrade(req).then((socket) {
        service.handleConnection(socket);
      });
    } else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Ruta no encontrada')
        ..close();
    }
  }
}
