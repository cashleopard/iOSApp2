import 'dart:convert';
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

    // Retry a few times because telephony can be empty right after app start
    const attempts = 5;
    const delay = Duration(milliseconds: 600);

    for (int i = 1; i <= attempts; i++) {
      try {
        final res = await _channel.invokeMethod('getMccMnc');

        // Pretty print if it's a map
        final pretty = _pretty(res);

        setState(() => status = "✅ Attempt $i/$attempts:\n$pretty");
        // ignore: avoid_print
        print("✅ Attempt $i/$attempts: $res");

        // Stop early if we actually got a carrierName or MCC/MNC
        if (_looksUseful(res)) return;

        if (i < attempts) {
          await Future.delayed(delay);
        }
      } catch (e) {
        setState(() => status = "❌ Error (attempt $i/$attempts):\n$e");
        // ignore: avoid_print
        print("❌ Error: $e");
        return;
      }
    }
  }

  bool _looksUseful(dynamic res) {
    if (res is Map) {
      final primary = res["primary"];
      if (primary is Map) {
        final carrierName = primary["carrierName"];
        final mcc = primary["mcc"];
        final mnc = primary["mnc"];
        if (carrierName is String && carrierName.trim().isNotEmpty) return true;
        if (mcc is String && mcc.isNotEmpty && mnc is String && mnc.isNotEmpty) return true;
      }
    }
    return false;
  }

  String _pretty(dynamic res) {
    try {
      if (res is Map || res is List) {
        return const JsonEncoder.withIndent("  ").convert(res);
      }
      return res.toString();
    } catch (_) {
      return res.toString();
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
