import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/gift_transaction_model.dart';
import '../services/api_service.dart';

class GiftTransactionsView extends StatefulWidget {
  const GiftTransactionsView({super.key});

  @override
  State<GiftTransactionsView> createState() => _GiftTransactionsViewState();
}

class _GiftTransactionsViewState extends State<GiftTransactionsView> {
  List<GiftTransactionModel> _transactions = [];
  bool _isLoading = true;
  String _selectedStatus = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final data = await ApiService.instance.getAdminTransactions(
      status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
    );
    if (mounted) {
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    }
  }

  void _exportCsv() {
    final url = ApiService.instance.getTransactionsCsvExportUrl();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV Export ready at: $url'),
        backgroundColor: AppTheme.crimsonMaroon,
        action: SnackBarAction(label: 'OK', textColor: AppTheme.royalGold, onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter & Search Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by guest name, mobile, or reference ID...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (_) => _loadTransactions(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalGold,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.download, size: 18, color: Colors.white),
                    label: const Text('Export CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip('All Transactions', 'ALL'),
                    _buildStatusChip('Successful', 'SUCCESS'),
                    _buildStatusChip('Initiated', 'INITIATED'),
                    _buildStatusChip('Failed', 'FAILED'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.crimsonMaroon))
              : _transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('No gift transactions recorded yet.', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final t = _transactions[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
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
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF6F0),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.royalGold),
                                    ),
                                    child: Text(t.txnId, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.crimsonMaroon)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t.guestName,
                                      style: GoogleFonts.cinzel(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: t.paymentStatus == 'SUCCESS' ? Colors.green.shade50 : Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: t.paymentStatus == 'SUCCESS' ? Colors.green : Colors.amber),
                                    ),
                                    child: Text(
                                      t.paymentStatus,
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: t.paymentStatus == 'SUCCESS' ? Colors.green.shade800 : Colors.amber.shade900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Section: ${t.sectionName}',
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2C1810)),
                                  ),
                                  Text(
                                    '₹${t.amountPaid.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gifted: ${t.giftedSft} Sq. Ft. • Equivalent: ${t.brickEquivalent} Bricks (1 SFT = 10 Bricks)',
                                style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF78655A)),
                              ),
                              if (t.guestMobile.isNotEmpty)
                                Text('Contact: ${t.guestMobile}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                              if (t.blessingMessage != null && t.blessingMessage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('“${t.blessingMessage}”', style: GoogleFonts.outfit(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppTheme.crimsonMaroon)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.crimsonMaroon, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppTheme.crimsonMaroon,
        backgroundColor: const Color(0xFFFAF6F0),
        onSelected: (_) {
          setState(() => _selectedStatus = status);
          _loadTransactions();
        },
      ),
    );
  }
}
