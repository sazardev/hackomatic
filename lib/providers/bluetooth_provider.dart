import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> _bondedDevices = [];
  BluetoothConnection? _connection;
  bool _isScanning = false;
  bool _isConnected = false;
  String? _connectedDeviceName;

  BluetoothState get bluetoothState => _bluetoothState;
  List<BluetoothDevice> get devices => _devices;
  List<BluetoothDevice> get bondedDevices => _bondedDevices;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDeviceName;

  BluetoothProvider() {
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      // Check if platform supports Bluetooth
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        if (kDebugMode) {
          print('ℹ️ Bluetooth not supported on ${Platform.operatingSystem}');
        }
        return;
      }

      // Get current state
      _bluetoothState = await FlutterBluetoothSerial.instance.state;

      // Listen to state changes
      FlutterBluetoothSerial.instance.onStateChanged().listen((
        BluetoothState state,
      ) {
        _bluetoothState = state;
        notifyListeners();
      });

      // Get bonded devices
      await _getBondedDevices();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Bluetooth: $e');
        // For desktop platforms, this is expected
        if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
          print('💡 This is expected on desktop platforms');
        }
      }
    }
  }

  Future<bool> requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    return statuses.values.every(
      (status) =>
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited,
    );
  }

  Future<void> enableBluetooth() async {
    try {
      await FlutterBluetoothSerial.instance.requestEnable();
    } catch (e) {
      if (kDebugMode) {
        print('Error enabling Bluetooth: $e');
      }
    }
  }

  Future<void> _getBondedDevices() async {
    try {
      _bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bonded devices: $e');
      }
    }
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      if (kDebugMode) {
        print('Bluetooth permissions not granted');
      }
      return;
    }

    try {
      _isScanning = true;
      _devices.clear();
      notifyListeners();

      FlutterBluetoothSerial.instance
          .startDiscovery()
          .listen((result) {
            final existingIndex = _devices.indexWhere(
              (device) => device.address == result.device.address,
            );
            if (existingIndex >= 0) {
              _devices[existingIndex] = result.device;
            } else {
              _devices.add(result.device);
            }
            notifyListeners();
          })
          .onDone(() {
            _isScanning = false;
            notifyListeners();
          });
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error starting scan: $e');
      }
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping scan: $e');
      }
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      if (_connection?.isConnected == true) {
        await disconnect();
      }

      _connection = await BluetoothConnection.toAddress(device.address);
      _isConnected = true;
      _connectedDeviceName = device.name ?? device.address;

      // Listen for disconnection
      _connection!.input!.listen(
        (data) {
          // Handle incoming data if needed
        },
        onDone: () {
          _isConnected = false;
          _connectedDeviceName = null;
          _connection = null;
          notifyListeners();
        },
        onError: (error) {
          _isConnected = false;
          _connectedDeviceName = null;
          _connection = null;
          notifyListeners();
        },
      );

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error connecting to device: $e');
      }
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      _isConnected = false;
      _connectedDeviceName = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error disconnecting: $e');
      }
    }
  }

  Future<bool> sendCommand(String command) async {
    if (!_isConnected || _connection == null) {
      return false;
    }

    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
      await _connection!.output.allSent;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending command: $e');
      }
      return false;
    }
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
