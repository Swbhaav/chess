import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

class SecureStorage {
  final storage = FlutterSecureStorage();

  Future saveCredentials(
    AccessToken token,
    String refreshToken,
    iso8601string,
  ) async {
    print(token.expiry.toIso8601String());

    await storage.write(key: "type", value: token.type);
    await storage.write(key: "data", value: token.data);
    await storage.write(key: "expiry", value: token.expiry.toString());
    await storage.write(key: "refreshToken", value: refreshToken);
  }

  // Get Saved Credentials
  Future<Map<String, dynamic>?> getCredentials() async {
    var result = await storage.readAll();
    if (result.isEmpty) return null;
    return result;
  }

  //Clear Saved credentials
  Future clear() {
    return storage.deleteAll();
  }
}
