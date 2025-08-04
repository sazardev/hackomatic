import 'dart:io';
import 'dart:convert';
import 'dart:developer' as dev;

/// 🔐 SERVICIO DE CACHÉ RÁPIDO PARA CREDENCIALES
/// Guarda credenciales de forma segura y las reutiliza automáticamente
class FastCredentialCache {
  static const String _cacheFile = '.hackomatic_fast_cache';
  static String? _cachedPassword;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(hours: 24);

  /// ⚡ Obtener password desde caché (super rápido)
  static Future<String?> getCachedPassword() async {
    // Si ya está en memoria y es válido
    if (_cachedPassword != null && _isCacheValid()) {
      dev.log('🚀 Using in-memory cached password');
      return _cachedPassword;
    }

    // Intentar cargar desde archivo
    try {
      final home = Platform.environment['HOME'] ?? '/tmp';
      final cacheFile = File('$home/$_cacheFile');

      if (await cacheFile.exists()) {
        final content = await cacheFile.readAsString();
        final data = jsonDecode(content);

        final timestamp = DateTime.parse(data['timestamp']);
        final now = DateTime.now();

        // Verificar si el caché sigue siendo válido
        if (now.difference(timestamp) < _cacheDuration) {
          _cachedPassword = _decodePassword(data['password']);
          _cacheTimestamp = timestamp;
          dev.log('🚀 Loaded cached password from file');
          return _cachedPassword;
        } else {
          dev.log('⚠️ Cached password expired, removing file');
          await cacheFile.delete();
        }
      }
    } catch (e) {
      dev.log('❌ Error loading cached password: $e');
    }

    return null;
  }

  /// 💾 Guardar password en caché para uso futuro
  static Future<void> cachePassword(String password) async {
    try {
      final home = Platform.environment['HOME'] ?? '/tmp';
      final cacheFile = File('$home/$_cacheFile');

      final data = {
        'password': _encodePassword(password),
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

      await cacheFile.writeAsString(jsonEncode(data));

      // También guardarlo en memoria
      _cachedPassword = password;
      _cacheTimestamp = DateTime.now();

      // Hacer el archivo solo legible por el usuario
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['600', cacheFile.path]);
      }

      dev.log('✅ Password cached successfully');
    } catch (e) {
      dev.log('❌ Error caching password: $e');
    }
  }

  /// 🗑️ Limpiar caché de credenciales
  static Future<void> clearCache() async {
    try {
      final home = Platform.environment['HOME'] ?? '/tmp';
      final cacheFile = File('$home/$_cacheFile');

      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }

      _cachedPassword = null;
      _cacheTimestamp = null;

      dev.log('🗑️ Credential cache cleared');
    } catch (e) {
      dev.log('❌ Error clearing cache: $e');
    }
  }

  /// ✅ Verificar si el caché en memoria es válido
  static bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;
  }

  /// 🔐 Codificar password (seguridad básica)
  static String _encodePassword(String password) {
    // Codificación simple base64 + rotación
    final bytes = utf8.encode(password);
    final rotated = bytes.map((b) => (b + 13) % 256).toList();
    return base64Encode(rotated);
  }

  /// 🔓 Decodificar password
  static String _decodePassword(String encoded) {
    final decoded = base64Decode(encoded);
    final rotated = decoded.map((b) => (b - 13) % 256).toList();
    return utf8.decode(rotated);
  }

  /// 📊 Obtener info del caché
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final home = Platform.environment['HOME'] ?? '/tmp';
      final cacheFile = File('$home/$_cacheFile');

      return {
        'hasMemoryCache': _cachedPassword != null,
        'hasFileCache': await cacheFile.exists(),
        'isValid': _isCacheValid(),
        'cacheAge': _cacheTimestamp != null
            ? DateTime.now().difference(_cacheTimestamp!).inMinutes
            : null,
        'cacheFile': cacheFile.path,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 🚀 Método de conveniencia para obtener password con fallback
  static Future<String?> getPasswordOrPrompt() async {
    final cached = await getCachedPassword();
    if (cached != null) {
      dev.log('🚀 Using cached credentials - no sudo prompt needed!');
      return cached;
    }

    dev.log('⚠️ No cached credentials found - will need sudo prompt');
    return null;
  }
}
