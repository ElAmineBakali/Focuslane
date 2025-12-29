import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/subscription_model.dart';
import 'package:mi_dashboard_personal/services/finance/subscription_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SubscriptionsScreenV2 extends StatelessWidget {
  const SubscriptionsScreenV2({super.key});
  static const route = '/finance/subscriptions';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          const FinanceHeaderLarge(
            title: 'Suscripciones',
            icon: Icons.subscriptions_outlined,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: StreamBuilder<List<Subscription>>(
                stream: SubscriptionService.I.watchAll(),
                builder: (context, s) {
                  final subs = s.data ?? [];
                  if (subs.isEmpty) {
                    return const Center(child: Text('Sin suscripciones'));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final sub = subs[i];
                      final daysUntilDue =
                          sub.nextDue.difference(DateTime.now()).inDays;
                      final color =
                          daysUntilDue < 3 ? Colors.red : Colors.green;
                      return FinanceCard(
                        child: ListTile(
                          leading: Icon(Icons.receipt_long, color: color),
                          title: Text(
                            sub.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${sub.category} · ${sub.frequency} · ${DateFormat('d MMM', 'es').format(sub.nextDue)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${sub.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                              Text(
                                'En $daysUntilDue d',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/finance/subscriptions/edit',
                                arguments: sub,
                              ),
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
      floatingActionButton: FinanceFab(
        onPressed:
            () => Navigator.pushNamed(context, '/finance/subscriptions/edit'),
        label: 'Nueva',
        icon: Icons.add,
      ),
    );
  }
}
