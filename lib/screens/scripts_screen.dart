import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/script_provider.dart';
import '../providers/task_provider.dart';
import '../models/hacking_script.dart';
import '../utils/theme.dart';

class ScriptsScreen extends StatefulWidget {
  const ScriptsScreen({super.key});

  @override
  State<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends State<ScriptsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<ScriptProvider>(
      builder: (context, scriptProvider, child) {
        return Column(
          children: [
            _buildSearchAndFilter(scriptProvider),
            Expanded(child: _buildScriptsList(scriptProvider)),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter(ScriptProvider scriptProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search scripts...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.filter_list),
            ),
            onChanged: (value) {
              scriptProvider.searchScripts(value);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: scriptProvider.categories.length,
              itemBuilder: (context, index) {
                final category = scriptProvider.categories[index];
                final isSelected = category == scriptProvider.selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      scriptProvider.filterByCategory(category);
                    },
                    backgroundColor: HackomaticTheme.cardColor,
                    selectedColor: HackomaticTheme.primaryGreen.withValues(
                      alpha: 0.3,
                    ),
                    checkmarkColor: HackomaticTheme.primaryGreen,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? HackomaticTheme.primaryGreen
                          : HackomaticTheme.textColor,
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

  Widget _buildScriptsList(ScriptProvider scriptProvider) {
    if (scriptProvider.scripts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 64,
              color: HackomaticTheme.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No scripts found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or category filter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scriptProvider.scripts.length,
      itemBuilder: (context, index) {
        final script = scriptProvider.scripts[index];
        return _buildScriptCard(script, scriptProvider);
      },
    );
  }

  Widget _buildScriptCard(HackingScript script, ScriptProvider scriptProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showScriptDetails(script),
        borderRadius: BorderRadius.circular(12),
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
                      color: HackomaticTheme.primaryGreen.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: HackomaticTheme.primaryGreen.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.code,
                      color: HackomaticTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                script.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                script.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: script.isFavorite
                                    ? HackomaticTheme.errorColor
                                    : HackomaticTheme.secondaryTextColor,
                              ),
                              onPressed: () {
                                scriptProvider.toggleFavorite(script.id);
                              },
                            ),
                          ],
                        ),
                        Text(
                          script.category,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: HackomaticTheme.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                script.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HackomaticTheme.secondaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: HackomaticTheme.secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    script.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HackomaticTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.settings,
                    size: 16,
                    color: HackomaticTheme.secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${script.parameters.length} parameters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HackomaticTheme.secondaryTextColor,
                    ),
                  ),
                  const Spacer(),
                  // Quick Run button
                  IconButton(
                    onPressed: () => _quickRunScript(script),
                    icon: const Icon(Icons.flash_on, size: 18),
                    tooltip: 'Quick Run',
                    style: IconButton.styleFrom(
                      foregroundColor: HackomaticTheme.primaryGreen,
                      backgroundColor: HackomaticTheme.primaryGreen.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _runScript(script),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Configure'),
                    style: TextButton.styleFrom(
                      foregroundColor: HackomaticTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScriptDetails(HackingScript script) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: HackomaticTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HackomaticTheme.secondaryTextColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            script.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      script.category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HackomaticTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      script.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HackomaticTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Script Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Author', script.author),
                    _buildInfoRow('Created', _formatDate(script.createdAt)),
                    _buildInfoRow('Parameters', '${script.parameters.length}'),
                    _buildInfoRow('Script Path', script.scriptPath),
                    const SizedBox(height: 24),
                    if (script.parameters.isNotEmpty) ...[
                      Text(
                        'Parameters',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: script.parameters.length,
                          itemBuilder: (context, index) {
                            final param = script.parameters[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          param.label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
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
                                    const SizedBox(height: 4),
                                    Text(
                                      'Type: ${param.type}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: HackomaticTheme
                                                .secondaryTextColor,
                                          ),
                                    ),
                                    if (param.description != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        param.description!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: HackomaticTheme
                                                  .secondaryTextColor,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _runScript(script);
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Run Script'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _runScript(HackingScript script) {
    // For auto-intelligent scripts (no parameters), run directly
    if (script.parameters.isEmpty) {
      _quickRunScript(script);
      return;
    }

    // For scripts with parameters, show choice: Quick Run or Configure
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Run ${script.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How would you like to run this script?'),
            const SizedBox(height: 16),
            Text(
              'Quick Run: Uses auto-detected network parameters',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _quickRunScript(script);
            },
            child: const Text('🚀 Quick Run'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showScriptParametersDialog(script);
            },
            child: const Text('⚙️ Configure'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _quickRunScript(HackingScript script) async {
    try {
      final scriptProvider = Provider.of<ScriptProvider>(
        context,
        listen: false,
      );
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      // For auto-intelligent scripts with no parameters, run directly
      if (script.parameters.isEmpty) {
        // Show brief loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('🚀 Starting auto-intelligent script...'),
              ],
            ),
          ),
        );

        // Execute script with empty parameters (it's auto-intelligent)
        await taskProvider.executeScript(script, {});

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${script.name} started! Check Tasks for output.',
              ),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View Tasks',
                onPressed: () {
                  // Switch to tasks tab - you'll need to implement navigation
                  // For now, just show a message
                },
              ),
            ),
          );
        }
        return;
      }

      // For scripts with parameters, get auto-detected values
      final autoParams = await scriptProvider.getAutoParameters(script);

      // Show confirmation with auto-detected parameters
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Quick Run: ${script.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Running with auto-detected parameters:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...autoParams.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: HackomaticTheme.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(entry.value.toString())),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _executeScript(script, autoParams);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Execute'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      // Close any open dialogs
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to auto-configure script: $error'),
            backgroundColor: HackomaticTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showScriptParametersDialog(HackingScript script) {
    final parameterValues = <String, dynamic>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Run ${script.name}'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: Provider.of<ScriptProvider>(
              context,
              listen: false,
            ).getAutoParameters(script),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Auto-detecting network parameters...'),
                  ],
                );
              }

              if (snapshot.hasData) {
                final autoParams = snapshot.data!;
                // Initialize with auto-detected values
                for (final param in script.parameters) {
                  if (autoParams.containsKey(param.name)) {
                    parameterValues[param.name] = autoParams[param.name];
                  } else if (param.defaultValue != null) {
                    parameterValues[param.name] = param.defaultValue;
                  }
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (snapshot.hasData)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: HackomaticTheme.primaryGreen.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: HackomaticTheme.primaryGreen.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_fix_high,
                              color: HackomaticTheme.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Parameters auto-detected from your network',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...script.parameters.map((param) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          initialValue:
                              parameterValues[param.name]?.toString() ?? '',
                          decoration: InputDecoration(
                            labelText: param.label,
                            hintText:
                                param.description ?? 'Enter ${param.label}',
                            border: const OutlineInputBorder(),
                            prefixIcon: parameterValues[param.name] != null
                                ? Icon(
                                    Icons.auto_awesome,
                                    color: HackomaticTheme.primaryGreen,
                                    size: 16,
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            parameterValues[param.name] = value;
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _executeScript(script, parameterValues);
                  },
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Quick Run'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _executeScript(script, parameterValues);
                  },
                  child: const Text('Run'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _executeScript(HackingScript script, Map<String, dynamic> parameters) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    taskProvider
        .executeScript(script, parameters)
        .then((task) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Script "${script.name}" started successfully'),
              backgroundColor: HackomaticTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View Tasks',
                onPressed: () {
                  // Could navigate to tasks screen
                },
              ),
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start script: $error'),
              backgroundColor: HackomaticTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
