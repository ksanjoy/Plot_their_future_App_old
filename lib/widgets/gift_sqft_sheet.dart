import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/flat_model.dart';
import '../models/room_model.dart';
import '../services/api_service.dart';
import '../services/local_marriage_storage_service.dart';
import '../state/flat_registry_provider.dart';
import 'deed_certificate_modal.dart';

class GiftSqFtSheet extends ConsumerStatefulWidget {
  final RoomModel? initialRoom;
  final FlatSectionModel? initialSection;
  final String? weddingSlug;
  final int initialSqFt;
  final int bricksPerSqFt;
  final VoidCallback? onGiftCompleted;

  const GiftSqFtSheet({
    super.key,
    this.initialRoom,
    this.initialSection,
    this.weddingSlug,
    this.initialSqFt = 5,
    this.bricksPerSqFt = 10,
    this.onGiftCompleted,
  });

  @override
  ConsumerState<GiftSqFtSheet> createState() => _GiftSqFtSheetState();
}

class _GiftSqFtSheetState extends ConsumerState<GiftSqFtSheet> {
  late int _selectedSqFt;
  late String _selectedRoomId;
  FlatSectionModel? _selectedSection;
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _blessingController = TextEditingController();
  String _selectedPaymentMethod = 'UPI';
  bool _isSubmitting = false;

  final List<int> _presetOptions = [1, 5, 10, 25, 50];
  final List<String> _relationshipSuggestions = [
    'College Bestie',
    'Bride\'s Family',
    'Groom\'s Family',
    'Colleague',
    'Childhood Friend',
  ];

  final List<String> _blessingSuggestions = [
    'May your home be overflowing with love, peace, and endless chai!',
    'Here is to late-night laughter, cozy movie nights, and warm memories.',
    'Wishing you both lifetime harmony in your beautiful forever home.',
  ];

  int get _effectiveBricksPerSqFt => widget.bricksPerSqFt > 0 ? widget.bricksPerSqFt : 10;
  int get _totalBricksEquivalent => _selectedSqFt * _effectiveBricksPerSqFt;

  @override
  void initState() {
    super.initState();
    _selectedSqFt = widget.initialSqFt;
    _selectedRoomId = widget.initialRoom?.id ?? 'living_room';
    _selectedSection = widget.initialSection;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _relationshipController.dispose();
    _blessingController.dispose();
    super.dispose();
  }

  void _handleCompleteGift() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name so the couple knows who to thank!'),
          backgroundColor: AppTheme.crimsonMaroon,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final guestMobile = _mobileController.text.trim().isEmpty ? '9848012345' : _mobileController.text.trim();
    final guestEmail = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    final blessing = _blessingController.text.trim().isEmpty
        ? 'Wishing you both boundless happiness and a lifetime of love!'
        : _blessingController.text.trim();

    String slug = widget.weddingSlug ?? 'surya-jyothika';
    int weddingId = 5;
    try {
      final list = await LocalMarriageStorageService.instance.getAllRegistrations();
      final approved = list.where((s) => s.isApproved).firstOrNull;
      if (approved != null) {
        if (approved.slug != null && approved.slug!.isNotEmpty) {
          slug = approved.slug!;
        }
        weddingId = approved.weddingId ?? int.tryParse(approved.id) ?? 5;
      }
    } catch (_) {}

    // 1. Call Section Gifting API if wedding slug / section is present
    try {
      final secId = _selectedSection?.id ?? 1;
      await ApiService.instance.giftWeddingSection(
        slug: slug,
        sectionId: secId,
        unitsSft: _selectedSqFt,
        guestName: _nameController.text.trim(),
        guestMobile: guestMobile,
        guestEmail: guestEmail,
        blessingMessage: blessing,
      );
    } catch (e) {
      debugPrint('[GiftSqFtSheet] Section gifting backend synced/notice: $e');
    }

    // 2. Call Registry provider to create Contribution, confirm payment, update FloorPlanZone in MySQL
    final registry = ref.read(flatRegistryProvider);
    final contribution = await registry.giftSqFtViaApi(
      donorName: _nameController.text.trim(),
      relationship: _relationshipController.text.trim().isEmpty ? 'Loving Guest' : _relationshipController.text.trim(),
      sqFt: _selectedSqFt,
      roomId: _selectedRoomId,
      blessingMessage: blessing,
      guestMobile: guestMobile,
      guestEmail: guestEmail,
      paymentMethod: _selectedPaymentMethod,
      weddingId: weddingId,
    );

    widget.onGiftCompleted?.call();

    if (!mounted) return;

    Navigator.of(context).pop(); // Close sheet

