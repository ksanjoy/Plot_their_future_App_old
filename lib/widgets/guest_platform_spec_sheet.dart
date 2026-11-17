import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/api_user_model.dart';
import '../screens/home_screen.dart';
import '../services/api_service.dart';

class GuestPlatformSpecSheet extends StatelessWidget {
  final VoidCallback? onEnterRegistry;

  const GuestPlatformSpecSheet({
    super.key,
    this.onEnterRegistry,
  });

  static void show(BuildContext context, {VoidCallback? onEnter}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GuestPlatformSpecSheet(onEnterRegistry: onEnter),
    );
  }

  void _handleGuestProceed(BuildContext context) {
    // Issue guest session in ApiService
    ApiService.instance.setSession(
      const AuthSession(
        token: 'jwt-guest-spec-session',
        expiresIn: 604800,
        user: ApiUser(
          id: 999,
          name: 'Honored Guest',
          mobileNumber: '+919988776655',
          role: 'GUEST',
          registered: true,
        ),
        accessibleWeddings: ['sanvi-santosh'],
        message: 'Guest session established',
      ),
    );

    Navigator.pop(context);
    if (onEnterRegistry != null) {
      onEnterRegistry!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.ivoryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),

          // Top Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.royalGold.withOpacity(0.6), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.royalGold.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(AppConstants.appIconPath, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PlotTheirFuture',
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.crimsonMaroon,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'APP CONTENT & PLATFORM SPEC',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.royalGold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.crimsonMaroon.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.crimsonMaroon.withOpacity(0.2)),
                  ),
                  child: Text(
                    'GUEST ACCESS',
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.crimsonMaroon,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Watermark banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5AB).withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.goldBorder.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                'M/s PLOT THEIR FUTURE • Confidential & Proprietary',
                style: GoogleFonts.cinzel(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF704200),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const Divider(height: 20),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: WHAT IS PLOTTHEIRFUTURE?
                  _buildSectionHeader('1. What is PlotTheirFuture?'),
                  const SizedBox(height: 8),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The wedding gift that becomes their forever.',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.crimsonMaroon,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PlotTheirFuture is India’s first digital wedding gift registry built around the one dream every couple shares: a home of their own.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We are redefining the tradition of wedding gifting. Instead of temporary, forgotten presents, we enable your loved ones to contribute toward the permanent foundation of your new beginning. PlotTheirFuture brings your wedding celebration, your guest list, and your future home together into one seamless digital experience.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.goldCardFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.goldBorder.withOpacity(0.6)),
                          ),
                          child: Center(
                            child: Text(
                              '“Celebrate the wedding. Build the future.”',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8B5E00),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // SECTION 2: FOR THE COUPLE
                  _buildSectionHeader('2. For the Couple'),
                  const SizedBox(height: 8),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your wedding, your way. Your future, together.',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a personalized digital wedding space, invite your loved ones, and give them a deeply meaningful way to contribute to your first home.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'KEY APP FEATURES',
                          style: GoogleFonts.cinzel(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.crimsonMaroon,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureTile(
                          title: 'Custom Wedding Microsite',
                          description: 'Build and personalize your unique wedding space in minutes.',
                          icon: Icons.web,
                        ),
                        _buildFeatureTile(
                          title: 'Smart Digital Invites',
                          description: 'Create and share beautiful digital invitation cards and video invites.',
                          icon: Icons.mark_email_read_outlined,
                        ),
                        _buildFeatureTile(
                          title: 'Seamless RSVP Manager',
                          description: 'Send digital invites, track RSVPs, and manage guest responses in real time.',
                          icon: Icons.how_to_reg_outlined,
                        ),
                        _buildFeatureTile(
                          title: 'Guest Logistics Hub',
                          description: 'Easily collect guest details, stay preferences, and dietary requirements.',
                          icon: Icons.hotel_outlined,
                        ),
                        _buildFeatureTile(
                          title: 'Gift-a-Square-Foot Registry',
                          description: 'Choose your future home and map it out on a digital grid of square feet.',
                          icon: Icons.grid_view_rounded,
                        ),
                        _buildFeatureTile(
                          title: 'Collective Gifting & Tracking',
                          description: 'Enable loved ones to gift square feet toward your down payment and view contributions live.',
                          icon: Icons.trending_up,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // SECTION 3: FOR THE GUEST
                  _buildSectionHeader('3. For the Guest'),
                  const SizedBox(height: 8),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Don’t just attend their wedding. Be part of their foundation.',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.crimsonMaroon,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Celebrate the couple you love and leave an indelible mark on the life they are building together.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'KEY APP FEATURES',
                          style: GoogleFonts.cinzel(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.crimsonMaroon,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureTile(
                          title: 'Digital Invitation Access',
                          description: 'Receive invitations and explore the wedding details in one central hub.',
                          icon: Icons.mail_outline,
                        ),
                        _buildFeatureTile(
                          title: 'Gift-a-Square-Foot',
                          description: 'Directly fund their future home by choosing to gift 1, 5, 10, or more square feet.',
                          icon: Icons.home_outlined,
                        ),
                        _buildFeatureTile(
                          title: 'Interactive Digital Grid',
                          description: 'Select the exact "square footage" you want to gift and see it unlock on their registry.',
                          icon: Icons.view_module,
                        ),
                        _buildFeatureTile(
                          title: 'Personal Blessings & Photos',
                          description: 'Leave warm wishes, digital messages, and upload photos directly to the couple.',
                          icon: Icons.favorite_border,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCF8EE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.royalGold.withOpacity(0.5)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '“Because sometimes, the best wedding gift isn\'t something you give them. It’s a home you help them build.”',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF7A4A00),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'M/s Plot Their Future • Platform Overview',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.crimsonMaroon,
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
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _handleGuestProceed(context),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  label: Text(
                    'Enter Wedding Registry as Guest ➔',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.crimsonMaroon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightGold.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.royalGold.withOpacity(0.35)),
      ),
      child: Text(
        title,
        style: GoogleFonts.cinzel(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: AppTheme.crimsonMaroon,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBDAB0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFeatureTile({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.lightGold.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.crimsonMaroon, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

