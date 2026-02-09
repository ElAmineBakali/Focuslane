import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/finance/models/subscription_model.dart';
import 'package:mi_dashboard_personal/screens/finance/services/subscription_service.dart';

import '../../../../ui/components/focus_card.dart';
import '../../../../ui/components/focus_module_header.dart';
import '../../../../ui/tokens/focuslane_tokens.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({
    super.key,
    required this.onBackToDashboard,
  });

  final VoidCallback onBackToDashboard;

  static const route = '/finance/subscriptions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: FocusModuleHeader(
        title: 'Finanzas',
        subtitle: 'Suscripciones',
        leadingMode: FocusModuleLeadingMode.backToModuleDashboard,
        onBack: onBackToDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva suscripción',
            onPressed: () =>
                Navigator.pushNamed(context, '/finance/subscriptions/form'),
          ),
        ],
      ),
      body: Padding(
        padding: FocuslaneTokens.pagePaddingCompact,
        child: Column(
          children: [
            Expanded(
              child: FocusCard(
                padding: const EdgeInsets.all(12),
                child: StreamBuilder<List<Subscription>>(
                  stream: SubscriptionService.I.watchAll(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final subs = snap.data ?? const [];
                    if (subs.isEmpty) {
                      return const Center(child: Text('Sin suscripciones'));
                    }
                    return ListView.separated(
                      itemCount: subs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = subs[i];
                        final daysLeft =
                            s.nextDue.difference(DateTime.now()).inDays;
                        return ListTile(
                          title: Text(s.title),
                          subtitle: Text(
                            '${s.category ?? 'General'} · ${s.frequency}',
                          ),
                          trailing: Text('En $daysLeft d'),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/finance/subscriptions/form',
                            arguments: s,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



