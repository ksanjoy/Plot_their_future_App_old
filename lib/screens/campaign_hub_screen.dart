import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/marriage_submission_model.dart';
import '../services/api_service.dart';
import '../services/local_marriage_storage_service.dart';
import '../state/flat_registry_provider.dart';
import '../widgets/gift_sqft_sheet.dart';
import '../widgets/wedding_video_player_dialog.dart';
import 'admin_dashboard_screen.dart';
import 'marriage_registration_screen.dart';

class CampaignHubScreen extends ConsumerStatefulWidget {
  final VoidCallback onGiftSqFtTapped;
  final VoidCallback onViewFloorPlanTapped;
  final VoidCallback onViewGuestbookTapped;
  final VoidCallback onViewWhyGiftTapped;

  const CampaignHubScreen({
    super.key,
    required this.onGiftSqFtTapped,
    required this.onViewFloorPlanTapped,
    required this.onViewGuestbookTapped,
    required this.onViewWhyGiftTapped,
  });

  @override
  ConsumerState<CampaignHubScreen> createState() => _CampaignHubScreenState();
}

class _CampaignHubScreenState extends ConsumerState<CampaignHubScreen> {
  List<MarriageSubmission> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final userId = ApiService.instance.currentSession?.user.id ?? 1;
      List<MarriageSubmission> list = [];
      try {
        list = await ApiService.instance.getMyMarriageRegistrations(userId);
      } catch (_) {}

      if (list.isEmpty) {
        list = await LocalMarriageStorageService.instance.getAllRegistrations();
      }

