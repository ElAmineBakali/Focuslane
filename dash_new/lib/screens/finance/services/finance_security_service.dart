import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FinanceSecurityService {
  FinanceSecurityService._();

  static final FinanceSecurityService I = FinanceSecurityService._();

  static const String _storageKey = 'finance_security_v1';
  static const int _iterations = 120000;
  static const Duration _sessionTtl = Duration(minutes: 15);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DateTime? _unlockedUntil;

  bool get isSessionUnlocked {
    final until = _unlockedUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  Future<bool> hasPassword() async {
    final data = await _readRecord();
    return data != null;
  }

  Future<void> clearSession() async {
    _unlockedUntil = null;
  }

  Future<void> setPassword(String rawPassword) async {
    final password = rawPassword.trim();
    if (password.length < 6) {
      throw ArgumentError('La contraseña debe tener al menos 6 caracteres.');
    }

    final salt = _generateSalt();
    final hash = _deriveHash(password, salt: salt, iterations: _iterations);

    final record = jsonEncode({
      'v': 1,
      'iterations': _iterations,
      'salt': base64Encode(salt),
      'hash': base64Encode(hash),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });

    await _storage.write(key: _storageKey, value: record);
    _markSessionUnlocked();
  }

  Future<bool> verifyAndUnlock(String rawPassword) async {
    final record = await _readRecord();
    if (record == null) return false;

    final password = rawPassword.trim();
    if (password.isEmpty) return false;

    final storedSalt = base64Decode(record.saltB64);
    final storedHash = base64Decode(record.hashB64);

    final candidate = _deriveHash(
      password,
      salt: storedSalt,
      iterations: record.iterations,
    );

    final ok = _constantTimeEquals(candidate, storedHash);
    if (ok) {
      _markSessionUnlocked();
    }
    return ok;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final has = await hasPassword();
    if (!has) {
      await setPassword(newPassword);
      return true;
    }

    final ok = await verifyAndUnlock(currentPassword);
    if (!ok) return false;

    await setPassword(newPassword);
    return true;
  }

  void _markSessionUnlocked() {
    _unlockedUntil = DateTime.now().add(_sessionTtl);
  }

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
  }

  Uint8List _deriveHash(
    String password, {
    required Uint8List salt,
    required int iterations,
  }) {
    var digest = sha256.convert(_joinBytes(salt, utf8.encode(password)));
    for (var i = 1; i < iterations; i++) {
      digest = sha256.convert(_joinBytes(digest.bytes, salt, utf8.encode(password)));
    }
    return Uint8List.fromList(digest.bytes);
  }

  List<int> _joinBytes(List<int> a, List<int> b, [List<int>? c]) {
    if (c == null) {
      return <int>[...a, ...b];
    }
    return <int>[...a, ...b, ...c];
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Future<_FinancePasswordRecord?> _readRecord() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final saltB64 = (map['salt'] as String?)?.trim() ?? '';
    final hashB64 = (map['hash'] as String?)?.trim() ?? '';
    final iterations = (map['iterations'] as num?)?.toInt() ?? _iterations;

    if (saltB64.isEmpty || hashB64.isEmpty || iterations <= 0) return null;

    return _FinancePasswordRecord(
      saltB64: saltB64,
      hashB64: hashB64,
      iterations: iterations,
    );
  }
}

class _FinancePasswordRecord {
  const _FinancePasswordRecord({
    required this.saltB64,
    required this.hashB64,
    required this.iterations,
  });

  final String saltB64;
  final String hashB64;
  final int iterations;
}
