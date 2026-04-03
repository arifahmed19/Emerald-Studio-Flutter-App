import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;

class CryptoService {
  static encrypt.IV _getIV() {
    return encrypt.IV(Uint8List.fromList(List<int>.filled(16, 0)));
  }

  static final Map<String, Uint8List> _imageCache = {};

  static encrypt.Key _getKey(String userId) {
    final keyString = userId.replaceAll('-', '').padRight(32, '0').substring(0, 32);
    return encrypt.Key.fromUtf8(keyString);
  }

  static Future<Uint8List> encryptImage(Uint8List rawBytes, String userId) async {
    return kIsWeb
        ? _encryptSync({'bytes': rawBytes, 'userId': userId})
        : await compute(_encryptSync, {'bytes': rawBytes, 'userId': userId});
  }

  static Future<Uint8List?> decryptImage(Uint8List encryptedBytes, String userId) async {
    return kIsWeb
        ? _decryptSync({'bytes': encryptedBytes, 'userId': userId})
        : await compute(_decryptSync, {'bytes': encryptedBytes, 'userId': userId});
  }

  static Uint8List _encryptSync(Map<String, dynamic> params) {
    final rawBytes = params['bytes'] as Uint8List;
    final userId = params['userId'] as String;
    
    final key = _getKey(userId);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final encrypted = encrypter.encryptBytes(rawBytes.toList(), iv: _getIV());
    return Uint8List.fromList(encrypted.bytes);
  }

  static Uint8List? _decryptSync(Map<String, dynamic> params) {
    final encryptedBytes = params['bytes'] as Uint8List;
    final userId = params['userId'] as String;
    
    final key = _getKey(userId);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    try {
      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: _getIV());
      return Uint8List.fromList(decrypted);
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List?> fetchAndDecrypt(String url, String userId) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final isEncrypted = url.contains('.bin');
        final bytesToUse = isEncrypted 
            ? await decryptImage(res.bodyBytes, userId) 
            : res.bodyBytes;
            
        if (bytesToUse == null) return null;
            
        _imageCache[url] = bytesToUse;
        return bytesToUse;
      }
    } catch (e) {
      debugPrint("Crypto Fetch Error: $e");
    }
    return null;
  }
}
