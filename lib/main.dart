import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SimDebugPage(),
    );
  }
}

class SimDebugPage extends StatefulWidget {
  const SimDebugPage({super.key});

  @override
  State<SimDebugPage> createState() => _SimDebugPageState();
}

class _SimDebugPageState extends State<SimDebugPage> {
  static const MethodChannel _channel = MethodChannel('sim_info');

  String status = "Press Refresh";

  Future<void> refresh() async {
    setState(() => status = "Calling iOS...");
    try {
      final res = await _channel.invokeMethod('getMccMnc');
      setState(() => status = "✅ Response:\n$res");
      // ignore: avoid_print
      print("✅ Response: $res");
    } catch (e) {
      setState(() => status = "❌ Error:\n$e");
      // ignore: avoid_print
      print("❌ Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SIM MCC/MNC Debug")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: Text(status)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
