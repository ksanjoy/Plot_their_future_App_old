import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/api_user_model.dart';
import '../models/marriage_submission_model.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'marriage_registration_screen.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ApiUser? get _currentUser => ApiService.instance.currentSession?.user;

  @override
  void initState() {
    super.initState();
    _fetchRealUserProfile();
  }

  Future<void> _fetchRealUserProfile() async {
    if (ApiService.instance.isAuthenticated) {
      final user = await ApiService.instance.getMe();
      if (mounted && user != null) {
        setState(() {});
      }
    }
  }

  void _handleSignOut() {
    ApiService.instance.clearSession();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed out successfully'),
        backgroundColor: AppTheme.crimsonMaroon,
        duration: Duration(seconds: 2),
      ),
    );
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final isAuthenticated = ApiService.instance.isAuthenticated && user != null;

    if (!isAuthenticated) {
      return _buildGuestProfileView();
    }

    final displayName = user.name.trim().isNotEmpty ? user.name : 'Honored Guest';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final phone = user.mobileNumber.isNotEmpty ? user.mobileNumber : '+91 98480 12345';
    final occupation = (user.occupation != null && user.occupation!.isNotEmpty)
        ? user.occupation!
        : 'Wedding Guest';

    return Scaffold(
      backgroundColor: AppTheme.ivoryBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F0),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.crimsonMaroon, size: 18),
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
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.crimsonMaroon, size: 20),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HERO PROFILE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFEBDAB0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar Circle with Initials
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF701322), Color(0xFF8B1E2D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.royalGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.crimsonMaroon.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.greenVerified.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.greenVerified,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            phone,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.crimsonMaroon,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            occupation,
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick Edit Profile button on hero card
                    InkWell(
                      key: const Key('hero_edit_profile_button'),
                      onTap: () => _showEditProfileBottomSheet(user),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.crimsonMaroon.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.crimsonMaroon.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined, size: 14, color: AppTheme.crimsonMaroon),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.crimsonMaroon,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 1: ACCOUNT DETAILS DOSSIER WITH EDIT BUTTON
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildProfileSectionHeader('ACCOUNT DOSSIER', Icons.verified_user_outlined),
                  ),
                  TextButton.icon(
                    key: const Key('account_edit_profile_button'),
                    onPressed: () => _showEditProfileBottomSheet(user),
                    icon: const Icon(Icons.edit, size: 13, color: AppTheme.crimsonMaroon),
                    label: Text(
                      'Edit Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.crimsonMaroon,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildProfileInfoRow(Icons.phone_android, 'Mobile Number', phone, isVerified: true),
                    const Divider(height: 18),
                    _buildProfileInfoRow(Icons.work_outline, 'Profession', occupation),
                    const Divider(height: 18),
                    _buildProfileInfoRow(
                      Icons.shield_outlined,
                      'Tax Exemption Status',
                      'Sec 56(2)(x) 100% Tax-Free Compliant',
                      onInfoTap: _showTaxExemptionExplanationDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 2: MARRIAGE REGISTRATION INVITATION / CARD
              _buildProfileSectionHeader('MY WEDDING REGISTRY', Icons.favorite_outline),
              _buildMarriageRegistryStatusCard(),

              const SizedBox(height: 20),

              // SECTION 3: QUICK PLATFORM ACCESS
              _buildProfileSectionHeader('PLATFORM ACCESS', Icons.apps),

              // Microsite Registry button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.celebration, color: AppTheme.royalGold, size: 18),
                  label: Text(
                    'Enter Wedding Microsite & Registry ➔',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B5E00),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.royalGold, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Admin Moderation Console button - Only visible to platform admins
              if (ApiService.instance.currentSession?.user.role.toUpperCase().contains('ADMIN') ?? false) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings, color: AppTheme.crimsonMaroon, size: 18),
                    label: Text(
                      'Open Admin Moderation Console ➔',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.crimsonMaroon,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.crimsonMaroon, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 24),

              // Sign Out Button at bottom
              Center(
                child: TextButton.icon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout, size: 16, color: AppTheme.crimsonMaroon),
                  label: Text(
                    'Sign Out / Switch Account',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.crimsonMaroon,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestProfileView() {
    return Scaffold(
      backgroundColor: AppTheme.ivoryBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.crimsonMaroon, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.crimsonMaroon.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_circle_outlined, size: 40, color: AppTheme.crimsonMaroon),
              ),
              const SizedBox(height: 18),
              Text(
                'Sign In to View Profile',
                style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
              ),
              const SizedBox(height: 8),
              Text(
                'Log in with your mobile number to view your couple registry, gift history, and profile dossier.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(
                          onLoginSuccess: () {
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.crimsonMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Sign In with Mobile ➔',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarriageRegistryStatusCard() {
    final userPhone = _currentUser?.mobileNumber ?? '';

    return FutureBuilder<List<MarriageSubmission>>(
      future: ApiService.instance.getMyMarriageRegistrations(_currentUser?.id ?? 1),
      builder: (context, snapshot) {
        final submissions = snapshot.data ?? [];
        MarriageSubmission? mySubmission;
        if (userPhone.isNotEmpty) {
          final cleanPhone = userPhone.replaceAll(RegExp(r'\s+'), '');
          for (final sub in submissions) {
            final bPhone = sub.bride.mobileNumber.replaceAll(RegExp(r'\s+'), '');
            final gPhone = sub.groom.mobileNumber.replaceAll(RegExp(r'\s+'), '');
            if (bPhone == cleanPhone || gPhone == cleanPhone) {
              mySubmission = sub;
              break;
            }
          }
        }

        // If user already has an active or submitted marriage
        if (mySubmission != null) {
          final isApproved = mySubmission.isApproved;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isApproved ? AppTheme.greenVerified.withOpacity(0.6) : const Color(0xFFFDBA74),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mySubmission.coupleTitle,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isApproved ? 'APPROVED & LIVE' : 'UNDER ADMIN REVIEW',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isApproved ? AppTheme.greenVerified : const Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Reference: ${mySubmission.referenceNumber} • ${mySubmission.city}',
                  style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.textMuted),
                ),
                if (isApproved && mySubmission.assignedFlat != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Assigned Flat: ${mySubmission.assignedFlat!.unitNumber} (${mySubmission.assignedFlat!.builderName})',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.royalGold),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MarriageRegistrationScreen(existingSubmission: mySubmission),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimsonMaroon,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'View / Edit Registration Details ➔',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // If user has not yet registered for marriage -> Promote 3-Step Wizard
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF701322), Color(0xFF8B1E2D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppTheme.crimsonMaroon.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: AppTheme.lightGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'REGISTER FOR MARRIAGE',
                      style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.lightGold, letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Turn Wedding Blessings Into Your First Home',
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Set up your couple registry, select your dream 2 BHK/3 BHK unit, and share dynamic invites.',
                style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MarriageRegistrationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Start Marriage Registration (3 Steps) ➔',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF701322)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.crimsonMaroon),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.crimsonMaroon,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isVerified = false,
    VoidCallback? onInfoTap,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppTheme.royalGold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
        if (onInfoTap != null)
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 17, color: AppTheme.royalGold),
            tooltip: 'Learn about $label',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            onPressed: onInfoTap,
          ),
        if (isVerified)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 14, color: AppTheme.greenVerified),
          ),
      ],
    );
  }

  void _showTaxExemptionExplanationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.greenVerified.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppTheme.greenVerified, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Section 56(2)(x) Exemption',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.crimsonMaroon,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What is Section 56(2)(x)?',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Under the Indian Income Tax Act 1961, Section 56(2)(x) explicitly exempts all wedding gifts received by a couple on the occasion of their marriage from income tax without any monetary upper limit.',
              style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEADBBE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: AppTheme.crimsonMaroon, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All guest gifts are deposited directly into an RBI-regulated tripartite Escrow account with bank-generated digital gift deeds.',
                      style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF2C1810), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimsonMaroon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Understood',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileBottomSheet(ApiUser user) {
    final nameController = TextEditingController(text: user.name);
    final occupationController = TextEditingController(text: user.occupation ?? '');
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isSaving = false;
    String? localError;

    final suggestions = [
      'Software Engineer',
      'Architect',
      'Doctor',
      'Business / Entrepreneur',
      'Chartered Accountant',
      'Designer',
      'Finance & Banking',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6C8B0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Profile Dossier',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.crimsonMaroon,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFEADBBE)),
                    const SizedBox(height: 16),

                    if (localError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          localError!,
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFB91C1C)),
                        ),
                      ),
                    ],

                    // Name Field
                    Text('Your Name / Couple Name *', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      cursorColor: AppTheme.crimsonMaroon,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2C1810)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF9F5EE),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.crimsonMaroon, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEADBBE))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEADBBE))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.crimsonMaroon, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Occupation Field
                    Text('What do you do? (Occupation)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: occupationController,
                      cursorColor: AppTheme.crimsonMaroon,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2C1810)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF9F5EE),
                        prefixIcon: const Icon(Icons.work_outline_rounded, color: Color(0xFF8B5E00), size: 20),
                        hintText: 'e.g. Software Engineer, Architect',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEADBBE))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEADBBE))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.crimsonMaroon, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick Suggestion Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestions.map((s) {
                        final isSel = occupationController.text == s;
                        return InkWell(
                          onTap: () => setModalState(() => occupationController.text = s),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.crimsonMaroon : const Color(0xFFF9F5EE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSel ? AppTheme.crimsonMaroon : const Color(0xFFEADBBE)),
                            ),
                            child: Text(
                              s,
                              style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : const Color(0xFF5C4E46)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Password Field (Optional / Change Password)
                    Text('Create / Change Password (Optional)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      cursorColor: AppTheme.crimsonMaroon,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2C1810)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF9F5EE),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.crimsonMaroon, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF64748B)),
                          onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                        ),
                        hintText: 'Enter new password (min 6 chars)',
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFA0988A)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEADBBE))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEADBBE))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.crimsonMaroon, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          final newName = nameController.text.trim();
                          final newOcc = occupationController.text.trim();
                          final newPwd = passwordController.text.trim();

                          if (newName.isEmpty) {
                            setModalState(() => localError = 'Please enter your name');
                            return;
                          }

                          setModalState(() {
                            isSaving = true;
                            localError = null;
                          });

                          try {
                            await ApiService.instance.updateUserProfile(
                              userId: user.id,
                              name: newName,
                              occupation: newOcc.isNotEmpty ? newOcc : null,
                              password: newPwd.isNotEmpty ? newPwd : null,
                            );

                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }

                            if (mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully!'),
                                  backgroundColor: AppTheme.greenVerified,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() {
                              isSaving = false;
                              localError = 'Failed to update profile. Please try again.';
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.crimsonMaroon,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Save Profile Changes ➔', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

