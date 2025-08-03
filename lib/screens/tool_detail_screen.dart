import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hacking_tool.dart';
import '../providers/task_provider.dart';
import '../utils/theme.dart';

class ToolDetailScreen extends StatefulWidget {
  final HackingTool tool;

  const ToolDetailScreen({super.key, required this.tool});

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  final Map<String, dynamic> _parameters = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize parameters with default values
    for (final param in widget.tool.parameters) {
      if (param.defaultValue != null) {
        _parameters[param.name] = param.defaultValue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tool.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildToolInfo(),
                    const SizedBox(height: 24),
                    _buildParametersSection(),
                  ],
                ),
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildToolInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: HackomaticTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: HackomaticTheme.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.build,
                    color: HackomaticTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tool.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.tool.category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HackomaticTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.tool.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  widget.tool.isInstalled ? 'Installed' : 'Not Installed',
                  widget.tool.isInstalled
                      ? HackomaticTheme.successColor
                      : HackomaticTheme.warningColor,
                ),
                if (widget.tool.requiresRoot)
                  _buildInfoChip('Requires Root', HackomaticTheme.errorColor),
                _buildInfoChip(
                  '${widget.tool.parameters.length} Parameters',
                  HackomaticTheme.primaryGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParametersSection() {
    if (widget.tool.parameters.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'This tool has no configurable parameters.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parameters',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...widget.tool.parameters.map((param) => _buildParameterField(param)),
      ],
    );
  }

  Widget _buildParameterField(ToolParameter param) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  param.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (param.required) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      color: HackomaticTheme.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _buildParameterInput(param),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterInput(ToolParameter param) {
    switch (param.type) {
      case 'select':
        return DropdownButtonFormField<String>(
          value: _parameters[param.name],
          decoration: InputDecoration(
            hintText: param.placeholder ?? 'Select ${param.label}',
          ),
          items: param.options?.map((option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _parameters[param.name] = value;
            });
          },
          validator: param.required
              ? (value) => value == null ? '${param.label} is required' : null
              : null,
        );

      case 'boolean':
        return SwitchListTile(
          title: Text('Enable ${param.label}'),
          value: _parameters[param.name] ?? false,
          onChanged: (value) {
            setState(() {
              _parameters[param.name] = value;
            });
          },
          activeColor: HackomaticTheme.primaryGreen,
        );

      case 'number':
        return TextFormField(
          initialValue: _parameters[param.name]?.toString(),
          decoration: InputDecoration(
            hintText: param.placeholder ?? 'Enter ${param.label}',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _parameters[param.name] = int.tryParse(value) ?? value;
            });
          },
          validator: param.required
              ? (value) => value == null || value.isEmpty
                    ? '${param.label} is required'
                    : null
              : null,
        );

      default: // text
        return TextFormField(
          initialValue: _parameters[param.name]?.toString(),
          decoration: InputDecoration(
            hintText: param.placeholder ?? 'Enter ${param.label}',
          ),
          onChanged: (value) {
            setState(() {
              _parameters[param.name] = value;
            });
          },
          validator: param.required
              ? (value) => value == null || value.isEmpty
                    ? '${param.label} is required'
                    : null
              : null,
        );
    }
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HackomaticTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: HackomaticTheme.primaryGreen.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _previewCommand,
              icon: const Icon(Icons.visibility),
              label: const Text('Preview Command'),
              style: OutlinedButton.styleFrom(
                foregroundColor: HackomaticTheme.primaryGreen,
                side: const BorderSide(color: HackomaticTheme.primaryGreen),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.tool.isInstalled ? _runTool : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                widget.tool.isInstalled ? 'Run Tool' : 'Not Installed',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previewCommand() {
    final command = _buildCommand();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Command Preview'),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HackomaticTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HackomaticTheme.primaryGreen),
          ),
          child: Text(
            command,
            style: const TextStyle(
              fontFamily: 'Courier',
              color: HackomaticTheme.primaryGreen,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _runTool() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.tool.requiresRoot) {
      _showRootWarning();
      return;
    }

    _executeCommand();
  }

  void _showRootWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Root Access Required'),
        content: const Text(
          'This tool requires root access to function properly. Make sure your device is rooted and you have granted superuser permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeCommand();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _executeCommand() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Execute the tool command through the task provider
    taskProvider
        .executeToolCommand(widget.tool, _parameters)
        .then((task) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${task.name}" started successfully'),
              backgroundColor: HackomaticTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  // Navigate to tasks screen or task detail
                  Navigator.popUntil(context, (route) => route.isFirst);
                  // You could add navigation to tasks screen here
                },
              ),
            ),
          );

          // Navigate back
          Navigator.pop(context);
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start task: $error'),
              backgroundColor: HackomaticTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
  }

  String _buildCommand() {
    String command = widget.tool.command;

    for (final param in widget.tool.parameters) {
      final value = _parameters[param.name];
      if (value != null && value.toString().isNotEmpty) {
        if (param.type == 'boolean' && value == true) {
          command += ' --${param.name}';
        } else if (param.type != 'boolean') {
          command += ' --${param.name} $value';
        }
      }
    }

    return command;
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.tool.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${widget.tool.category}'),
            const SizedBox(height: 8),
            Text('Command: ${widget.tool.command}'),
            const SizedBox(height: 8),
            Text('Requires Root: ${widget.tool.requiresRoot ? "Yes" : "No"}'),
            const SizedBox(height: 8),
            Text(
              'Status: ${widget.tool.isInstalled ? "Installed" : "Not Installed"}',
            ),
            const SizedBox(height: 16),
            Text(
              widget.tool.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
