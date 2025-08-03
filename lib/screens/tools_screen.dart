import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_provider.dart';
import '../models/hacking_tool.dart';
import '../utils/theme.dart';
import 'tool_detail_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<ToolProvider>(
      builder: (context, toolProvider, child) {
        return Column(
          children: [
            _buildSearchAndFilter(toolProvider),
            Expanded(child: _buildToolsList(toolProvider)),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter(ToolProvider toolProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search tools...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.filter_list),
            ),
            onChanged: (value) {
              toolProvider.searchTools(value);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: toolProvider.categories.length,
              itemBuilder: (context, index) {
                final category = toolProvider.categories[index];
                final isSelected = category == toolProvider.selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      toolProvider.filterByCategory(category);
                    },
                    backgroundColor: HackomaticTheme.cardColor,
                    selectedColor: HackomaticTheme.primaryGreen.withOpacity(
                      0.3,
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

  Widget _buildToolsList(ToolProvider toolProvider) {
    if (toolProvider.tools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build,
              size: 64,
              color: HackomaticTheme.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No tools found',
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
      itemCount: toolProvider.tools.length,
      itemBuilder: (context, index) {
        final tool = toolProvider.tools[index];
        return _buildToolCard(tool);
      },
    );
  }

  Widget _buildToolCard(HackingTool tool) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ToolDetailScreen(tool: tool),
            ),
          );
        },
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
                        Row(
                          children: [
                            Text(
                              tool.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (tool.requiresRoot) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: HackomaticTheme.errorColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ROOT',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: HackomaticTheme.errorColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tool.category,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: HackomaticTheme.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tool.isInstalled
                              ? HackomaticTheme.successColor.withOpacity(0.1)
                              : HackomaticTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tool.isInstalled ? 'Installed' : 'Not Installed',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: tool.isInstalled
                                    ? HackomaticTheme.successColor
                                    : HackomaticTheme.warningColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: HackomaticTheme.secondaryTextColor,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tool.description,
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
                    Icons.settings,
                    size: 16,
                    color: HackomaticTheme.secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${tool.parameters.length} parameters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HackomaticTheme.secondaryTextColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ToolDetailScreen(tool: tool),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Run'),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
