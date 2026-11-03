import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Account {
  final String url, token;
  const Account(this.url, this.token);
}

class UserInfo {
  final String username, name;
  const UserInfo(this.username, this.name);
}

class Credentials {
  final String username, password;
  const Credentials(this.username, this.password);
}

/// Keeps the Web app URL, token and signed-in user on this device.
class SessionStore {
  final _secure = const FlutterSecureStorage(); // Android Keystore / iOS Keychain
  static const _cUser = 'saved_username', _cPass = 'saved_password';
  static const _url = 'api_url', _token = 'api_token', _user = 'user_name', _name = 'user_full_name';

  Future<Account?> loadAccount() async {
    final p = await SharedPreferences.getInstance();
    final u = p.getString(_url), t = p.getString(_token);
    return (u == null || t == null || u.isEmpty || t.isEmpty) ? null : Account(u, t);
  }

  Future<UserInfo?> loadUser() async {
    final p = await SharedPreferences.getInstance();
    final u = p.getString(_user), n = p.getString(_name);
    return (u == null || u.isEmpty) ? null : UserInfo(u, n ?? u);
  }

  Future<void> saveAccount(Account a) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_url, a.url);
    await p.setString(_token, a.token);
  }

  Future<void> saveUser(UserInfo u) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_user, u.username);
    await p.setString(_name, u.name);
  }

  Future<void> clearUser() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_user);
    await p.remove(_name);
  }

  // ---- "Remember password" (kept in secure storage, not in plain preferences) ----
  Future<Credentials?> loadCredentials() async {
    try {
      final u = await _secure.read(key: _cUser), p = await _secure.read(key: _cPass);
      return (u == null || p == null || u.isEmpty) ? null : Credentials(u, p);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCredentials(String username, String password) async {
    try {
      await _secure.write(key: _cUser, value: username);
      await _secure.write(key: _cPass, value: password);
    } catch (_) {}
  }

  Future<void> clearCredentials() async {
    try {
      await _secure.delete(key: _cUser);
      await _secure.delete(key: _cPass);
    } catch (_) {}
  }
}