      if (mounted) {
        setState(() {
          _submissions = list;
          _isLoading = false;
        });

        final approved = list.where((s) => s.isApproved).firstOrNull;
        if (approved != null) {
          final wId = approved.weddingId ?? int.tryParse(approved.id) ?? 5;
          ref.read(flatRegistryProvider.notifier).fetchRegistryFromApi(weddingId: wId);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  static Widget _buildAppImage(
    String? path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (path == null || path.isEmpty) {
      return Image.asset(AppConstants.coupleImagePath, width: width, height: height, fit: fit);
    }
    if (path.startsWith('/') || path.startsWith('file://')) {
      final cleanPath = path.replaceFirst('file://', '');
      return Image.file(
        File(cleanPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(AppConstants.coupleImagePath, width: width, height: height, fit: fit),
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(AppConstants.coupleImagePath, width: width, height: height, fit: fit),
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(AppConstants.coupleImagePath, width: width, height: height, fit: fit),
      );
    }
  }

  void _showVideoDialog(BuildContext context, {String? videoUrl, String? title, String? coverImageUrl}) {
    WeddingVideoPlayerDialog.show(
      context,
      videoUrl: videoUrl,
      title: title ?? 'Wedding Invitation & Video Reel',
      coverImageUrl: coverImageUrl,
    );
  }

  void _showItineraryModal(BuildContext context, {MarriageSubmission? submission}) {
    final functions = submission?.functions.where((f) => f.isEnabled).toList() ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.ivoryBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'WEDDING ITINERARY & VENUES',
              style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
            ),
            const SizedBox(height: 4),
            Text(
              submission != null
                  ? '${submission.coupleTitle} • ${submission.city}'
                  : 'Sanvi Rao & Santosh Kumar • Bengaluru',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
            ),
            const Divider(height: 24),
            if (functions.isNotEmpty)
              ...functions.map((fn) => _buildItineraryRow(
                    fn.name,
                    '${DateFormat('MMM dd').format(fn.eventDate)} • ${fn.startTime}',
                    '${fn.venueName} • ${fn.dressCode ?? ""}',
                  ))
            else ...[
              _buildItineraryRow('Pellikuthuru & Haldi', 'Nov 14 • 9:00 AM', 'Rao Residence • Traditional Yellow'),
              _buildItineraryRow('Mehendi & Sangeet Soiree', 'Nov 14 • 6:30 PM', 'Grand Lotus Pavilion • DJ & Cocktails'),
              _buildItineraryRow('Sacred Wedding Muhurtham', 'Nov 15 • 5:45 AM', 'Main Mandapam, Grand Palace'),
              _buildItineraryRow('Grand Reception Gala', 'Nov 15 • 7:00 PM', 'Crystal Grand Ballroom • Royal Feast'),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.crimsonMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Close Itinerary', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildItineraryRow(String title, String time, String venue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.royalGold.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.event, color: AppTheme.royalGold, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                Text(time, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.crimsonMaroon)),
                Text(venue, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDetailsSheet(BuildContext context, MarriageSubmission submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REGISTRATION DETAILS', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
                        Text('Ref: ${submission.referenceNumber}', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Status banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pending_actions, color: Color(0xFFB45309), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${submission.status}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                              Text('Admin verification team is inspecting contacts & wedding card.', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF92400E))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Couple photo preview
                  if (submission.coverImageUrl != null && submission.coverImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildAppImage(submission.coverImageUrl, height: 180, width: double.infinity),
                    ),
                  const SizedBox(height: 16),

                  // Bride details
                  _buildDetailSection('Bride Details', [
                    'Name: ${submission.bride.name}',
                    'Mobile: ${submission.bride.mobileNumber}',
                    if (submission.bride.occupation != null && submission.bride.occupation!.isNotEmpty) 'Occupation: ${submission.bride.occupation!}',
                    if (submission.bride.email != null && submission.bride.email!.isNotEmpty) 'Email: ${submission.bride.email!}',
                  ]),

                  // Groom details
                  _buildDetailSection('Groom Details', [
                    'Name: ${submission.groom.name}',
                    'Mobile: ${submission.groom.mobileNumber}',
                    if (submission.groom.occupation != null && submission.groom.occupation!.isNotEmpty) 'Occupation: ${submission.groom.occupation!}',
                    if (submission.groom.email != null && submission.groom.email!.isNotEmpty) 'Email: ${submission.groom.email!}',
                  ]),

                  // Wedding details
                  _buildDetailSection('Event Information', [
                    'Date: ${DateFormat('dd MMMM yyyy').format(submission.weddingDate)}',
                    'City: ${submission.city}',
                    'Target Flat: ${submission.targetBhk}',
                    if (submission.preferredArea.isNotEmpty) 'Preferred Area: ${submission.preferredArea}',
                  ]),

                  // Ceremonies
                  _buildDetailSection(
                    'Ceremonies (${submission.functions.where((f) => f.isEnabled).length} active)',
                    submission.functions.where((f) => f.isEnabled).map((f) => '• ${f.name} (${f.startTime}) - ${f.venueName}').toList(),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                    },
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
                    label: Text('Open Admin Dashboard to Approve', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimsonMaroon,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> lines) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBBE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.cinzel(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textDark)),
              )),
        ],
      ),
    );
  }

  // --- CARD 1: PENDING APPROVAL CARD ---
  Widget _buildPendingApprovalCard(BuildContext context, MarriageSubmission pending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'REGISTRY PENDING ADMIN APPROVAL',
                    style: GoogleFonts.cinzel(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD97706), width: 0.8),
                  ),
                  child: Text(
                    pending.referenceNumber,
                    style: GoogleFonts.cinzel(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Couple Snapshot Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Couple / Cover Thumbnail
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: _buildAppImage(
                          (pending.coverImageUrl != null && pending.coverImageUrl!.isNotEmpty)
                              ? pending.coverImageUrl
                              : pending.weddingCardUrl,
                          width: 72,
                          height: 72,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pending.coupleTitle,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.crimsonMaroon,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Wedding: ${DateFormat('dd MMMM yyyy').format(pending.weddingDate)} • ${pending.city}',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Target: ${pending.targetBhk} (${pending.preferredArea.isNotEmpty ? pending.preferredArea : pending.city})',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3-Step Verification Timeline
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildStepItem('1. Submitted', isDone: true, isActive: false)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
                      const SizedBox(width: 4),
                      Expanded(child: _buildStepItem('2. Verification', isDone: false, isActive: true)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
                      const SizedBox(width: 4),
                      Expanded(child: _buildStepItem('3. Flat Live', isDone: false, isActive: false)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Verification note
                Text(
                  'Our admin concierges are verifying your wedding card and contacts. Once approved, your dream home flat will be linked and guests can start gifting square feet!',
                  style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.35),
                ),
                const SizedBox(height: 14),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showSubmissionDetailsSheet(context, pending),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD97706)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen())).then((_) => _loadSubmissions());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB45309),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                        child: Text(
                          'Approve in Admin ➔',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
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

  Widget _buildStepItem(String title, {required bool isDone, required bool isActive}) {
    Color bg = const Color(0xFFE2E8F0);
    Color fg = const Color(0xFF64748B);
    Widget icon = const SizedBox.shrink();

    if (isDone) {
      bg = const Color(0xFF10B981);
      fg = Colors.white;
      icon = const Icon(Icons.check, size: 10, color: Colors.white);
    } else if (isActive) {
      bg = const Color(0xFFF59E0B);
      fg = Colors.white;
      icon = const Icon(Icons.refresh, size: 10, color: Colors.white);
    }

    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: icon,
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 9.5,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFFB45309) : (isDone ? const Color(0xFF047857) : fg),
          ),
        ),
      ],
    );
  }

  // --- CARD 2: APPROVED REGISTRY HERO CARD ---
  Widget _buildApprovedRegistryHero(BuildContext context, MarriageSubmission approved) {
    final flat = approved.assignedFlat;
    final totalArea = flat?.targetSft ?? 1200;
    final flatRate = flat?.rateSft.toInt() ?? 4500;
    final unitInfo = flat != null ? '${flat.projectName} • ${flat.unitNumber}' : 'Lotus Heights 2 BHK • Unit 402';
    final locationInfo = flat?.tower ?? approved.city;

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2D1A3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cover Photo & Video Play Banner
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: _buildAppImage(
                  (approved.coverImageUrl != null && approved.coverImageUrl!.isNotEmpty)
                      ? approved.coverImageUrl
                      : AppConstants.coupleImagePath,
                  height: 220,
                  width: double.infinity,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // Status Chip Top Left
              Positioned(
                top: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'VERIFIED REGISTRY • LIVE',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),

              // Reference Chip Top Right
              Positioned(
                top: 12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    approved.referenceNumber,
                    style: GoogleFonts.cinzel(color: const Color(0xFFF3E5AB), fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Play Video Button
              InkWell(
                onTap: () {
                  final vUrl = (approved.videoStreamUrl != null && approved.videoStreamUrl!.isNotEmpty)
                      ? approved.videoStreamUrl
                      : approved.invitationVideoUrl;
                  _showVideoDialog(
                    context,
                    videoUrl: vUrl,
                    title: '${approved.coupleTitle} Wedding Reel',
                    coverImageUrl: approved.coverImageUrl,
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.92),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 14),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: AppTheme.crimsonMaroon, size: 36),
                ),
              ),

              // Bottom Title Overlay on Cover
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approved.coupleTitle,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [const Shadow(color: Colors.black, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Wedding: ${DateFormat('dd MMMM yyyy').format(approved.weddingDate)} • ${approved.city}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFF3E5AB),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. Assigned Flat Details & Real-Time Gifting Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assigned Flat Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.crimsonMaroon.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.apartment, color: AppTheme.crimsonMaroon, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unitInfo,
                            style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            locationInfo,
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Area & Pricing Chips
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEADBBE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('TOTAL FLAT AREA', style: GoogleFonts.cinzel(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('$totalArea Sq. Ft.', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEADBBE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('RATE PER SFT', style: GoogleFonts.cinzel(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('₹$flatRate / SFT', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEADBBE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('BRICK CONVERSION', style: GoogleFonts.cinzel(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('1 SFT = 10 Bricks', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Live Progress Indicator
                Consumer(
                  builder: (context, ref, _) {
                    final reg = ref.watch(flatRegistryProvider);
                    final gifted = reg.totalGiftedSqFt;
                    final progress = totalArea > 0 ? (gifted / totalArea).clamp(0.0, 1.0) : 0.0;
                    final remaining = (totalArea - gifted).clamp(0, totalArea);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.royalGold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '$gifted / $totalArea SFT Funded (${(progress * 100).toStringAsFixed(0)}%)',
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$remaining SFT Available',
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Buttons: Gift Now & Itinerary
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => GiftSqFtSheet(
                              weddingSlug: approved.slug,
                              bricksPerSqFt: 10,
                              onGiftCompleted: () {
                                final wId = approved.weddingId ?? int.tryParse(approved.id) ?? 5;
                                ref.read(flatRegistryProvider.notifier).fetchRegistryFromApi(weddingId: wId);
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.crimsonMaroon,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 3,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'GIFT SQUARE FEET NOW ➔',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () => _showItineraryModal(context, submission: approved),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.crimsonMaroon),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Ceremonies 📅',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Share Registry Bar
                InkWell(
                  onTap: () {
                    final shareText = 'Gift a square foot in ${approved.coupleTitle}\'s dream home! Visit: https://plottheirfuture.com/w/${approved.referenceNumber.replaceAll("#", "")}';
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Registry link copied to clipboard!', style: GoogleFonts.outfit()),
                        backgroundColor: AppTheme.crimsonMaroon,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6EE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEADBBE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share, size: 14, color: AppTheme.royalGold),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Share Registry Link with Friends & Family',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.crimsonMaroon),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CARD 3: REGISTER NEW WEDDING PROMPT BANNER ---
  Widget _buildRegisterNewWeddingBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBBE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.crimsonMaroon.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite, color: AppTheme.crimsonMaroon, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are You Getting Married?',
                  style: GoogleFonts.playfairDisplay(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                ),
                Text(
                  'Register your wedding to get an approved flat and accept square-foot gifts from guests.',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MarriageRegistrationScreen()),
              ).then((_) => _loadSubmissions());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimsonMaroon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: Text(
              'Register',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(flatRegistryProvider);

    // Filter pending and approved submissions
    final pendingSubmissions = _submissions.where((s) => s.status == 'PENDING_ADMIN_APPROVAL' || s.status == 'PENDING').toList();
    final approvedSubmissions = _submissions.where((s) => s.isApproved).toList();

    return RefreshIndicator(
      onRefresh: _loadSubmissions,
      color: AppTheme.crimsonMaroon,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Monogram & Title
            Center(
              child: Column(
                children: [
                  Text(
                    'Plot Their Future',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.royalGold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Wedding Gift Registry',
                    style: GoogleFonts.cinzel(
                      fontSize: 11,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E2640),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // DYNAMIC STATUS SECTIONS:
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: AppTheme.crimsonMaroon)),
              )
            else ...[
              // 1. IF PENDING APPROVALS EXIST -> SHOW PENDING APPROVAL CARDS
              if (pendingSubmissions.isNotEmpty)
                ...pendingSubmissions.map((p) => _buildPendingApprovalCard(context, p)),

              // 2. IF APPROVED / ACCEPTED REGISTRIES EXIST -> SHOW APPROVED REGISTRY HERO
              if (approvedSubmissions.isNotEmpty)
                ...approvedSubmissions.map((a) => _buildApprovedRegistryHero(context, a))
              else
                // Register Prompt if no approved registry
                _buildRegisterNewWeddingBanner(context),
            ],

            // SECTION: INVITATION CARD & VIDEO (Default / Fallback if no approved hero above)
            if (approvedSubmissions.isEmpty) ...[
              Text(
                'Invitation Card & Video',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E232A),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEBDAB0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.asset(
                            AppConstants.coupleImagePath,
                            height: 190,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Wedding Invitation • ${AppConstants.brideName.split(" ").first} & ${AppConstants.groomName.split(" ").first}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _showVideoDialog(context),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: AppTheme.crimsonMaroon,
                              size: 32,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          child: Text(
                            'Play Wedding Video Invite 🎥',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(color: Colors.black, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        children: [
                          Text(
                            'Muhurtham: Nov 15 • 5:45 AM',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E232A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Grand Reception: Nov 15 • 7:00 PM',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E232A),
                            ),
                          ),
                          const Divider(height: 20, color: Color(0xFFF1E6D0)),
                          InkWell(
                            onTap: () => _showItineraryModal(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    'View Full Itinerary & Venues',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.crimsonMaroon,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('📍'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // SECTION 2: GIFT A SQUARE FOOT (2 BHK Flat Campaign - only shown if no approved registry hero above)
            if (approvedSubmissions.isEmpty) ...[
              Text(
                'GIFT A SQUARE FOOT (2 BHK Flat Campaign)',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEBDAB0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Gift Square Feet in Their 2 BHK\nDream Home! 🏡',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E232A),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: registry.overallProgress,
                        minHeight: 9,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.royalGold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${registry.totalGiftedSqFt} / ${registry.totalSqFt} SFT Funded (${(registry.overallProgress * 100).toStringAsFixed(0)}%)',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.crimsonMaroon,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Isometric 2 BHK Blueprint Image Box
                    InkWell(
                      onTap: widget.onViewFloorPlanTapped,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF6EE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.goldBorder.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                AppConstants.apartmentPosterPath,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.grid_on, color: AppTheme.royalGold, size: 14),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '2 BHK Flat Blueprint & Grid Map',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Chips & CTA
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            '1 • 5 • 10 SFT',
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onGiftSqFtTapped,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.crimsonMaroon,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              elevation: 3,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'GIFT SQUARE FEET NOW →',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // SECTION 3: Guest Features / Fun Stuff
            Text(
              'Guest Features / Fun Stuff',
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E232A),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEBDAB0)),
              ),
              child: Column(
                children: [
                  _buildGuestFeatureTile(
                    icon: Icons.edit_note,
                    title: 'Leave a Blessing / Digital Guestbook',
                    onTap: widget.onViewGuestbookTapped,
                  ),
                  const Divider(height: 1, color: Color(0xFFF1E6D0)),
                  _buildGuestFeatureTile(
                    icon: Icons.photo_camera_outlined,
                    title: 'Upload Photos to the Wedding Wall',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Photo uploaded to wedding reception live screen!', style: GoogleFonts.outfit()),
                          backgroundColor: AppTheme.crimsonMaroon,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1E6D0)),
                  _buildGuestFeatureTile(
                    icon: Icons.help_outline,
                    title: 'Why Gift a Square Foot? (Calculator & FAQ)',
                    onTap: widget.onViewWhyGiftTapped,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestFeatureTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.crimsonMaroon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
