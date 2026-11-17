import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/admin_analytics_model.dart';
import '../services/api_service.dart';

class AdminAnalyticsView extends StatefulWidget {
  const AdminAnalyticsView({super.key});

  @override
  State<AdminAnalyticsView> createState() => _AdminAnalyticsViewState();
}

class _AdminAnalyticsViewState extends State<AdminAnalyticsView> {
  AdminAnalyticsModel? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final data = await ApiService.instance.getAdminAnalytics();
    if (mounted) {
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.crimsonMaroon));
    }

    final a = _analytics;
    if (a == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No analytics data available.', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimsonMaroon),
              onPressed: _loadAnalytics,
              child: const Text('Refresh', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Text('Platform Portfolio & Gifting KPI Metrics', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh, color: AppTheme.crimsonMaroon), onPressed: _loadAnalytics),
            ],
          ),
          const SizedBox(height: 14),

          // 10 KPI Metric Cards Grid
          LayoutBuilder(
            builder: (ctx, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _buildKpiCard('Total Registered Flats', '${a.totalRegisteredFlats}', Icons.apartment, Colors.indigo),
                  _buildKpiCard('Approved Flats', '${a.approvedFlats}', Icons.check_circle, AppTheme.greenVerified),
                  _buildKpiCard('Pending Approval', '${a.pendingApprovalFlats}', Icons.pending_actions, Colors.amber.shade800),
                  _buildKpiCard('Assigned Flats', '${a.assignedFlats}', Icons.link, Colors.blue.shade700),
                  _buildKpiCard('Active Weddings', '${a.totalWeddings}', Icons.favorite, AppTheme.crimsonMaroon),
                  _buildKpiCard('Total Gifted Sq. Ft.', '${a.totalGiftedSqFt} SFT', Icons.square_foot, AppTheme.royalGold),
                  _buildKpiCard('Remaining Sq. Ft.', '${a.totalRemainingSqFt} SFT', Icons.pie_chart, Colors.teal),
                  _buildKpiCard('Total Gift Amount', '₹${a.totalGiftAmount.toStringAsFixed(0)}', Icons.currency_rupee, Colors.green.shade800),
                  _buildKpiCard('Total Bricks Gifted', '${a.totalGiftedSqFt * 10} Bricks', Icons.view_module, Colors.deepOrange),
                  _buildKpiCard('Total Portfolio Area', '${a.totalBuiltUpAreaSft} SFT', Icons.domain, Colors.brown),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Section-wise Gifting Breakdown
          Text('Section-wise Gifting Distribution', style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEADBBE)),
            ),
            child: a.sectionWiseBreakdown.isEmpty
                ? const Center(child: Text('No section breakdown available.'))
                : Column(
                    children: a.sectionWiseBreakdown.map((s) {
                      final pct = (s.totalSft > 0) ? (s.giftedSft / s.totalSft).clamp(0.0, 1.0) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(s.sectionName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${s.giftedSft} / ${s.totalSft} Sq. Ft. (${(pct * 100).toStringAsFixed(1)}%)', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: pct,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(AppTheme.royalGold),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 24),

          // Flat-wise Progress Breakdown
          Text('Flat-wise Campaign Progress', style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEADBBE)),
            ),
            child: a.flatWiseProgress.isEmpty
                ? const Center(child: Text('No flats found.'))
                : Column(
                    children: a.flatWiseProgress.map((f) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('${f.flatId} • ${f.status}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${f.giftedSft} / ${f.totalSft} SFT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('${f.progressPercent}% funded', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.greenVerified)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBBE)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, overflow: TextOverflow.ellipsis, style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810))),
        ],
      ),
    );
  }
}
