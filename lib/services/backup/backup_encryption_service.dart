import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-local AES-256-GCM encryption. Keys never leave the device.
class BackupEncryptionService {
  static const _keyName = 'renewwise_backup_key_v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<enc.Key> _deviceKey() async {
    var stored = await _storage.read(key: _keyName);
    if (stored == null) {
      final key = enc.Key.fromSecureRandom(32);
      await _storage.write(key: _keyName, value: key.base64);
      return key;
    }
    return enc.Key(base64Decode(stored));
  }

  Future<Uint8List> encrypt(Uint8List plain) async {
    final key = await _deviceKey();
    final iv = enc.IV.fromSecureRandom(12);
    final encrypter =
        enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plain, iv: iv);
    final out = Uint8List(12 + encrypted.bytes.length);
    out.setRange(0, 12, iv.bytes);
    out.setRange(12, out.length, encrypted.bytes);
    return out;
  }

  Future<Uint8List> decrypt(Uint8List payload) async {
    if (payload.length < 13) {
      throw StateError('Invalid backup payload');
    }
    final key = await _deviceKey();
    final iv = enc.IV(payload.sublist(0, 12));
    final cipher = enc.Encrypted(payload.sublist(12));
    final encrypter =
        enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    return Uint8List.fromList(encrypter.decryptBytes(cipher, iv: iv));
  }
}
