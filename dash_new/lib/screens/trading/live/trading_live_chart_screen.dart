import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TradingLiveChartScreen extends StatelessWidget {
  const TradingLiveChartScreen({super.key});
  static const route = '/trading/live';

  // tu URL específica de TradingView
  Uri get _url =>
      Uri.parse('https://es.tradingview.com/chart/?symbol=ICMARKETS%3AUSTEC');

  Future<void> _open() async {
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      await launchUrl(_url, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USTEC en vivo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pulsa para abrir el gráfico en TradingView'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _open,
                icon: const Icon(Icons.show_chart),
                label: const Text('Abrir gráfico'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
