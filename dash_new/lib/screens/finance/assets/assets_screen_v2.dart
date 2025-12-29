import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/theme/finance_ui_theme.dart';
import 'package:mi_dashboard_personal/models/finance/asset_model.dart';
import 'package:mi_dashboard_personal/services/finance/asset_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AssetsScreenV2 extends StatelessWidget {
  const AssetsScreenV2({super.key});
  static const route = '/finance/assets';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FinanceScreenBody(
        slivers: [
          const FinanceHeaderLarge(
            title: 'Patrimonio (Activos)',
            icon: Icons.account_balance_wallet_outlined,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: StreamBuilder<List<Asset>>(
                stream: AssetService.I.watchAll(),
                builder: (context, s) {
                  final assets = s.data ?? [];
                  if (assets.isEmpty) {
                    return const Center(child: Text('Sin activos registrados'));
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: assets.length,
                    itemBuilder: (context, i) {
                      final a = assets[i];
                      return FinanceCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (a.photoUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  a.photoUrl!,
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image, size: 40),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              a.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              a.type,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              a.currentValue.toStringAsFixed(2),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
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
        onPressed: () => Navigator.pushNamed(context, '/finance/assets/edit'),
        label: 'Nuevo activo',
        icon: Icons.add,
      ),
    );
  }
}
