import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/flat_model.dart';
import '../services/api_service.dart';
import 'flat_registration_dialog.dart';

class FlatManagementView extends StatefulWidget {
  final VoidCallback onDataChanged;

  const FlatManagementView({super.key, required this.onDataChanged});

  @override
  State<FlatManagementView> createState() => _FlatManagementViewState();
}

class _FlatManagementViewState extends State<FlatManagementView> {
  List<FlatModel> _flats = [];
  bool _isLoading = true;
  FlatStatus? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFlats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFlats() async {
    setState(() => _isLoading = true);
    final data = await ApiService.instance.getAdminFlats(
      status: _selectedStatus,
      query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
    );
    if (mounted) {
      setState(() {
        _flats = data;
        _isLoading = false;
      });
    }
  }

  void _openRegistrationDialog({FlatModel? flat}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FlatRegistrationWizardDialog(
        existingFlat: flat,
        onSaved: () {
          _loadFlats();
          widget.onDataChanged();
        },
      ),
    );
  }

  void _viewSectionsModal(FlatModel flat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${flat.name} — Sections Breakdown', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
                      Text('Total Built-up: ${flat.builtUpAreaSft} Sq. Ft. • Rate: ₹${flat.pricePerSft.toStringAsFixed(0)}/SFT', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: flat.sections.isEmpty
                  ? const Center(child: Text('No sections configured.'))
                  : ListView.separated(
                      itemCount: flat.sections.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (c, i) {
                        final s = flat.sections[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF6F0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFEADBBE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(s.sectionName, style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.royalGold),
                                    ),
                                    child: Text('${s.areaSft} Sq. Ft.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Gifted: ${s.giftedSft} SFT • Remaining: ${s.remainingSft} SFT • Price: ₹${s.totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: s.areaSft > 0 ? (s.giftedSft / s.areaSft).clamp(0.0, 1.0) : 0.0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation(AppTheme.royalGold),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveFlat(FlatModel flat) async {
    if (!flat.areaMatches) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot approve ${flat.flatId}: Section areas (${flat.totalSectionArea} SFT) do not match built-up area (${flat.builtUpAreaSft} SFT).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ApiService.instance.approveFlat(flat.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flat ${flat.name} approved successfully! Now available for wedding assignment.'),
          backgroundColor: AppTheme.greenVerified,
        ),
      );
      _loadFlats();
      widget.onDataChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve flat: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectFlat(FlatModel flat) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Reject Flat', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter reason for rejecting this flat draft:', style: GoogleFonts.outfit(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.instance.rejectFlat(flat.id, reasonController.text.trim());
      _loadFlats();
      widget.onDataChanged();
    }
  }

  Future<void> _deleteFlat(FlatModel flat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Flat', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: Colors.red.shade800)),
        content: Text('Are you sure you want to delete ${flat.name} (${flat.flatId})? This action cannot be undone.', style: GoogleFonts.outfit(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.instance.deleteFlat(flat.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flat ${flat.name} deleted.'), backgroundColor: Colors.red),
        );
        _loadFlats();
        widget.onDataChanged();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot delete flat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Action Bar & Filters
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
                        hintText: 'Search flats by name, ID, or location...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (_) => _loadFlats(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimsonMaroon,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openRegistrationDialog(),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Register Flat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Statuses', null),
                    _buildFilterChip('Draft', FlatStatus.DRAFT),
                    _buildFilterChip('Pending Approval', FlatStatus.PENDING_APPROVAL),
                    _buildFilterChip('Approved', FlatStatus.APPROVED),
                    _buildFilterChip('Assigned', FlatStatus.ASSIGNED),
                    _buildFilterChip('Completed', FlatStatus.COMPLETED),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Flats List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.crimsonMaroon))
              : _flats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('No flats found matching your filter.', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimsonMaroon),
                            onPressed: () => _openRegistrationDialog(),
                            child: const Text('Register New Flat', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _flats.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (ctx, i) => _buildFlatCard(_flats[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, FlatStatus? status) {
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
          _loadFlats();
        },
      ),
    );
  }

  Widget _buildFlatCard(FlatModel flat) {
    Color statusColor;
    switch (flat.status) {
      case FlatStatus.APPROVED:
        statusColor = AppTheme.greenVerified;
        break;
      case FlatStatus.ASSIGNED:
        statusColor = Colors.blue.shade700;
        break;
      case FlatStatus.PENDING_APPROVAL:
        statusColor = Colors.amber.shade800;
        break;
      default:
        statusColor = Colors.grey.shade700;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBBE)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flat Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF6F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.royalGold),
                  ),
                  child: Text(flat.flatId, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flat.name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    flat.status.label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
          ),

          // Flat Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: FlatRegistrationWizardDialog.buildAppImage(
                        flat.coverImageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${flat.bedrooms} BHK • ${flat.builtUpAreaSft} Sq. Ft. Total Area', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('${flat.location} • ${flat.address}', style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            'Rate: ₹${flat.pricePerSft.toStringAsFixed(0)} / SFT • ${flat.totalBricksEquivalent} Bricks (1 SFT = ${flat.bricksPerSft} Bricks)',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF78655A)),
                          ),
                          if (flat.assignedWeddingSlug != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Assigned Wedding: ${flat.assignedWeddingSlug}',
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Area Validation Banner (Fluid & Responsive - Prevents Overflow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: flat.areaMatches ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        flat.areaMatches ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 16,
                        color: flat.areaMatches ? Colors.green.shade700 : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          flat.areaMatches
                              ? 'Section Area Check: Verified (${flat.totalSectionArea} SFT across ${flat.sections.length} sections)'
                              : 'Area Warning: Sections total ${flat.totalSectionArea} SFT vs Built-up ${flat.builtUpAreaSft} SFT',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: flat.areaMatches ? Colors.green.shade800 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Gift Progress (Flexible - Prevents Overflow on Narrow Devices)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Gifted: ${flat.totalGiftedSft} / ${flat.builtUpAreaSft} SFT (${flat.totalGiftedSft * flat.bricksPerSft} Bricks)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remaining: ${flat.totalRemainingSft} SFT',
                      style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: flat.builtUpAreaSft > 0 ? (flat.totalGiftedSft / flat.builtUpAreaSft).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.royalGold),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),

                const SizedBox(height: 12),

                // Action Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      onPressed: () => _viewSectionsModal(flat),
                      icon: const Icon(Icons.view_quilt, size: 16, color: AppTheme.crimsonMaroon),
                      label: Text('View Sections (${flat.sections.length})', style: const TextStyle(fontSize: 11.5, color: AppTheme.crimsonMaroon)),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      onPressed: () => _openRegistrationDialog(flat: flat),
                      icon: const Icon(Icons.edit, size: 16, color: AppTheme.crimsonMaroon),
                      label: const Text('Edit Flat', style: TextStyle(fontSize: 11.5, color: AppTheme.crimsonMaroon)),
                    ),
                    if (flat.status == FlatStatus.PENDING_APPROVAL) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenVerified, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                        onPressed: () => _approveFlat(flat),
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Approve Flat', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                        onPressed: () => _rejectFlat(flat),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(fontSize: 11.5, color: Colors.red)),
                      ),
                    ],
                    if (flat.status == FlatStatus.DRAFT)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                        onPressed: flat.areaMatches ? () => _approveFlat(flat) : null,
                        icon: const Icon(Icons.send, size: 16, color: Colors.white),
                        label: const Text('Submit & Approve', style: TextStyle(fontSize: 11.5, color: Colors.white)),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      tooltip: 'Delete Flat',
                      onPressed: () => _deleteFlat(flat),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
