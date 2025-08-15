import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Temporarily disabled
// import '../providers/bluetooth_provider.dart'; // Temporarily disabled
import '../utils/theme.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'; // Temporarily disabled

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final TextEditingController _commandController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBluetoothStatus(),
        Expanded(child: _buildBluetoothUnavailable()),
      ],
    );
  }

  Widget _buildBluetoothStatus() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.bluetooth_disabled,
                size: 32,
                color: HackomaticTheme.secondaryTextColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bluetooth',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Temporarily Unavailable',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HackomaticTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothUnavailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 64,
            color: HackomaticTheme.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Bluetooth Feature Temporarily Disabled',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HackomaticTheme.secondaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The Bluetooth functionality is temporarily disabled due to compatibility issues. It will be restored in a future update.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: HackomaticTheme.warningColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: HackomaticTheme.warningColor,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Alternative Features Available',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: HackomaticTheme.warningColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• WiFi scanning and monitoring\n'
                    '• Network discovery tools\n'
                    '• Port scanning utilities\n'
                    '• Terminal access for manual commands',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HackomaticTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }
}
