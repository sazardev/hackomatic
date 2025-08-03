import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../utils/theme.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final TextEditingController _commandController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bluetoothProvider, child) {
        return Column(
          children: [
            _buildBluetoothStatus(bluetoothProvider),
            if (bluetoothProvider.bluetoothState ==
                BluetoothState.STATE_ON) ...[
              _buildConnectionStatus(bluetoothProvider),
              Expanded(child: _buildDevicesList(bluetoothProvider)),
              if (bluetoothProvider.isConnected)
                _buildCommandInput(bluetoothProvider),
            ] else
              Expanded(child: _buildBluetoothDisabled(bluetoothProvider)),
          ],
        );
      },
    );
  }

  Widget _buildBluetoothStatus(BluetoothProvider bluetoothProvider) {
    final isEnabled =
        bluetoothProvider.bluetoothState == BluetoothState.STATE_ON;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.bluetooth,
                size: 32,
                color: isEnabled
                    ? HackomaticTheme.primaryGreen
                    : HackomaticTheme.secondaryTextColor,
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
                      isEnabled ? 'Enabled' : 'Disabled',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isEnabled
                            ? HackomaticTheme.successColor
                            : HackomaticTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isEnabled)
                ElevatedButton(
                  onPressed: () => bluetoothProvider.enableBluetooth(),
                  child: const Text('Enable'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BluetoothProvider bluetoothProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                bluetoothProvider.isConnected ? Icons.link : Icons.link_off,
                size: 24,
                color: bluetoothProvider.isConnected
                    ? HackomaticTheme.successColor
                    : HackomaticTheme.secondaryTextColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bluetoothProvider.isConnected
                          ? 'Connected'
                          : 'Not Connected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bluetoothProvider.isConnected &&
                        bluetoothProvider.connectedDeviceName != null)
                      Text(
                        bluetoothProvider.connectedDeviceName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HackomaticTheme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (bluetoothProvider.isConnected)
                TextButton(
                  onPressed: () => bluetoothProvider.disconnect(),
                  child: const Text('Disconnect'),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bluetoothProvider.isScanning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => bluetoothProvider.startScan(),
                        child: const Text('Scan'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevicesList(BluetoothProvider bluetoothProvider) {
    final allDevices = [
      ...bluetoothProvider.bondedDevices,
      ...bluetoothProvider.devices,
    ];

    // Remove duplicates
    final uniqueDevices = <String, BluetoothDevice>{};
    for (final device in allDevices) {
      uniqueDevices[device.address] = device;
    }

    final devices = uniqueDevices.values.toList();

    if (devices.isEmpty && !bluetoothProvider.isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 64,
              color: HackomaticTheme.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No devices found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap scan to discover nearby devices',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HackomaticTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => bluetoothProvider.startScan(),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Start Scan'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Available Devices',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (bluetoothProvider.isScanning)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scanning...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HackomaticTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final isBonded = bluetoothProvider.bondedDevices.any(
                (bonded) => bonded.address == device.address,
              );
              final isConnected =
                  bluetoothProvider.isConnected &&
                  bluetoothProvider.connectedDeviceName == device.name;

              return _buildDeviceCard(
                device,
                isBonded,
                isConnected,
                bluetoothProvider,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(
    BluetoothDevice device,
    bool isBonded,
    bool isConnected,
    BluetoothProvider bluetoothProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isConnected
              ? HackomaticTheme.successColor.withOpacity(0.1)
              : HackomaticTheme.primaryGreen.withOpacity(0.1),
          child: Icon(
            _getDeviceIcon(device),
            color: isConnected
                ? HackomaticTheme.successColor
                : HackomaticTheme.primaryGreen,
          ),
        ),
        title: Text(
          device.name?.isNotEmpty == true ? device.name! : 'Unknown Device',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.address),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isBonded) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: HackomaticTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Bonded',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HackomaticTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: HackomaticTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Connected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HackomaticTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: isConnected
            ? IconButton(
                icon: const Icon(Icons.link_off),
                onPressed: () => bluetoothProvider.disconnect(),
                color: HackomaticTheme.errorColor,
              )
            : IconButton(
                icon: const Icon(Icons.link),
                onPressed: () => _connectToDevice(device, bluetoothProvider),
                color: HackomaticTheme.primaryGreen,
              ),
      ),
    );
  }

  IconData _getDeviceIcon(BluetoothDevice device) {
    // You could check device.type or device.bondState for more specific icons
    return Icons.devices;
  }

  Widget _buildCommandInput(BluetoothProvider bluetoothProvider) {
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
            child: TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                hintText: 'Enter command...',
                prefixIcon: Icon(Icons.terminal),
              ),
              onSubmitted: (command) =>
                  _sendCommand(command, bluetoothProvider),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () =>
                _sendCommand(_commandController.text, bluetoothProvider),
            icon: const Icon(Icons.send),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothDisabled(BluetoothProvider bluetoothProvider) {
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
            'Bluetooth is disabled',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HackomaticTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable Bluetooth to discover and connect to devices',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HackomaticTheme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => bluetoothProvider.enableBluetooth(),
            icon: const Icon(Icons.bluetooth),
            label: const Text('Enable Bluetooth'),
          ),
        ],
      ),
    );
  }

  void _connectToDevice(
    BluetoothDevice device,
    BluetoothProvider bluetoothProvider,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Connecting...'),
          ],
        ),
      ),
    );

    final success = await bluetoothProvider.connectToDevice(device);

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name ?? device.address}'),
            backgroundColor: HackomaticTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to connect to ${device.name ?? device.address}',
            ),
            backgroundColor: HackomaticTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _sendCommand(String command, BluetoothProvider bluetoothProvider) async {
    if (command.trim().isEmpty) return;

    final success = await bluetoothProvider.sendCommand(command);

    if (success) {
      _commandController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Command sent: $command'),
          backgroundColor: HackomaticTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send command'),
          backgroundColor: HackomaticTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }
}
