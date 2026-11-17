import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/flat_model.dart';
import '../services/api_service.dart';

class WeddingManagementView extends StatefulWidget {
  final VoidCallback onDataChanged;

  const WeddingManagementView({super.key, required this.onDataChanged});

  @override
  State<WeddingManagementView> createState() => _WeddingManagementViewState();
}

class _WeddingManagementViewState extends State<WeddingManagementView> {
  List<Map<String, dynamic>> _weddings = [];
  List<FlatModel> _approvedFlats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final weddingsData = await ApiService.instance.getWeddings();
    final flatsData = await ApiService.instance.getAdminFlats(status: FlatStatus.APPROVED);

    if (mounted) {
      setState(() {
        _weddings = weddingsData;
        _approvedFlats = flatsData;
        _isLoading = false;
      });
    }
  }

  void _openAssignFlatDialog(Map<String, dynamic> wedding) {
    FlatModel? selectedFlat;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Assign Flat to Wedding', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Couple: ${wedding['groomName']} & ${wedding['brideName']} (${wedding['slug']})', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 14),
              Text('Select an Approved Real Estate Flat:', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              if (_approvedFlats.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text('No approved flats available. Please register and approve a flat in the Flat Management tab first.', style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
                )
              else
                DropdownButtonFormField<FlatModel>(
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  hint: const Text('Choose Approved Flat'),
                  initialValue: selectedFlat,
                  items: _approvedFlats.map((f) {
                    return DropdownMenuItem<FlatModel>(
                      value: f,
                      child: Text('${f.flatId} - ${f.name} (${f.builtUpAreaSft} SFT)', style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedFlat = val),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimsonMaroon),
              onPressed: selectedFlat == null
                  ? null
                  : () async {
                      final weddingId = wedding['id'] is int ? wedding['id'] as int : int.tryParse(wedding['id'].toString()) ?? 1;
                      await ApiService.instance.assignFlatToWedding(selectedFlat!.id, weddingId);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _loadData();
                      widget.onDataChanged();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Assigned ${selectedFlat!.name} to ${wedding['slug']} successfully!'),
                          backgroundColor: AppTheme.greenVerified,
                        ),
                      );
                    },
              child: const Text('Assign Flat', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.crimsonMaroon));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Wedding Campaigns & Flat Assignments', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh, color: AppTheme.crimsonMaroon), onPressed: _loadData),
            ],
          ),
          const SizedBox(height: 12),
          _weddings.isEmpty
              ? const Center(child: Text('No active wedding campaigns.'))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _weddings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) {
                    final w = _weddings[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEADBBE)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${w['groomName']} & ${w['brideName']}', style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.greenVerified.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.greenVerified),
                                ),
                                child: Text('ACTIVE CAMPAIGN', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.greenVerified)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Slug: ${w['slug']} • Goal: ${w['targetSft']} Sq. Ft. @ ₹${w['rateSft']}/SFT', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimsonMaroon, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                onPressed: () => _openAssignFlatDialog(w),
                                icon: const Icon(Icons.apartment, size: 16, color: Colors.white),
                                label: const Text('Assign Approved Flat', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.royalGold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Wedding URL: https://plottheirfuture.in/weddings/${w['slug']}'), backgroundColor: AppTheme.crimsonMaroon),
                                  );
                                },
                                icon: const Icon(Icons.link, size: 16, color: AppTheme.crimsonMaroon),
                                label: const Text('Share URL', style: TextStyle(color: AppTheme.crimsonMaroon, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
