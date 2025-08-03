import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Servicio de Autenticación UI para Hackomatic
/// Maneja solicitudes de contraseñas de forma segura y amigable
class AuthUIService {
  static final AuthUIService _instance = AuthUIService._internal();
  factory AuthUIService() => _instance;
  AuthUIService._internal();

  // Cache de credenciales para evitar pedir múltiples veces
  String? _cachedPassword;
  DateTime? _passwordCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 30);

  /// Solicitar contraseña del usuario de forma visual
  Future<String?> requestPassword(
    BuildContext context, {
    String? title,
    String? message,
    bool allowSave = true,
  }) async {
    // Verificar si tenemos una contraseña en cache válida
    if (_cachedPassword != null && _passwordCacheTime != null) {
      final now = DateTime.now();
      if (now.difference(_passwordCacheTime!) < _cacheTimeout) {
        return _cachedPassword;
      } else {
        // Cache expirado
        _clearPasswordCache();
      }
    }

    final completer = Completer<String?>();

    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _PasswordDialog(
          title: title ?? 'Acceso Administrativo Requerido',
          message:
              message ??
              'Se necesitan permisos de administrador para continuar',
          allowSave: allowSave,
          onSubmit: (password, shouldSave) {
            if (shouldSave && password.isNotEmpty) {
              _cachePassword(password);
            }
            Navigator.of(context).pop();
            completer.complete(password.isEmpty ? null : password);
          },
          onCancel: () {
            Navigator.of(context).pop();
            completer.complete(null);
          },
        );
      },
    );

    return completer.future;
  }

  /// Verificar credenciales administrativas
  Future<bool> verifyAdminCredentials(
    BuildContext context,
    String password,
  ) async {
    try {
      // Verificar la contraseña ejecutando un comando simple con sudo
      final process = await Process.start('sudo', [
        '-S',
        '-p',
        '',
        'true',
      ], mode: ProcessStartMode.normal);

      // Enviar contraseña
      process.stdin.writeln(password);
      await process.stdin.close();

      final exitCode = await process.exitCode;
      return exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Ejecutar comando con sudo usando contraseña almacenada
  Future<Process?> executeSudoCommand(
    BuildContext context,
    List<String> command, {
    String? customMessage,
  }) async {
    final password = await requestPassword(
      context,
      message:
          customMessage ??
          'Se requiere acceso administrativo para: ${command.join(' ')}',
    );

    if (password == null || password.isEmpty) {
      return null;
    }

    try {
      final process = await Process.start('sudo', [
        '-S',
        '-p',
        '',
        ...command,
      ], mode: ProcessStartMode.normal);

      // Enviar contraseña
      process.stdin.writeln(password);

      return process;
    } catch (e) {
      return null;
    }
  }

  /// Almacenar contraseña en cache temporal
  void _cachePassword(String password) {
    _cachedPassword = password;
    _passwordCacheTime = DateTime.now();
  }

  /// Limpiar cache de contraseña
  void _clearPasswordCache() {
    _cachedPassword = null;
    _passwordCacheTime = null;
  }

  /// Verificar si hay contraseña en cache válida
  bool get hasValidPasswordCache {
    if (_cachedPassword == null || _passwordCacheTime == null) {
      return false;
    }

    final now = DateTime.now();
    return now.difference(_passwordCacheTime!) < _cacheTimeout;
  }

  /// Limpiar todas las credenciales almacenadas
  void clearAllCredentials() {
    _clearPasswordCache();
  }
}

/// Widget de diálogo para solicitar contraseña
class _PasswordDialog extends StatefulWidget {
  final String title;
  final String message;
  final bool allowSave;
  final Function(String password, bool shouldSave) onSubmit;
  final VoidCallback onCancel;

  const _PasswordDialog({
    required this.title,
    required this.message,
    required this.allowSave,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog>
    with TickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _shouldSave = true;
  bool _isVerifying = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Auto-focus en el campo de contraseña
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passwordFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      _showError('La contraseña no puede estar vacía');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // Simular verificación (en el servicio se hace la verificación real)
    await Future.delayed(const Duration(milliseconds: 500));

    widget.onSubmit(password, _shouldSave);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00FF41), width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFF00FF41), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFF00FF41),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00FF41).withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Ingresa tu contraseña',
                  hintStyle: const TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF00FF41),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
            ),
            if (widget.allowSave) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _shouldSave,
                    onChanged: (value) {
                      setState(() {
                        _shouldSave = value ?? true;
                      });
                    },
                    activeColor: const Color(0xFF00FF41),
                    checkColor: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Recordar por 30 minutos',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
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
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tu contraseña se utiliza solo para obtener permisos administrativos y no se almacena permanentemente.',
                      style: TextStyle(color: Color(0xFF00FF41), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isVerifying ? null : widget.onCancel,
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: _isVerifying ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF41),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade600,
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}
