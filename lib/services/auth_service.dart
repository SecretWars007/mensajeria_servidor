import 'dart:convert';
import 'package:mensajeria_servidor/bcrypt_helper.dart';
import 'package:mensajeria_servidor/jwt_helper.dart';
import 'package:shelf/shelf.dart';


class AuthService {
  final db;

  AuthService(this.db);

  Future<Response> registerHandler(Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final username = payload['username'];
    final password = payload['password'];

    final hashed = BcryptHelper.hashPassword(password);
    try {
      db.execute('INSERT INTO users (username, password) VALUES (?, ?)', [username, hashed]);
      return Response.ok(jsonEncode({'message': 'Usuario registrado'}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(400, body: jsonEncode({'error': 'Usuario ya existe'}), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> loginHandler(Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final username = payload['username'];
    final password = payload['password'];

    final result = db.select('SELECT * FROM users WHERE username = ?', [username]);
    if (result.isEmpty) return Response(401, body: jsonEncode({'error': 'Usuario no encontrado'}), headers: {'Content-Type': 'application/json'});

    final user = result.first;
    final valid = BcryptHelper.verify(password, user['password']);
    if (!valid) return Response(401, body: jsonEncode({'error': 'Contraseña incorrecta'}), headers: {'Content-Type': 'application/json'});

    final token = JwtHelper.generateToken(username);
    return Response.ok(jsonEncode({'token': token, 'username': username}), headers: {'Content-Type': 'application/json'});
  }
}
