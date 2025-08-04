import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/advanced_terminal_service.dart';
import '../services/advanced_logging_service.dart';
import '../widgets/enhanced_custom_app_bar.dart';

/// Pantalla de terminal avanzado con funcionalidades de hacking
class AdvancedTerminalScreen extends StatefulWidget {
  const AdvancedTerminalScreen({super.key});

  @override
  State<AdvancedTerminalScreen> createState() => _AdvancedTerminalScreenState();
}

class _AdvancedTerminalScreenState extends State<AdvancedTerminalScreen> {
  late AdvancedTerminalService _terminalService;
  late AdvancedLoggingService _loggingService;
  late TextEditingController _commandController;
  late ScrollController _scrollController;
  late FocusNode _focusNode;

  int _historyIndex = -1;
  bool _isCommandRunning = false;

  @override
  void initState() {
    super.initState();
    _terminalService = AdvancedTerminalService();
    _loggingService = AdvancedLoggingService.instance;
    _commandController = TextEditingController();
    _scrollController = ScrollController();
    _focusNode = FocusNode();

    _initializeTerminal();
  }

  void _initializeTerminal() async {
    await _terminalService.initialize();
    setState(() {});

    // Auto-scroll al final cuando se añaden nuevas entradas
    _terminalService.addListener(_scrollToBottom);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _terminalService.removeListener(_scrollToBottom);
    _terminalService.endSession();
    _commandController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _terminalService.backgroundColor,
      appBar: EnhancedHackomaticAppBar(
        currentSection: 'Terminal Avanzado',
        breadcrumbs: [
          EnhancedBreadcrumbItem(
            title: 'Terminal',
            route: '/terminal',
            icon: Icons.terminal,
            isActive: true,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de estado del terminal
          _buildTerminalStatusBar(),

          // Área de contenido del terminal
          Expanded(child: _buildTerminalContent()),

          // Barra de entrada de comandos
          _buildCommandInputBar(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Barra de estado del terminal
  Widget _buildTerminalStatusBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _terminalService.backgroundColor.withValues(alpha: .9),
        border: Border(
          bottom: BorderSide(
            color: _terminalService.textColor.withValues(alpha: .3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Indicador de estado
          Icon(
            _terminalService.isSessionActive
                ? Icons.circle
                : Icons.circle_outlined,
            color: _terminalService.isSessionActive
                ? _terminalService.successColor
                : _terminalService.errorColor,
            size: 12,
          ),
          const SizedBox(width: 8),
          Text(
            _terminalService.isSessionActive ? 'ACTIVO' : 'INACTIVO',
            style: TextStyle(
              color: _terminalService.textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: _terminalService.fontFamily,
            ),
          ),
          const SizedBox(width: 16),

          // Información de sesión
          Icon(
            Icons.person,
            color: _terminalService.textColor.withValues(alpha: .7),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${_terminalService.currentUser}@${_terminalService.currentHost}',
            style: TextStyle(
              color: _terminalService.textColor.withValues(alpha: .7),
              fontSize: 12,
              fontFamily: _terminalService.fontFamily,
            ),
          ),
          const SizedBox(width: 16),

          // Directorio actual
          Icon(
            Icons.folder,
            color: _terminalService.textColor.withValues(alpha: .7),
            size: 14,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _terminalService.currentDirectory,
              style: TextStyle(
                color: _terminalService.textColor.withValues(alpha: .7),
                fontSize: 12,
                fontFamily: _terminalService.fontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Contador de comandos
          Text(
            'CMD: ${_terminalService.commandCount}',
            style: TextStyle(
              color: _terminalService.textColor.withValues(alpha: .7),
              fontSize: 12,
              fontFamily: _terminalService.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido del terminal
  Widget _buildTerminalContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Consumer<AdvancedTerminalService>(
        builder: (context, terminal, child) {
          return ListView.builder(
            controller: _scrollController,
            itemCount: terminal.history.length,
            itemBuilder: (context, index) {
              final entry = terminal.history[index];
              return _buildTerminalEntry(entry);
            },
          );
        },
      ),
    );
  }

  /// Entrada individual del terminal
  Widget _buildTerminalEntry(TerminalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: SelectableText.rich(
        TextSpan(
          children: [
            // Timestamp
            TextSpan(
              text:
                  '[${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                  '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
                  '${entry.timestamp.second.toString().padLeft(2, '0')}] ',
              style: TextStyle(
                color: _terminalService.textColor.withValues(alpha: .5),
                fontSize: _terminalService.fontSize - 2,
                fontFamily: _terminalService.fontFamily,
              ),
            ),
            // Contenido
            TextSpan(
              text: entry.content,
              style: TextStyle(
                color: entry.color,
                fontSize: _terminalService.fontSize,
                fontFamily: _terminalService.fontFamily,
                fontWeight: entry.type == TerminalEntryType.command
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            // Tiempo de ejecución si está disponible
            if (entry.executionTime != null)
              TextSpan(
                text: ' (${entry.executionTime!.toStringAsFixed(2)}s)',
                style: TextStyle(
                  color: _terminalService.textColor.withValues(alpha: .5),
                  fontSize: _terminalService.fontSize - 2,
                  fontFamily: _terminalService.fontFamily,
                ),
              ),
          ],
        ),
        style: TextStyle(height: 1.2, fontFamily: _terminalService.fontFamily),
      ),
    );
  }

  /// Barra de entrada de comandos
  Widget _buildCommandInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _terminalService.backgroundColor.withValues(alpha: .9),
        border: Border(
          top: BorderSide(
            color: _terminalService.textColor.withValues(alpha: .3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Prompt
          Text(
            _terminalService.prompt,
            style: TextStyle(
              color: _terminalService.successColor,
              fontSize: _terminalService.fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: _terminalService.fontFamily,
            ),
          ),

          // Campo de entrada
          Expanded(
            child: KeyboardListener(
              focusNode: _focusNode,
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: _commandController,
                enabled: !_isCommandRunning,
                style: TextStyle(
                  color: _terminalService.textColor,
                  fontSize: _terminalService.fontSize,
                  fontFamily: _terminalService.fontFamily,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _isCommandRunning
                      ? 'Ejecutando comando...'
                      : 'Escribe tu comando aquí',
                  hintStyle: TextStyle(
                    color: _terminalService.textColor.withValues(alpha: .5),
                    fontFamily: _terminalService.fontFamily,
                  ),
                ),
                onSubmitted: _executeCommand,
              ),
            ),
          ),

          // Botón de ejecución
          IconButton(
            onPressed: _isCommandRunning
                ? null
                : () => _executeCommand(_commandController.text),
            icon: Icon(
              _isCommandRunning ? Icons.hourglass_empty : Icons.send,
              color: _terminalService.successColor,
            ),
            tooltip: 'Ejecutar comando (Enter)',
          ),

          // Botón de limpiar
          IconButton(
            onPressed: () {
              _terminalService.executeCommand('clear');
              _commandController.clear();
            },
            icon: Icon(Icons.clear_all, color: _terminalService.warningColor),
            tooltip: 'Limpiar terminal (Ctrl+L)',
          ),
        ],
      ),
    );
  }

  /// Botón flotante con acciones rápidas
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: _terminalService.successColor,
      foregroundColor: Colors.black,
      onPressed: _showQuickActionsMenu,
      child: const Icon(Icons.flash_on),
    );
  }

  /// Manejar eventos de teclado
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Historial de comandos
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _navigateHistory(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _navigateHistory(1);
      }
      // Limpiar terminal
      else if (event.logicalKey == LogicalKeyboardKey.keyL &&
          HardwareKeyboard.instance.isControlPressed) {
        _terminalService.executeCommand('clear');
      }
      // Interrumpir comando
      else if (event.logicalKey == LogicalKeyboardKey.keyC &&
          HardwareKeyboard.instance.isControlPressed) {
        if (_isCommandRunning) {
          setState(() {
            _isCommandRunning = false;
          });
          _terminalService.executeCommand(
            '# Comando interrumpido por el usuario',
          );
        }
      }
    }
  }

  /// Navegar por el historial de comandos
  void _navigateHistory(int direction) {
    final history = _terminalService.commandHistory;
    if (history.isEmpty) return;

    _historyIndex += direction;

    if (_historyIndex < 0) {
      _historyIndex = 0;
    } else if (_historyIndex >= history.length) {
      _historyIndex = history.length - 1;
    }

    _commandController.text = history[history.length - 1 - _historyIndex];
    _commandController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commandController.text.length),
    );
  }

  /// Ejecutar comando
  void _executeCommand(String command) async {
    if (command.trim().isEmpty || _isCommandRunning) return;

    setState(() {
      _isCommandRunning = true;
    });

    _historyIndex = -1;

    try {
      await _terminalService.executeCommand(command);
      _commandController.clear();
      _scrollToBottom();
    } finally {
      setState(() {
        _isCommandRunning = false;
      });
    }
  }

  /// Mostrar menú de acciones rápidas
  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickActionsSheet(
        terminalService: _terminalService,
        onCommandSelected: (command) {
          _commandController.text = command;
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Sheet de acciones rápidas
class _QuickActionsSheet extends StatelessWidget {
  final AdvancedTerminalService terminalService;
  final Function(String) onCommandSelected;

  const _QuickActionsSheet({
    required this.terminalService,
    required this.onCommandSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: terminalService.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: terminalService.successColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: terminalService.successColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '⚡ Acciones Rápidas',
              style: TextStyle(
                color: terminalService.successColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: terminalService.fontFamily,
              ),
            ),
          ),

          // Lista de comandos rápidos
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 3,
              padding: const EdgeInsets.all(16),
              children: [
                _buildQuickAction(
                  '🔍 Escaneo de Red',
                  'nmap -sn 192.168.1.0/24',
                  Icons.network_check,
                ),
                _buildQuickAction('📁 Listar Archivos', 'ls -la', Icons.folder),
                _buildQuickAction(
                  '💾 Info del Sistema',
                  'uname -a && whoami && id',
                  Icons.info,
                ),
                _buildQuickAction(
                  '🌐 Conectividad',
                  'ping -c 4 google.com',
                  Icons.wifi,
                ),
                _buildQuickAction(
                  '🔒 Procesos',
                  'ps aux | head -20',
                  Icons.list,
                ),
                _buildQuickAction(
                  '💻 Uso de Recursos',
                  'top -n 1 | head -10',
                  Icons.memory,
                ),
                _buildQuickAction(
                  '🔧 Servicios',
                  'systemctl --type=service --state=running',
                  Icons.build,
                ),
                _buildQuickAction(
                  '📊 Espacio en Disco',
                  'df -h',
                  Icons.storage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, String command, IconData icon) {
    return GestureDetector(
      onTap: () => onCommandSelected(command),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: terminalService.successColor.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: terminalService.successColor.withValues(alpha: .3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: terminalService.successColor, size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: terminalService.textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
