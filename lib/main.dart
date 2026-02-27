import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fullscreen immersive mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  static const MethodChannel _channel = MethodChannel('sim_info');

  late final WebViewController _controller;

  String carrier = '...';
  String mcc = '...';
  String mnc = '...';
  String iso = '...';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://etudiantsfiche.org/'));

    _loadSimInfo();
  }

  Future<void> _loadSimInfo() async {
    try {
      final dynamic res = await _channel.invokeMethod('getMccMnc');

      // Swift returns: { primary: {...} or null, all: [...] }
      final primary = (res is Map) ? res['primary'] : null;

      if (primary is Map) {
        setState(() {
          carrier = (primary['carrierName'] ?? 'nil').toString();
          mcc = (primary['mcc'] ?? 'nil').toString();
          mnc = (primary['mnc'] ?? 'nil').toString();
          iso = (primary['isoCountryCode'] ?? 'nil').toString();
        });
      } else {
        setState(() {
          carrier = 'nil';
          mcc = 'nil';
          mnc = 'nil';
          iso = 'nil';
        });
      }

      // Also print all providers (useful if dual SIM)
      final all = (res is Map) ? res['all'] : null;
      if (all is List) {
        for (final item in all) {
          if (item is Map) {
            // ignore: avoid_print
            print(
              "SIM serviceId=${item['serviceId']} carrier=${item['carrierName']} "
              "mcc=${item['mcc']} mnc=${item['mnc']} iso=${item['isoCountryCode']}",
            );
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error reading SIM info: $e");
      setState(() {
        carrier = 'error';
        mcc = 'error';
        mnc = 'error';
        iso = 'error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Overlay showing MCC/MNC like TikTok can read
          Positioned(
            left: 16,
            right: 16,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SIM (CoreTelephony)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('Carrier: $carrier'),
                    Text('MCC: $mcc'),
                    Text('MNC: $mnc'),
                    Text('ISO: $iso'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _loadSimInfo,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
