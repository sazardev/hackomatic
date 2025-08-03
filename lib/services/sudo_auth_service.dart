import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Servicio de autenticación sudo con interfaz gráfica
class SudoAuthService {
  static final SudoAuthService _instance = SudoAuthService._internal();
  factory SudoAuthService() => _instance;
  SudoAuthService._internal();

  String? _cachedPassword;
  DateTime? _passwordCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  /// Verificar si hay una contraseña válida en caché
  bool get hasValidPasswordCache {
    if (_cachedPassword == null || _passwordCacheTime == null) return false;

    final now = DateTime.now();
    return now.difference(_passwordCacheTime!) < _cacheValidDuration;
  }

  /// Solicitar contraseña con interfaz gráfica
  Future<String?> requestPassword(
    BuildContext context, {
    String title = 'Autenticación requerida',
    String message = 'Se requieren permisos de administrador para continuar',
  }) async {
    // Si ya tenemos una contraseña válida en caché
    if (hasValidPasswordCache) {
      return _cachedPassword;
    }

    final completer = Completer<String?>();
    final passwordController = TextEditingController();
    bool isObscured = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF00FF41), width: 1),
          ),
          title: Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF00FF41), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF00FF41),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF41).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00FF41).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF00FF41),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Color(0xFF00FF41),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Contraseña de ${Platform.environment['USER'] ?? 'usuario'}:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00FF41)),
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: isObscured,
                    autofocus: true,
                    style: const TextStyle(
                      color: Color(0xFF00FF41),
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ingresa tu contraseña...',
                      hintStyle: TextStyle(
                        color: const Color(0xFF00FF41).withOpacity(0.5),
                        fontFamily: 'monospace',
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFF00FF41),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF00FF41),
                        ),
                        onPressed: () {
                          setState(() {
                            isObscured = !isObscured;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onSubmitted: (value) {
                      Navigator.pop(context);
                      completer.complete(value.isNotEmpty ? value : null);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tu contraseña se guardará temporalmente para evitar solicitudes repetitivas',
                          style: TextStyle(
                            color: Colors.orange.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                completer.complete(null);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final password = passwordController.text;
                Navigator.pop(context);
                completer.complete(password.isNotEmpty ? password : null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF41),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.check),
              label: const Text('Autenticar'),
            ),
          ],
        ),
      ),
    );

    final password = await completer.future;

    if (password != null) {
      // Verificar la contraseña
      final isValid = await _verifyPassword(password);
      if (isValid) {
        _cachedPassword = password;
        _passwordCacheTime = DateTime.now();
        return password;
      } else {
        // Mostrar error y volver a pedir
        if (context.mounted) {
          _showPasswordError(context);
          return await requestPassword(context, title: title, message: message);
        }
      }
    }

    return null;
  }

  /// Verificar contraseña con sudo
  Future<bool> _verifyPassword(String password) async {
    try {
      final process = await Process.start('sudo', [
        '-S',
        '-k',
        'true',
      ], runInShell: false);

      // Enviar contraseña
      process.stdin.writeln(password);
      await process.stdin.close();

      final exitCode = await process.exitCode;
      return exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Mostrar error de contraseña
  void _showPasswordError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Contraseña incorrecta. Intenta nuevamente.'),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Ejecutar comando con sudo usando contraseña en caché
  Future<ProcessResult> executeSudoCommand(
    String command, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (!hasValidPasswordCache) {
      throw Exception('No valid password in cache');
    }

    try {
      final process = await Process.start(
        'sudo',
        ['-S', '-k', 'sh', '-c', command],
        runInShell: false,
        workingDirectory: workingDirectory,
        environment: environment,
      );

      // Enviar contraseña
      process.stdin.writeln(_cachedPassword);
      await process.stdin.close();

      final exitCode = await process.exitCode;
      final stdout = await process.stdout
          .transform(const SystemEncoding().decoder)
          .join();
      final stderr = await process.stderr
          .transform(const SystemEncoding().decoder)
          .join();

      return ProcessResult(process.pid, exitCode, stdout, stderr);
    } catch (e) {
      throw Exception('Failed to execute sudo command: $e');
    }
  }

  /// Limpiar caché de contraseña
  void clearPasswordCache() {
    _cachedPassword = null;
    _passwordCacheTime = null;
  }

  /// Verificar si el usuario tiene permisos sudo
  Future<bool> hasSudoAccess() async {
    try {
      final result = await Process.run('sudo', ['-n', 'true']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
