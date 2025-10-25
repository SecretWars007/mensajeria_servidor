import 'package:bcrypt/bcrypt.dart';

class BcryptHelper {
  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  static bool verify(String password, String hash) {
    return BCrypt.checkpw(password, hash);
  }
}
