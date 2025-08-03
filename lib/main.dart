import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/tool_provider.dart';
import 'providers/script_provider.dart';
import 'providers/task_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'utils/theme.dart';

void main() {
  runApp(const HackomaticApp());
}

class HackomaticApp extends StatelessWidget {
  const HackomaticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ToolProvider()),
        ChangeNotifierProvider(create: (_) => ScriptProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
      ],
      child: MaterialApp(
        title: 'Hackomatic',
        theme: HackomaticTheme.darkTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
