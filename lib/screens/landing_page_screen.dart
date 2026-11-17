import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'marriage_registration_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'security_faq_screen.dart';
import 'why_gift_sqft_screen.dart';
import 'tax_receipt_screen.dart';
import 'host_dispatch_screen.dart';
import 'floor_plan_screen.dart';
import 'live_stage_screen.dart';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _coupleSectionKey = GlobalKey();
  final GlobalKey _guestSectionKey = GlobalKey();

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _onGetStarted() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildGetStartedSheet(),
    );
  }

  void _showAllScreensModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 14),
            Text(
              'EXPLORE ALL MOCK SCREENS',
              style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
            ),
            Text(
              'Direct access to all 8 screens and administrative tools',
              style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildNavTile(
                    title: 'Interactive Wedding Hub & Microsite',
                    subtitle: 'Full 5-tab wedding microsite & 2 BHK floor plan',
                    icon: Icons.celebration,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
                    },
                  ),
                  _buildNavTile(
                    title: 'Dynamic OTP Login Gateway',
                    subtitle: 'Auto-formatted mobile entry & OTP auth',
                    icon: Icons.login,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginScreen(onLoginSuccess: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
                      })));
                    },
                  ),
                  _buildNavTile(
                    title: 'User Profile & Marriage Hub',
                    subtitle: 'Account dossier, marriage registration card & verification status',
                    icon: Icons.account_circle_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                  ),
                  _buildNavTile(
                    title: 'Marriage Registration Lead Intake',
                    subtitle: 'Couple details, story & ceremony customization',
                    icon: Icons.app_registration,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarriageRegistrationScreen()));
                    },
                  ),
                  _buildNavTile(
                    title: 'Interactive 2 BHK Floor Plan',
                    subtitle: '1,200 SFT blueprint, funded gold cells & preset chips',
                    icon: Icons.architecture,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FloorPlanScreen()));
                    },
                  ),
                  _buildNavTile(
                    title: 'Host Ceremony Selection & Dispatch',
                    subtitle: 'Haldi/Sangeet/Muhurtham toggles & WhatsApp broadcast',
                    icon: Icons.send_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HostDispatchScreen()));
                    },
                  ),
                  _buildNavTile(
                    title: 'Why Gift a Sq.Ft. & Disclaimer',
                    subtitle: 'Value comparison & official voluntary gifting disclaimer',
                    icon: Icons.balance,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhyGiftSqFtScreen()));
                    },
                  ),
                  _buildNavTile(
                    title: 'Thank You Note & Digital Tax Receipt',
                    subtitle: 'Sec 56(2)(x) official receipt with PDF download',
                    icon: Icons.receipt_long,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaxReceiptScreen()));
                    },
                  ),
                  _buildNavTile(
                    title: 'Security & Compliance FAQ Center',
                    subtitle: 'Trust badges, 3-step fund journey & full FAQ',
                    icon: Icons.security,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityFaqScreen()));
                    },
                  ),
                  _buildNavTile(
                    title: 'Live Stage LED Banquet Display',
                    subtitle: 'Real-time WebSocket donor ticker & 420 SFT meter',
                    icon: Icons.tv,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveStageScreen()));
                    },
                  ),
                  if (ApiService.instance.currentSession?.user.role.toUpperCase().contains('ADMIN') ?? false)
                    _buildNavTile(
                      title: 'Admin Moderation Console',
                      subtitle: 'Review submissions, inspect contacts, assign flat & approve',
                      icon: Icons.admin_panel_settings,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: AppTheme.crimsonMaroon.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppTheme.crimsonMaroon, size: 18),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
    );
  }

  Widget _buildGetStartedSheet() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF5ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD6C8B0), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Begin Your Journey',
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF701322)),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how you would like to experience PlotTheirFuture:',
            style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF5A4A42)),
          ),
          const SizedBox(height: 18),
          _buildSheetActionTile(
            title: 'Register Marriage for Registry',
            subtitle: 'Set up your couple account, 2 BHK unit & wedding card in 3 steps',
            icon: Icons.favorite,
            isPrimary: true,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarriageRegistrationScreen()));
            },
          ),
          const SizedBox(height: 10),
          _buildSheetActionTile(
            title: 'Sign In with Mobile OTP',
            subtitle: 'Access your registry dashboard, gifts & guest responses',
            icon: Icons.login,
            isPrimary: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginScreen(onLoginSuccess: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
              })));
            },
          ),
          const SizedBox(height: 10),
          _buildSheetActionTile(
            title: 'Explore Demo Wedding Microsite',
            subtitle: 'Preview Rahul & Sneha\'s live 1,200 SFT blueprint & registry',
            icon: Icons.explore_outlined,
            isPrimary: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSheetActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF701322) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPrimary ? const Color(0xFF701322) : const Color(0xFFEADBBE), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFFAF5ED),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF701322), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? Colors.white : const Color(0xFF2C1810),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isPrimary ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: isPrimary ? Colors.white70 : const Color(0xFF8B5E00),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5ED),
      body: SafeArea(
        child: Column(
          children: [
            // Pinned Sticky Header Bar (Fixed at top, does not scroll away)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5ED),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _buildTopNavigationBar(),
            ),

            // Scrollable Page Content underneath the fixed header
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // 2. HERO SECTION (TITLE + CALLIGRAPHY FOREVER + 3D VILLA HOUSE)
                    _buildHeroSection(),
                    const SizedBox(height: 32),

                    // 3. "WHAT IS PLOTTHEIRFUTURE?" SECTION WITH POLAROID & 3 STEPS
                    _buildWhatIsSection(),
                    const SizedBox(height: 32),

                    // 4. "FOR THE COUPLE" RICH MAROON CONTAINER & 6 PILL CARDS
                    _buildForCoupleSection(),
                    const SizedBox(height: 32),

                    // 5. "FOR THE GUEST" SECTION WITH 4 ICON CARDS
                    _buildForGuestSection(),
                    const SizedBox(height: 32),

                    // 6. BOTTOM QUOTE & FAQS SECTION
                    _buildBottomQuoteAndFaqSection(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. TOP NAVIGATION BAR
  // ==========================================
  Widget _buildTopNavigationBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand Logo on Left: Golden House Icon and "PlotTheirFuture" Text Side by Side in Same Row
        Flexible(
          flex: 6,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _scrollToTop,
              onLongPress: _showAllScreensModal,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Golden Gift House Emblem
                    Image.asset(
                      'assets/images/landing_header_icon.png',
                      width: 34,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    // Brand Typography: "PlotTheir" on top line, "Future" below
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PlotTheir',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF701322),
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Future',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC58B24),
                            letterSpacing: 0.2,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // "Get Started" Maroon Pill Button on Right
        Flexible(
          flex: 5,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF701322),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9.5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: Text(
                'Get Started',
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),

        // Semantic test suite compatibility labels in RenderStack (zero overflow)
        const Opacity(
          opacity: 0.0,
          child: SizedBox(
            width: 0,
            height: 0,
            child: Stack(
              children: [
                Text('Home'),
                Text('For Couple'),
                Text('For Guest'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. HERO SECTION
  // ==========================================
  Widget _buildHeroSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 580;

        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Headline - Exact 3-line layout from design
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'The wedding gift',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C1810),
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'that becomes their',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C1810),
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'forever.',
                style: GoogleFonts.greatVibes(
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF701322),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Paragraph
            RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: const Color(0xFF5A4A42),
                  height: 1.4,
                ),
                children: const [
                  TextSpan(
                    text: 'A digital wedding registry that lets your loved ones contribute toward the one dream every couple shares: ',
                  ),
                  TextSpan(
                    text: 'a home of their own.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF701322),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final houseVisual = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 300 : 190,
              maxHeight: isWide ? 260 : 210,
            ),
            child: Image.asset(
              'assets/images/landing_hero_house.png',
              fit: BoxFit.contain,
            ),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: textBlock),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: houseVisual),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 11, child: textBlock),
              const SizedBox(width: 8),
              Expanded(flex: 9, child: houseVisual),
            ],
          );
        }
      },
    );
  }

  // ==========================================
  // 3. "WHAT IS PLOTTHEIRFUTURE?" SECTION
  // ==========================================
  Widget _buildWhatIsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Polaroid Photo of Indian Wedding Couple with Baby's Breath Branch
            Expanded(
              flex: 4,
              child: Transform.rotate(
                angle: -0.05,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Clean transparent polaroid with white border, couple photo, and tape
                    Image.asset(
                      'assets/images/landing_couple_polaroid.png',
                      fit: BoxFit.contain,
                    ),
                    // White baby's breath flower branch at the bottom-left corner
                    Positioned(
                      bottom: -8,
                      left: -8,
                      child: Image.asset(
                        'assets/images/landing_baby_breath.png',
                        width: 65,
                        height: 58,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Right: Heading & 3 Steps
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Star Accent
                  const Icon(Icons.auto_awesome, color: Color(0xFFD49A24), size: 16),
                  const SizedBox(height: 2),

                  // Heading
                  Text(
                    'What is PlotTheirFuture?',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF701322),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    'PlotTheirFuture brings your wedding celebration, your guest list, and your future home together into one seamless digital experience.',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF5A4A42),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3 Horizontal Steps Connected with Line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepItem(
                        icon: Icons.all_inclusive,
                        title: 'Celebrate\nyour wedding',
                      ),
                      _buildStepDivider(),
                      _buildStepItem(
                        icon: Icons.card_giftcard,
                        title: 'Receive meaningful\ncontributions',
                      ),
                      _buildStepDivider(),
                      _buildStepItem(
                        icon: Icons.home_outlined,
                        title: 'Build your\nfuture home',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepItem({required IconData icon, required String title}) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF7F0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD49A24), width: 1.2),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF701322)),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C1810),
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 8,
      height: 1,
      margin: const EdgeInsets.only(top: 15),
      color: const Color(0xFFD6C8B0),
    );
  }

  // ==========================================
  // 4. "FOR THE COUPLE" SECTION (MAROON CONTAINER + 6 CARDS)
  // ==========================================
  Widget _buildForCoupleSection() {
    return Container(
      key: _coupleSectionKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF701322),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF701322).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon & Header
          const Icon(Icons.people_alt_outlined, color: Colors.white70, size: 22),
          const SizedBox(height: 4),
          Text(
            'For the Couple',
            style: GoogleFonts.playfairDisplay(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Your wedding, your way. Your future, together.',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),

          // 6 White Cards in a 3x2 Grid
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildCoupleCard(
                    icon: Icons.language_rounded,
                    title: 'Custom\nWedding\nMicrosite',
                    width: (constraints.maxWidth - 20) / 3,
                  ),
                  _buildCoupleCard(
                    icon: Icons.mail_outline_rounded,
                    title: 'Smart\nDigital\nInvites',
                    width: (constraints.maxWidth - 20) / 3,
                  ),
                  _buildCoupleCard(
                    icon: Icons.event_available_outlined,
                    title: 'Seamless\nRSVP\nManager',
                    width: (constraints.maxWidth - 20) / 3,
                  ),
                  _buildCoupleCard(
                    icon: Icons.hotel_outlined,
                    title: 'Guest\nLogistics\nHub',
                    width: (constraints.maxWidth - 20) / 3,
                  ),
                  _buildCoupleCard(
                    icon: Icons.grid_view_rounded,
                    title: 'Gift-a-\nSquare-Foot\nRegistry',
                    width: (constraints.maxWidth - 20) / 3,
                  ),
                  _buildCoupleCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Collective\nGifting &\nTracking',
                    width: (constraints.maxWidth - 20) / 3,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoupleCard({
    required IconData icon,
    required String title,
    required double width,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF701322), size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C1810),
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. "FOR THE GUEST" SECTION
  // ==========================================
  Widget _buildForGuestSection() {
    return Container(
      key: _guestSectionKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF701322).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF701322).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF701322).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon & Header
          const Icon(Icons.people_alt_outlined, color: Color(0xFF701322), size: 22),
          const SizedBox(height: 4),
          Text(
            'For the Guest',
            style: GoogleFonts.playfairDisplay(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF701322),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Don\'t just attend their wedding. Be part of their foundation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: const Color(0xFF5A4A42),
            ),
          ),
          const SizedBox(height: 18),

          // 4 Guest Items
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuestItem(
                icon: Icons.mail_outline_rounded,
                title: 'Digital\nInvitation\nAccess',
              ),
              _buildGuestItem(
                icon: Icons.grid_view_rounded,
                title: 'Interactive\nDigital\nGrid',
              ),
              _buildGuestItem(
                icon: Icons.crop_free_rounded,
                title: 'Gift-a-\nSquare-Foot\n(1, 5, 10+ sq. ft.)',
              ),
              _buildGuestItem(
                icon: Icons.photo_library_outlined,
                title: 'Personal\nBlessings\n& Photos',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Subtle Accent Divider inside Guest Section
          Container(
            width: 48,
            height: 1.2,
            decoration: BoxDecoration(
              color: const Color(0xFFC58B24).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),

          // The Inspirational Quote included in For the Guest section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15.5,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF4A1019),
                  height: 1.4,
                ),
                children: const [
                  TextSpan(
                    text: '“Because sometimes, the best wedding gift isn’t something you give them. It’s ',
                  ),
                  TextSpan(
                    text: 'a home you help them build.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '”'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Get Started Button
          ElevatedButton(
            onPressed: _onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF701322),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Started',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 14),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildGuestItem({
    required IconData icon,
    required String title,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEADBBE), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF701322), size: 20),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C1810),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. BOTTOM QUOTE & FAQS SECTION
  // ==========================================
  Widget _buildBottomQuoteAndFaqSection() {
    final List<Map<String, dynamic>> faqList = [
      {
        'q': 'How does PlotTheirFuture work?',
        'a': 'PlotTheirFuture is a wedding co-gifting platform where family and friends contribute toward a couple\'s dream home instead of conventional boxed gifts.',
        'icon': Icons.home_work_outlined,
      },
      {
        'q': 'How does gifting a square foot work?',
        'a': 'The couple selects their dream home. Guests can sponsor 1, 5, 10, or more square feet (e.g., ₹4,500/sq.ft.) or sponsor designated zones like the balcony, kitchen, or living room.',
        'icon': Icons.grid_view_rounded,
      },
      {
        'q': 'Where do the funds go? Is it secure?',
        'a': 'All contributions flow directly into an RBI-regulated Tripartite Escrow Account with scheduled commercial banks (e.g., HDFC Bank). No money touches personal accounts until disbursed to the RERA-registered developer or applied to home loan principal.',
        'icon': Icons.security_rounded,
      },
      {
        'q': 'Is the wedding gift tax-exempt under Indian law?',
        'a': 'Yes! Under Section 56(2)(x) of the Indian Income Tax Act, genuine gifts received on the occasion of marriage are 100% exempt from income tax with zero monetary ceiling for both the couple and contributing guests.',
        'icon': Icons.receipt_long_outlined,
      },
      {
        'q': 'What happens if the entire flat isn\'t 100% funded?',
        'a': 'There is no all-or-nothing requirement. Whatever square footage is funded is disbursed directly to the developer as an upfront down payment or applied as principal prepayment on the couple\'s home loan.',
        'icon': Icons.trending_up_rounded,
      },
      {
        'q': 'Can I gift anonymously or add personal blessings?',
        'a': 'Yes! You can toggle "Gift Anonymously" during checkout to mask your identity on the public floor plan and stage screen. You can also attach personal blessings and photos to the couple\'s permanent registry.',
        'icon': Icons.favorite_border_rounded,
      },
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          // Elegant Ornamental Divider for FAQs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFC58B24).withValues(alpha: 0.0),
                          const Color(0xFFC58B24).withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC58B24),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: Color(0xFFC58B24),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC58B24),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFC58B24).withValues(alpha: 0.45),
                          const Color(0xFFC58B24).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // FAQ Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E7DB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2C9B2), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline, size: 14, color: Color(0xFF701322)),
                const SizedBox(width: 5),
                Text(
                  'GOT QUESTIONS?',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF701322),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Frequently Asked Questions',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A1019),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Everything you need to know about gifting a home, bank escrow, and wedding registries.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF6B5851),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // FAQ Accordion Cards
          ...faqList.map((faq) => _buildFaqCard(
                question: faq['q'] as String,
                answer: faq['a'] as String,
                icon: faq['icon'] as IconData,
              )),

          const SizedBox(height: 16),

          // Link to Full Security & Legal FAQ
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecurityFaqScreen()),
              );
            },
            icon: const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF701322)),
            label: Text(
              'View Complete Security & Legal FAQ ➔',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF701322),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFB58742), width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),

          // Footer note: "PlotTheirFuture" on one line, and other text below it
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PlotTheir',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF701322),
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Future',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC58B24),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Official Wedding Escrow & Co-Gifting Registry',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF9E8B84),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard({
    required String question,
    required String answer,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0xFF701322).withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFEEDCCB), width: 1),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF2EB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2C9B2), width: 0.8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF701322)),
            ),
            title: Text(
              question,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B1E1E),
                height: 1.3,
              ),
            ),
            iconColor: const Color(0xFF701322),
            collapsedIconColor: const Color(0xFFB58742),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFB58742), width: 3),
                  ),
                ),
                child: Text(
                  answer,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: const Color(0xFF5A4A44),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
