import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const jwtSecret = 'mi-clave-super-secreta';

class JwtHelper {
  static String generateToken(String username) {
    final jwt = JWT({'username': username});
    return jwt.sign(SecretKey(jwtSecret), expiresIn: const Duration(hours: 24));
  }

  static JWT? verifyToken(String token) {
    try {
      return JWT.verify(token, SecretKey(jwtSecret));
    } catch (e) {
      return null;
    }
  }
}
