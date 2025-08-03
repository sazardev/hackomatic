import 'package:flutter/material.dart';
import '../services/terminal_ui_service.dart';

/// Widget de terminal visual que muestra el output en tiempo real
class TerminalDisplayWidget extends StatefulWidget {
  final Stream<List<TerminalLine>> outputStream;
  final bool showTimestamps;
  final double? height;

  const TerminalDisplayWidget({
    super.key,
    required this.outputStream,
    this.showTimestamps = true,
    this.height,
  });

  @override
  State<TerminalDisplayWidget> createState() => _TerminalDisplayWidgetState();
}

class _TerminalDisplayWidgetState extends State<TerminalDisplayWidget> {
  final ScrollController _scrollController = ScrollController();
  List<TerminalLine> _lines = [];

  @override
  void initState() {
    super.initState();

    widget.outputStream.listen((lines) {
      setState(() {
        _lines = lines;
      });

      // Auto-scroll al final
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header del terminal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF00FF41).withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF41),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Hackomatic Terminal',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_lines.length} líneas',
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
          ),

          // Contenido del terminal
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                final line = _lines[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        if (widget.showTimestamps) ...[
                          TextSpan(
                            text: '[${line.formattedTime}] ',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        TextSpan(
                          text: line.content,
                          style: TextStyle(
                            color: line.color,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