    // Show celebratory Deed Certificate Modal
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DeedCertificateModal(contribution: contribution),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFAF8F5),
      hintText: hintText,
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: AppTheme.crimsonMaroon, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEADBBE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEADBBE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.crimsonMaroon, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(flatRegistryProvider);
    final double currentCost = (_selectedSqFt * registry.pricePerSqFt).toDouble();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFFEADBBE), width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GIFT SQUARE FOOTAGE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.crimsonMaroon,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Lay a foundation stone in their forever home',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.crimsonMaroon),
                ),
              ],
            ),
            const Divider(color: Color(0xFFEADBBE), height: 24),

            // 10-Minute Temporary Cart Lock Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEADBBE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, size: 16, color: AppTheme.crimsonMaroon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '10-Min Temporary Cart Lock Active • Prevents Tile Collision',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.crimsonMaroon,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // STEP 1: Select SqFt
            Text(
              '1. SELECT SQUARE FEET TO GIFT',
              style: GoogleFonts.cinzel(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.crimsonMaroon,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            // Preset options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _presetOptions.map((sqFt) {
                final isSelected = _selectedSqFt == sqFt;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSqFt = sqFt),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.crimsonMaroon : const Color(0xFFFAF6EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.crimsonMaroon : const Color(0xFFEADBBE),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$sqFt',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.crimsonMaroon,
                              ),
                            ),
                            Text(
                              'sq.ft.',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white70 : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Stepper / Counter Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEADBBE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Custom Sq.Ft.:',
                      style: GoogleFonts.outfit(color: const Color(0xFF1E232A), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: _selectedSqFt > 1
                            ? () => setState(() => _selectedSqFt--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.crimsonMaroon, size: 22),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_selectedSqFt sq.ft.',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.crimsonMaroon,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: _selectedSqFt < registry.remainingSqFt
                            ? () => setState(() => _selectedSqFt++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.crimsonMaroon, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Brick Equivalent Indicator Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEADBBE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.view_in_ar, size: 16, color: AppTheme.royalGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_selectedSqFt Sq. Ft. = $_totalBricksEquivalent Bricks Equivalent',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.crimsonMaroon,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.royalGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '1 SFT = $_effectiveBricksPerSqFt Bricks',
                      style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.crimsonMaroon, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // STEP 2: Select Room
            Text(
              '2. DEDICATE TO ROOM',
              style: GoogleFonts.cinzel(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.crimsonMaroon,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final seenRoomIds = <String>{};
                final uniqueRooms = registry.rooms
                    .where((r) => r.id.isNotEmpty && seenRoomIds.add(r.id))
                    .toList();

                final effectiveRoomId = uniqueRooms.any((r) => r.id == _selectedRoomId)
                    ? _selectedRoomId
                    : (uniqueRooms.isNotEmpty ? uniqueRooms.first.id : null);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEADBBE)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      value: effectiveRoomId,
                      items: uniqueRooms.map((room) {
                        return DropdownMenuItem<String>(
                          value: room.id,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Color(room.colorValue),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${room.name} (${room.remainingSqFt} sq.ft. left)',
                                  style: GoogleFonts.outfit(color: const Color(0xFF1E232A), fontSize: 13.5, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRoomId = val);
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // STEP 3: Guest Info
            Text(
              '3. YOUR DETAILS',
              style: GoogleFonts.cinzel(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.crimsonMaroon,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: GoogleFonts.outfit(color: const Color(0xFF1E232A), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: _buildInputDecoration(
                hintText: 'Your Full Name (e.g., Rohan & Neha) *',
                prefixIcon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.outfit(color: const Color(0xFF1E232A), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: _buildInputDecoration(
                hintText: 'Mobile Number (e.g., 98480 12345) *',
                prefixIcon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.outfit(color: const Color(0xFF1E232A), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: _buildInputDecoration(
                hintText: 'Email Address (for Gift Deed Receipt)',
                prefixIcon: Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _relationshipController,
              style: GoogleFonts.outfit(color: const Color(0xFF1E232A), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: _buildInputDecoration(
                hintText: 'Relationship (e.g., College Bestie, Cousin)',
                prefixIcon: Icons.people_outline,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _relationshipSuggestions.map((rel) {
                return InkWell(
                  onTap: () => setState(() => _relationshipController.text = rel),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEADBBE)),
                    ),
                    child: Text(
                      rel,
                      style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.crimsonMaroon, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // STEP 4: Blessing Note
            Text(
              '4. HEARTFELT BLESSING & WISH',
              style: GoogleFonts.cinzel(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.crimsonMaroon,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _blessingController,
              maxLines: 2,
              style: GoogleFonts.outfit(color: const Color(0xFF1E232A), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFAF8F5),
                hintText: 'Write a warm blessing to be forever pinned to their home deed...',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.favorite_border, color: AppTheme.crimsonMaroon, size: 20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEADBBE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEADBBE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.crimsonMaroon, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _blessingSuggestions.map((bless) {
                return InkWell(
                  onTap: () => setState(() => _blessingController.text = bless),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEADBBE)),
                    ),
                    child: Text(
                      bless.length > 34 ? '${bless.substring(0, 34)}...' : bless,
                      style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.crimsonMaroon, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // STEP 5: Payment Method
            Text(
              '5. PAYMENT METHOD',
              style: GoogleFonts.cinzel(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.crimsonMaroon,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['UPI', 'Credit / Debit Card', 'Net Banking'].map((method) {
                final isSelected = _selectedPaymentMethod == method;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPaymentMethod = method),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.crimsonMaroon.withOpacity(0.08) : const Color(0xFFFAF8F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppTheme.crimsonMaroon : const Color(0xFFEADBBE),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          method,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppTheme.crimsonMaroon : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Total and Checkout Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEADBBE), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL FOUNDATION GIFT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cinzel(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Formatters.formatCurrency(currentCost, inINR: registry.useINR),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.crimsonMaroon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleCompleteGift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimsonMaroon,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Gift & Mint Deed',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
}
