import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/flat_model.dart';
import '../models/marriage_submission_model.dart';
import '../services/api_service.dart';
import '../state/wedding_registry_service.dart';
import '../widgets/flat_management_view.dart';
import '../widgets/wedding_management_view.dart';
import '../widgets/admin_analytics_view.dart';
import '../widgets/gift_transactions_view.dart';
import '../widgets/osm_map_modal.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedModuleIndex = 0;
  List<MarriageSubmission> _allSubmissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSubmissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    final data = await ApiService.instance.getAdminMarriageRegistrations();
    if (mounted) {
      setState(() {
        _allSubmissions = data;
        _isLoading = false;
      });
    }
  }

  List<MarriageSubmission> get _pendingSubmissions =>
      _allSubmissions.where((s) => s.status == 'PENDING_ADMIN_APPROVAL').toList();

  List<MarriageSubmission> get _approvedSubmissions =>
      _allSubmissions.where((s) => s.status == 'APPROVED' || s.status == 'ACTIVE').toList();

  void _openDetailAndAssignFlatModal(MarriageSubmission submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminSubmissionDetailSheet(
        submission: submission,
        onApproved: () {
          _loadSubmissions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivoryBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Navigator.of(context).canPop() ? Icons.arrow_back_ios : Icons.home_outlined,
            color: AppTheme.crimsonMaroon,
            size: 18,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.crimsonMaroon.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings, color: AppTheme.crimsonMaroon, size: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin Moderation Console',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cinzel(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                  ),
                  Text(
                    'Verify Contacts • Assign Flat • Curation',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.royalGold),
            onPressed: _loadSubmissions,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.crimsonMaroon),
            tooltip: 'Admin Menu',
            onSelected: (val) {
              if (val == 'home') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              } else if (val == 'logout') {
                ApiService.instance.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen(onLoginSuccess: () {})),
                  (route) => false,
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'home',
                child: Row(
                  children: [
                    Icon(Icons.home_outlined, size: 18, color: AppTheme.crimsonMaroon),
                    SizedBox(width: 8),
                    Text('View User Home'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout Admin'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_selectedModuleIndex == 0 ? 94 : 48),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModuleNavPill(0, 'Submissions', Icons.assignment_outlined),
                      const SizedBox(width: 8),
                      _buildModuleNavPill(1, 'Flat Management', Icons.apartment),
                      const SizedBox(width: 8),
                      _buildModuleNavPill(2, 'Weddings', Icons.favorite_border),
                      const SizedBox(width: 8),
                      _buildModuleNavPill(3, 'Analytics', Icons.analytics_outlined),
                      const SizedBox(width: 8),
                      _buildModuleNavPill(4, 'Transactions', Icons.receipt_long),
                    ],
                  ),
                ),
              ),
              if (_selectedModuleIndex == 0)
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.crimsonMaroon,
                  unselectedLabelColor: AppTheme.textMuted,
                  indicatorColor: AppTheme.crimsonMaroon,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: 'Pending (${_pendingSubmissions.length})'),
                    Tab(text: 'Approved (${_approvedSubmissions.length})'),
                    Tab(text: 'All (${_allSubmissions.length})'),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: _buildCurrentModuleBody(),
    );
  }

  Widget _buildCurrentModuleBody() {
    switch (_selectedModuleIndex) {
      case 1:
        return FlatManagementView(onDataChanged: _loadSubmissions);
      case 2:
        return WeddingManagementView(onDataChanged: _loadSubmissions);
      case 3:
        return const AdminAnalyticsView();
      case 4:
        return const GiftTransactionsView();
      case 0:
      default:
        return _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.crimsonMaroon))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildSubmissionsList(_pendingSubmissions, isPending: true),
                  _buildSubmissionsList(_approvedSubmissions, isPending: false),
                  _buildSubmissionsList(_allSubmissions, isPending: null),
                ],
              );
    }
  }

  Widget _buildModuleNavPill(int index, String label, IconData icon) {
    final isSelected = _selectedModuleIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedModuleIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.crimsonMaroon : const Color(0xFFFAF6F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.crimsonMaroon : const Color(0xFFEADBBE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : AppTheme.crimsonMaroon),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.crimsonMaroon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsList(List<MarriageSubmission> list, {bool? isPending}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 54, color: AppTheme.royalGold.withOpacity(0.5)),
              const SizedBox(height: 14),
              Text(
                'No Submissions in this View',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                isPending == true
                    ? 'All incoming couple registrations have been reviewed and approved!'
                    : 'Submit a new marriage registration to see it appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildSubmissionCard(item);
      },
    );
  }

  Widget _buildSubmissionCard(MarriageSubmission item) {
    final isPending = item.status == 'PENDING_ADMIN_APPROVAL';
    final isApproved = item.isApproved;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? AppTheme.royalGold.withOpacity(0.6) : const Color(0xFFE2E8F0),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetailAndAssignFlatModal(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Reference + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.referenceNumber,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.royalGold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending
                            ? const Color(0xFFFFF7ED)
                            : (isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPending
                              ? const Color(0xFFFDBA74)
                              : (isApproved ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5)),
                        ),
                      ),
                      child: Text(
                        item.status.replaceAll('_', ' '),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPending
                              ? const Color(0xFFC2410C)
                              : (isApproved ? AppTheme.greenVerified : AppTheme.crimsonMaroon),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Couple Names
                Text(
                  '${item.bride.name} & ${item.groom.name}',
                  style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),

                // Contacts Row with Icon
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    const Icon(Icons.phone, size: 13, color: AppTheme.crimsonMaroon),
                    Text(
                      'Primary: ${item.primaryContactNumber}',
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                    Text('•', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                    const Icon(Icons.location_on, size: 13, color: AppTheme.royalGold),
                    Text(
                      item.city,
                      style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Functions Badge Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.ivoryBackground, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${item.enabledFunctions.length} Functions Enabled',
                        style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                      ),
                    ),
                    ...item.enabledFunctions.take(3).map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            f.name,
                            style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF475569)),
                          ),
                        )),
                    if (item.enabledFunctions.length > 3)
                      Text(
                        '+${item.enabledFunctions.length - 3} more',
                        style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted),
                      ),
                  ],
                ),

                const Divider(height: 20),

                // Bottom Action Row
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isApproved && item.assignedFlat != null)
                      Text(
                        'Flat: ${item.assignedFlat!.unitNumber}',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.greenVerified),
                      )
                    else
                      Text(
                        'Wedding: ${DateFormat('dd MMM yyyy').format(item.weddingDate)}',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _openDetailAndAssignFlatModal(item),
                      icon: Icon(isPending ? Icons.edit_note : Icons.visibility, size: 14, color: Colors.white),
                      label: Text(
                        isPending ? 'Inspect & Assign Flat ➔' : 'View Dossier ➔',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPending ? AppTheme.crimsonMaroon : const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADMIN SUBMISSION DETAIL & FLAT ASSIGNMENT MODAL SHEET
// ---------------------------------------------------------------------------

class _AdminSubmissionDetailSheet extends StatefulWidget {
  final MarriageSubmission submission;
  final VoidCallback onApproved;

  const _AdminSubmissionDetailSheet({
    required this.submission,
    required this.onApproved,
  });

  @override
  State<_AdminSubmissionDetailSheet> createState() => _AdminSubmissionDetailSheetState();
}

class _AdminSubmissionDetailSheetState extends State<_AdminSubmissionDetailSheet> {
  late MarriageSubmission _currentSubmission;
  List<FlatModel> _approvedFlats = [];
  FlatModel? _selectedFlat;
  bool _isLoadingFlats = true;

  late TextEditingController _slugController;
  late TextEditingController _builderController;
  late TextEditingController _projectController;
  late TextEditingController _towerController;
  late TextEditingController _unitController;
  late TextEditingController _bhkController;
  late TextEditingController _targetSftController;
  late TextEditingController _rateSftController;
  late TextEditingController _reraIdController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _upiVpaController;
  late TextEditingController _videoStreamController;

  bool _isApproving = false;

  @override
  void initState() {
    super.initState();
    _currentSubmission = widget.submission;
    final item = widget.submission;
    final defaultSlug = item.slug ??
        '${item.groom.name.split(" ").first}-${item.bride.name.split(" ").first}'
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    _slugController = TextEditingController(text: defaultSlug);
    _builderController = TextEditingController(text: item.assignedFlat?.builderName ?? 'My Home Constructions');
    _projectController = TextEditingController(text: item.assignedFlat?.projectName ?? 'My Home Bhooja');
    _towerController = TextEditingController(text: item.assignedFlat?.tower ?? 'Tower 3');
    _unitController = TextEditingController(text: item.assignedFlat?.unitNumber ?? 'Flat 1402 (14th Floor)');
    _bhkController = TextEditingController(text: item.assignedFlat?.configuration ?? item.targetBhk);
    _targetSftController = TextEditingController(text: (item.assignedFlat?.targetSft ?? 1200).toString());
    _rateSftController = TextEditingController(text: (item.assignedFlat?.rateSft ?? 4500.0).toStringAsFixed(0));
    _reraIdController = TextEditingController(text: item.assignedFlat?.builderReraId ?? 'PRM/KA/RERA/1251/310/PR/210312/004018');
    _bankNameController = TextEditingController(text: item.assignedFlat?.escrowBank.bankName ?? 'HDFC Bank Ltd');
    _accountNumberController = TextEditingController(text: item.assignedFlat?.escrowBank.accountNumber ?? 'ESC-HDFC-99201948102');
    _ifscController = TextEditingController(text: item.assignedFlat?.escrowBank.ifscCode ?? 'HDFC0000456');
    _upiVpaController = TextEditingController(text: item.assignedFlat?.escrowBank.upiVpa ?? 'plottheirfuture.escrow@hdfcbank');
    _videoStreamController = TextEditingController(text: item.videoStreamUrl ?? 'https://cdn.plottheirfuture.in/stream/master.m3u8');

    _loadFullDetailsAndFlats();
  }

  Future<void> _loadFullDetailsAndFlats() async {
    // 1. Fetch fresh registration details to ensure functions and media are populated
    try {
      final fresh = await ApiService.instance.getAdminMarriageRegistration(widget.submission.id);
      if (fresh != null && mounted) {
        setState(() {
          _currentSubmission = fresh;
        });
      }
    } catch (e) {
      debugPrint('[AdminDashboard] Error refreshing submission details: $e');
    }

    // 2. Fetch approved flats from Flat Management
    try {
      final flats = await ApiService.instance.getAdminFlats(status: FlatStatus.APPROVED);
      if (mounted) {
        final unassigned = flats.where((f) =>
          f.status == FlatStatus.APPROVED &&
          (f.assignedWeddingId == null || f.assignedWeddingId == 0)
        ).toList();

        setState(() {
          _approvedFlats = unassigned;
          _isLoadingFlats = false;

          // If current submission already has an assigned flat or there are unassigned flats, match or select
          if (_currentSubmission.assignedFlat != null) {
            _selectedFlat = flats.cast<FlatModel?>().firstWhere(
              (f) => f?.flatId == _currentSubmission.assignedFlat?.unitNumber ||
                     f?.name == _currentSubmission.assignedFlat?.projectName,
              orElse: () => unassigned.isNotEmpty ? unassigned.first : null,
            );
          } else if (unassigned.isNotEmpty) {
            _selectedFlat = unassigned.first;
            _onFlatSelected(unassigned.first);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFlats = false);
      }
      debugPrint('[AdminDashboard] Error loading approved flats: $e');
    }
  }

  void _onFlatSelected(FlatModel flat) {
    setState(() {
      _selectedFlat = flat;
      _builderController.text = flat.location.split('•').first.trim().isNotEmpty
          ? flat.location.split('•').first.trim()
          : 'Verified Developer';
      _projectController.text = flat.name;
      _towerController.text = flat.address.isNotEmpty ? flat.address : 'Tower A';
      _unitController.text = flat.flatId;
      _bhkController.text = '${flat.bedrooms} BHK';
      _targetSftController.text = flat.builtUpAreaSft.toString();
      _rateSftController.text = flat.pricePerSft.toInt().toString();
      _reraIdController.text = 'PRM/RERA/${flat.flatId}';
    });
  }

  Widget _buildAppImage(
    String? path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    if (path == null || path.trim().isEmpty) {
      return placeholder ??
          Container(
            width: width,
            height: height,
            color: AppTheme.ivoryBackground,
            child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.textMuted),
          );
    }
    final trimmed = path.trim();
    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholder ??
            Container(
              width: width,
              height: height,
              color: AppTheme.ivoryBackground,
              child: const Icon(Icons.broken_image, color: AppTheme.textMuted),
            ),
      );
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholder ??
            Container(
              width: width,
              height: height,
              color: AppTheme.ivoryBackground,
              child: const Icon(Icons.broken_image, color: AppTheme.textMuted),
            ),
      );
    }
    final file = File(trimmed);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholder ??
            Container(
              width: width,
              height: height,
              color: AppTheme.ivoryBackground,
              child: const Icon(Icons.broken_image, color: AppTheme.textMuted),
            ),
      );
    }
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: AppTheme.ivoryBackground,
          child: const Icon(Icons.image, color: AppTheme.textMuted),
        );
  }

  void _showMediaPreviewDialog(BuildContext context, {required String title, required String path, bool isVideo = false}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 460),
                color: Colors.black,
                child: Center(
                  child: isVideo
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_filled, size: 64, color: Colors.white70),
                            const SizedBox(height: 12),
                            Text(
                              'Wedding Invitation Video Reel',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                path,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11),
                              ),
                            ),
                          ],
                        )
                      : _buildAppImage(path, fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slugController.dispose();
    _builderController.dispose();
    _projectController.dispose();
    _towerController.dispose();
    _unitController.dispose();
    _bhkController.dispose();
    _targetSftController.dispose();
    _rateSftController.dispose();
    _reraIdController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _upiVpaController.dispose();
    _videoStreamController.dispose();
    super.dispose();
  }

  Future<void> _handleApproveAndAssignFlat() async {
    setState(() => _isApproving = true);

    try {
      final targetSft = int.tryParse(_targetSftController.text.trim()) ?? 1200;
      final rateSft = double.tryParse(_rateSftController.text.trim()) ?? 4500.0;
      final totalAmount = targetSft * rateSft;

      final flat = AssignedFlatModel(
        builderName: _builderController.text.trim(),
        projectName: _projectController.text.trim(),
        tower: _towerController.text.trim(),
        unitNumber: _unitController.text.trim(),
        configuration: _bhkController.text.trim(),
        targetSft: targetSft,
        rateSft: rateSft,
        totalTargetAmountInr: totalAmount,
        builderReraId: _reraIdController.text.trim(),
        escrowBank: EscrowBankModel(
          bankName: _bankNameController.text.trim(),
          accountHolder: 'PLOT THEIR FUTURE ESCROW - ${_currentSubmission.coupleTitle.toUpperCase()}',
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscController.text.trim(),
          upiVpa: _upiVpaController.text.trim(),
        ),
      );

      final approved = await ApiService.instance.adminApproveAndAssignFlat(
        registrationId: _currentSubmission.id,
        flat: flat,
        slug: _slugController.text.trim(),
        videoStreamUrl: _videoStreamController.text.trim(),
        flatId: _selectedFlat?.flatId ?? _selectedFlat?.id.toString(),
      );

      if (mounted) {
        setState(() => _isApproving = false);

        // Show approval celebration dialog while sheet is still active
        await _showApprovedCelebrationDialog(approved);

        if (mounted) {
          Navigator.pop(context);
          widget.onApproved();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApproving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e'), backgroundColor: AppTheme.crimsonMaroon),
        );
      }
    }
  }

  Future<void> _showApprovedCelebrationDialog(MarriageSubmission approved) async {
    final assignedFlat = approved.assignedFlat;
    final shareUrl = approved.shareableUrl ?? 'https://plottheirfuture.in/weddings/${approved.slug ?? ""}';

    await showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.royalGold.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Wedding Approved & Flat Assigned!',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.crimsonMaroon,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Congratulations to ${approved.coupleTitle}! The wedding campaign is now LIVE and guests can begin gifting square feet directly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Flat & Escrow Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.ivoryBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.goldBorder),
                ),
                child: Column(
                  children: [
                    // Flat Unit & Project
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded, color: AppTheme.royalGold, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignedFlat?.projectName ?? "Residential Property",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textDark),
                              ),
                              Text(
                                '${assignedFlat?.tower ?? ""}, ${assignedFlat?.unitNumber ?? ""} • ${assignedFlat?.configuration ?? "2 BHK"}',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFEADBBE)),

                    // Target SFT & Target Valuation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TARGET AREA', style: GoogleFonts.cinzel(fontSize: 10, letterSpacing: 1.0, color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              '${assignedFlat?.targetSft ?? 1200} SFT',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('TOTAL VALUATION', style: GoogleFonts.cinzel(fontSize: 10, letterSpacing: 1.0, color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              '₹${(((assignedFlat?.totalTargetAmountInr ?? 5400000)) / 100000).toStringAsFixed(1)} Lakhs',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFEADBBE)),

                    // Escrow Account & RERA
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Escrow: ${assignedFlat?.escrowBank.bankName ?? "HDFC Bank"} • ${assignedFlat?.escrowBank.accountNumber ?? ""}',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (assignedFlat?.builderReraId != null && assignedFlat!.builderReraId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppTheme.royalGold, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'RERA: ${assignedFlat.builderReraId}',
                              style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Public Microsite Link Box with Copy Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: AppTheme.royalGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Public Wedding Link', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
                          SelectableText(
                            shareUrl,
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.crimsonMaroon),
                      tooltip: 'Copy Link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareUrl));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Wedding Link copied!'),
                            duration: Duration(seconds: 2),
                            backgroundColor: AppTheme.crimsonMaroon,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Back to Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final wedding = WeddingRegistryRepository.findBySlugOrUrl(approved.slug ?? '') ??
                            WeddingRegistryRepository.allWeddings.first;
                        WeddingRegistryRepository.openWedding(context, wedding);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.crimsonMaroon,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('View Live Wedding ➔', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = _currentSubmission;
    final displayFunctions = sub.enabledFunctions.isNotEmpty ? sub.enabledFunctions : sub.functions;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dossier: ${sub.referenceNumber}',
                        style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${sub.bride.name} & ${sub.groom.name}',
                        style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CONTACT INFORMATION & VERIFICATION (Primary User Requirement)
                  _buildSectionHeader('1. CONTACT DOSSIER & VERIFICATION', Icons.contact_phone),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.ivoryBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2D6C0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bride: ${sub.bride.name}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Mobile: ${sub.bride.mobileNumber}', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.crimsonMaroon, fontWeight: FontWeight.w600)),
                                  if (sub.bride.email != null && sub.bride.email!.isNotEmpty) Text('Email: ${sub.bride.email}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                                  if (sub.bride.occupation != null && sub.bride.occupation!.isNotEmpty) Text('Role: ${sub.bride.occupation}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling Bride ${sub.bride.mobileNumber}...')),
                                );
                              },
                              icon: const Icon(Icons.call, size: 14, color: Colors.white),
                              label: Text('Call', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.greenVerified,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Groom: ${sub.groom.name}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Mobile: ${sub.groom.mobileNumber}', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.crimsonMaroon, fontWeight: FontWeight.w600)),
                                  if (sub.groom.email != null && sub.groom.email!.isNotEmpty) Text('Email: ${sub.groom.email}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                                  if (sub.groom.occupation != null && sub.groom.occupation!.isNotEmpty) Text('Role: ${sub.groom.occupation}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('WhatsApping Groom ${sub.groom.mobileNumber}...')),
                                );
                              },
                              icon: const Icon(Icons.chat, size: 14, color: Colors.white),
                              label: Text('WhatsApp', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Primary Verification Contact: ${sub.primaryContactNumber} • Secondary: ${sub.secondaryContactNumber}',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. WEDDING MEDIA & INVITATIONS SHOWCASE
                  _buildSectionHeader('2. WEDDING MEDIA & INVITATIONS', Icons.perm_media),
                  
                  // A. Couple Photo / Cover Portrait Preview
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.photo_library, size: 16, color: AppTheme.crimsonMaroon),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Couple Photo / Portrait Banner',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (sub.coverImageUrl != null && sub.coverImageUrl!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 150,
                                  child: _buildAppImage(sub.coverImageUrl, height: 150, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showMediaPreviewDialog(
                                      context,
                                      title: '${sub.bride.name} & ${sub.groom.name} - Portrait',
                                      path: sub.coverImageUrl!,
                                    ),
                                    icon: const Icon(Icons.fullscreen, size: 14, color: Colors.white),
                                    label: Text('Preview Full Photo', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black.withOpacity(0.75),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.ivoryBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'No couple cover portrait attached',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // B. Digital Wedding Card Preview
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 65,
                            height: 85,
                            color: AppTheme.ivoryBackground,
                            child: sub.weddingCardUrl.isNotEmpty
                                ? _buildAppImage(
                                    sub.weddingCardUrl,
                                    width: 65,
                                    height: 85,
                                    fit: BoxFit.cover,
                                    placeholder: const Icon(Icons.picture_as_pdf, color: AppTheme.crimsonMaroon, size: 34),
                                  )
                                : const Icon(Icons.picture_as_pdf, color: AppTheme.crimsonMaroon, size: 34),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Official Digital Wedding Invitation Card', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                sub.weddingCardUrl.isNotEmpty ? sub.weddingCardUrl : 'No invitation file attached',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 6),
                              if (sub.weddingCardUrl.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => _showMediaPreviewDialog(
                                    context,
                                    title: 'Official Wedding Invitation Card',
                                    path: sub.weddingCardUrl,
                                  ),
                                  icon: const Icon(Icons.open_in_new, size: 14, color: AppTheme.royalGold),
                                  label: Text('View Full Wedding Card', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.royalGold)),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // C. Wedding Invitation Video Reel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.crimsonMaroon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.video_library, color: AppTheme.crimsonMaroon, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wedding Reel Video / Live Stream',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                              ),
                              Text(
                                (sub.invitationVideoUrl != null && sub.invitationVideoUrl!.isNotEmpty)
                                    ? sub.invitationVideoUrl!
                                    : (sub.videoStreamUrl != null && sub.videoStreamUrl!.isNotEmpty)
                                        ? sub.videoStreamUrl!
                                        : 'No reel video uploaded (Optional)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if ((sub.invitationVideoUrl != null && sub.invitationVideoUrl!.isNotEmpty) ||
                            (sub.videoStreamUrl != null && sub.videoStreamUrl!.isNotEmpty))
                          ElevatedButton.icon(
                            onPressed: () => _showMediaPreviewDialog(
                              context,
                              title: 'Invitation Video Reel',
                              path: (sub.invitationVideoUrl != null && sub.invitationVideoUrl!.isNotEmpty)
                                  ? sub.invitationVideoUrl!
                                  : sub.videoStreamUrl!,
                              isVideo: true,
                            ),
                            icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                            label: Text('Play Reel', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.crimsonMaroon,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. ENABLED FUNCTIONS / CEREMONIES
                  _buildSectionHeader('3. CEREMONY ITINERARY (${displayFunctions.length} Enabled)', Icons.celebration),
                  if (displayFunctions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          'No ceremony itinerary configured for this wedding.',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  else
                    ...displayFunctions.map((fn) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppTheme.lightGold.withOpacity(0.5), shape: BoxShape.circle),
                                child: const Icon(Icons.event, size: 16, color: AppTheme.crimsonMaroon),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            fn.name,
                                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('dd MMM yyyy').format(fn.eventDate), style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.royalGold)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Time: ${fn.startTime} - ${fn.endTime}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                                    Text('Venue: ${fn.venueName} • ${fn.venueAddress}', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF475569))),
                                    if (fn.dressCode != null && fn.dressCode!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text('Dress Code: ${fn.dressCode}', style: GoogleFonts.outfit(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppTheme.crimsonMaroon)),
                                      ),
                                    // OpenStreetMap Pin & In-App Navigation Actions
                                    Builder(
                                      builder: (ctx) {
                                        double lat = 17.3850;
                                        double lng = 78.4867;
                                        if (fn.venueMapUrl != null && fn.venueMapUrl!.contains('mlat=')) {
                                          final uri = Uri.tryParse(fn.venueMapUrl!);
                                          if (uri != null) {
                                            lat = double.tryParse(uri.queryParameters['mlat'] ?? '') ?? 17.3850;
                                            lng = double.tryParse(uri.queryParameters['mlon'] ?? '') ?? 78.4867;
                                          }
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  OSMMapPickerModal.show(
                                                    context,
                                                    initialLat: lat,
                                                    initialLng: lng,
                                                    initialAddress: '${fn.venueName}, ${fn.venueAddress}',
                                                    title: '${fn.name} - OpenStreetMap',
                                                  );
                                                },
                                                icon: const Icon(Icons.map_outlined, size: 13, color: AppTheme.crimsonMaroon),
                                                label: Text(
                                                  'View Map',
                                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFFEADBBE)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  OSMNavigationModal.show(
                                                    context,
                                                    venueLat: lat,
                                                    venueLng: lng,
                                                    venueName: fn.venueName.isNotEmpty ? fn.venueName : fn.name,
                                                    venueAddress: fn.venueAddress,
                                                  );
                                                },
                                                icon: const Icon(Icons.navigation_outlined, size: 13, color: Colors.white),
                                                label: Text(
                                                  'Navigate (OSM)',
                                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.crimsonMaroon,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 20),

                  // 4. REAL ESTATE FLAT ALLOCATION (WITH INVENTORY DROPDOWN)
                  _buildSectionHeader('4. REAL ESTATE FLAT ALLOCATION', Icons.home_work),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.royalGold.withOpacity(0.6), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select an approved flat from Flat Management inventory below to link to this wedding campaign. When guests gift square feet, their contributions land in the designated escrow account.',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 14),

                        // Dropdown Selector of Approved Unassigned Flats from Flat Management
                        if (_isLoadingFlats)
                          const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                        else if (_approvedFlats.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No approved unassigned flats found in inventory. You can approve flats in Flat Management or enter details manually below.',
                                    style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF92400E)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Choose Approved Flat from Flat Management *'),
                              DropdownButtonFormField<FlatModel>(
                                value: _selectedFlat != null && _approvedFlats.any((f) => f.id == _selectedFlat!.id)
                                    ? _approvedFlats.firstWhere((f) => f.id == _selectedFlat!.id)
                                    : null,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.apartment, color: AppTheme.crimsonMaroon),
                                  filled: true,
                                  fillColor: const Color(0xFFFFFBF2),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                                ),
                                hint: Text('Select an approved flat...', style: GoogleFonts.outfit(fontSize: 12.5, color: AppTheme.textMuted)),
                                items: _approvedFlats.map((flat) {
                                  return DropdownMenuItem<FlatModel>(
                                    value: flat,
                                    child: Text(
                                      '${flat.name} • ${flat.bedrooms} BHK (${flat.builtUpAreaSft} SFT @ ₹${flat.pricePerSft.toInt()}/SFT)',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.textDark),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (FlatModel? flat) {
                                  if (flat != null) {
                                    _onFlatSelected(flat);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),

                        // Selected Flat Verification Card
                        if (_selectedFlat != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.greenVerified.withOpacity(0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildAppImage(
                                        _selectedFlat!.coverImageUrl,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _selectedFlat!.name,
                                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.greenVerified.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.check_circle, size: 10, color: AppTheme.greenVerified),
                                                    const SizedBox(width: 3),
                                                    Text('Approved', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.greenVerified)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text('ID: ${_selectedFlat!.flatId} • ${_selectedFlat!.location}', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_selectedFlat!.builtUpAreaSft} SFT Built-up • ${_selectedFlat!.builtUpAreaSft * _selectedFlat!.bricksPerSft} Bricks (${_selectedFlat!.bricksPerSft} Bricks/SFT)',
                                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.crimsonMaroon),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified, size: 12, color: AppTheme.greenVerified),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Section Area Check: Verified (${_selectedFlat!.totalSectionArea} SFT in ${_selectedFlat!.sections.length} sections)',
                                          style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Slug input
                        _buildFormLabel('Campaign Slug (Public URL) *'),
                        TextFormField(
                          controller: _slugController,
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            prefixText: 'weddings/',
                            prefixStyle: GoogleFonts.outfit(color: AppTheme.royalGold, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: AppTheme.ivoryBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Builder & Project
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFormLabel('Builder / Developer *'),
                                  TextFormField(
                                    controller: _builderController,
                                    style: GoogleFonts.outfit(fontSize: 12),
                                    decoration: InputDecoration(filled: true, fillColor: AppTheme.ivoryBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFormLabel('Project & Tower *'),
                                  TextFormField(
                                    controller: _projectController,
                                    style: GoogleFonts.outfit(fontSize: 12),
                                    decoration: InputDecoration(filled: true, fillColor: AppTheme.ivoryBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Flat Unit & BHK
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFormLabel('Flat Unit Number *'),
                                  TextFormField(
                                    controller: _unitController,
                                    style: GoogleFonts.outfit(fontSize: 12),
                                    decoration: InputDecoration(filled: true, fillColor: AppTheme.ivoryBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFormLabel('Configuration (BHK) *'),
                                  TextFormField(
                                    controller: _bhkController,
                                    style: GoogleFonts.outfit(fontSize: 12),
                                    decoration: InputDecoration(filled: true, fillColor: AppTheme.ivoryBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // SFT & Rate
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFormLabel('Target Area (SFT) *'),
                                  TextFormField(
                                    controller: _targetSftController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.outfit(fontSize: 12),
                                    decoration: InputDecoration(filled: true, fillColor: AppTheme.ivoryBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFormLabel('Rate / SFT (₹) *'),
                                  TextFormField(
                                    controller: _rateSftController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.outfit(fontSize: 12),
                                    decoration: InputDecoration(filled: true, fillColor: AppTheme.ivoryBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // RERA ID & Escrow Acc
                        _buildFormLabel('Builder RERA Registration ID *'),
                        TextFormField(
                          controller: _reraIdController,
                          style: GoogleFonts.outfit(fontSize: 12),
                          decoration: InputDecoration(filled: true, fillColor: AppTheme.ivoryBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                        const SizedBox(height: 12),

                        _buildFormLabel('Escrow Bank Account Number *'),
                        TextFormField(
                          controller: _accountNumberController,
                          style: GoogleFonts.outfit(fontSize: 12),
                          decoration: InputDecoration(filled: true, fillColor: AppTheme.ivoryBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACTION BUTTONS
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isApproving ? null : _handleApproveAndAssignFlat,
                      icon: _isApproving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.verified, color: Colors.white),
                      label: Text(
                        _isApproving ? 'Approving & Initializing Matrix...' : 'APPROVE & ATTACH FLAT UNIT ➔',
                        style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenVerified,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (sub.isApproved && sub.slug != null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          final wedding = WeddingRegistryRepository.findBySlugOrUrl(sub.slug ?? '') ??
                              WeddingRegistryRepository.allWeddings.first;
                          WeddingRegistryRepository.openWedding(context, wedding);
                        },
                        icon: const Icon(Icons.open_in_browser, color: AppTheme.crimsonMaroon),
                        label: Text(
                          'Test Open Public Wedding Microsite ➔',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.crimsonMaroon, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.crimsonMaroon),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cinzel(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
      ),
    );
  }
}
