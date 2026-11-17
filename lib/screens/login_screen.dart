import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/api_user_model.dart';
import '../services/api_service.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';

class _CountryCodeItem {
  final String id;
  final String flag;
  final String code;
  final String name;

  const _CountryCodeItem({
    required this.id,
    required this.flag,
    required this.code,
    required this.name,
  });
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Step 0: Phone Input, Step 1: OTP Verify, Step 2: New User Profile (Name + Profession), Step 3: Proper Profile Screen
  int _currentFlowStep = 0;

  // Country Codes Selection
  String _selectedCountryId = 'IN';

  static const List<_CountryCodeItem> _countryCodes = [
    _CountryCodeItem(id: 'IN', flag: '🇮🇳', code: '+91', name: 'India'),
    _CountryCodeItem(id: 'US', flag: '🇺🇸', code: '+1', name: 'United States'),
    _CountryCodeItem(id: 'GB', flag: '🇬🇧', code: '+44', name: 'United Kingdom'),
    _CountryCodeItem(id: 'AE', flag: '🇦🇪', code: '+971', name: 'UAE'),
    _CountryCodeItem(id: 'SG', flag: '🇸🇬', code: '+65', name: 'Singapore'),
    _CountryCodeItem(id: 'AU', flag: '🇦🇺', code: '+61', name: 'Australia'),
    _CountryCodeItem(id: 'CA', flag: '🇨🇦', code: '+1', name: 'Canada'),
    _CountryCodeItem(id: 'DE', flag: '🇩🇪', code: '+49', name: 'Germany'),
    _CountryCodeItem(id: 'MY', flag: '🇲🇾', code: '+60', name: 'Malaysia'),
    _CountryCodeItem(id: 'SA', flag: '🇸🇦', code: '+966', name: 'Saudi Arabia'),
    _CountryCodeItem(id: 'QA', flag: '🇶🇦', code: '+974', name: 'Qatar'),
    _CountryCodeItem(id: 'KW', flag: '🇰🇼', code: '+965', name: 'Kuwait'),
  ];

  _CountryCodeItem get _selectedCountry =>
      _countryCodes.firstWhere((c) => c.id == _selectedCountryId, orElse: () => _countryCodes.first);

  // Controllers (empty mobile by default - no prefilled text)
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _createPasswordController = TextEditingController();
  final _otpController = TextEditingController(text: "123456");
  final _nameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _mobileFocusNode = FocusNode();

  // State
  bool _isLoading = false;
  bool _isPasswordLoginMode = false;
  bool _obscurePassword = true;
  bool _obscureCreatePassword = true;
  String? _errorMessage;
  ApiUser? _authenticatedUser;

  // Resend OTP countdown timer
  int _resendCountdown = 30;
  Timer? _countdownTimer;

  final List<String> _occupationSuggestions = [
    'Software Engineer',
    'Architect',
    'Doctor',
    'Business / Entrepreneur',
    'Chartered Accountant',
    'Designer',
    'Finance & Banking',
  ];

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _mobileFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _mobileController.dispose();
    _passwordController.dispose();
    _createPasswordController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _occupationController.dispose();
    _mobileFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 30);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // ==========================================
  // AUTHENTICATION LOGIC
  // ==========================================

  Future<void> _handleRequestOtp() async {
    final rawPhone = _mobileController.text.trim();
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 8) {
      setState(() => _errorMessage = 'Please enter a valid mobile number');
      return;
    }

    final dialCode = _selectedCountry.code;
    final phone = rawPhone.startsWith('+') ? rawPhone : '$dialCode ${rawPhone.replaceAll(' ', '')}';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.instance.requestOtp(
        phone: phone,
        slug: AppConstants.campaignSlug,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentFlowStep = 1; // Advance to OTP entry
          if (_otpController.text.isEmpty) {
            _otpController.text = '123456';
          }
        });
        _startResendTimer();

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'OTP dispatched successfully to $phone'),
            backgroundColor: AppTheme.crimsonMaroon,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e is ApiException) {
            _errorMessage = e.message;
          } else {
            _errorMessage = e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '');
          }
        });
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final rawPhone = _mobileController.text.trim();
    final dialCode = _selectedCountry.code;
    final phone = rawPhone.startsWith('+') ? rawPhone : '$dialCode ${rawPhone.replaceAll(' ', '')}';
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await ApiService.instance.verifyOtp(
        phone: phone,
        otp: otp,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _authenticatedUser = session.user;
        });

        ScaffoldMessenger.of(context).clearSnackBars();

        // Automatic user check: if user already exists or has completed profile
        final isExisting = session.isExistingUser ||
            (session.user.registered && session.user.name.trim().isNotEmpty && session.user.name != 'Guest User') ||
            session.user.role.toUpperCase().contains('ADMIN') ||
            (session.user.name.trim().isNotEmpty &&
                session.user.name != 'Guest User' &&
                session.user.occupation != null &&
                session.user.occupation!.trim().isNotEmpty);

        if (isExisting) {
          // Existing user -> Directly complete login and route to Home Screen!
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${session.user.name.isNotEmpty ? session.user.name : "Member"}!'),
              backgroundColor: AppTheme.greenVerified,
              duration: const Duration(seconds: 2),
            ),
          );
          _completeLoginAndNavigateHome();
        } else {
          // New user -> Show name & profession input
          setState(() => _currentFlowStep = 2);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e is ApiException) {
            _errorMessage = e.message;
          } else {
            _errorMessage = e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '');
          }
        });
      }
    }
  }

  Future<void> _handlePasswordLogin() async {
    final rawPhone = _mobileController.text.trim();
    final dialCode = _selectedCountry.code;
    final phone = rawPhone.startsWith('+') ? rawPhone : '$dialCode ${rawPhone.replaceAll(' ', '')}';
    final password = _passwordController.text.trim();

    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      setState(() => _errorMessage = 'Please enter a valid mobile number');
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your account password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await ApiService.instance.loginWithPassword(
        mobileNumber: phone,
        password: password,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _authenticatedUser = session.user;
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${session.user.name.isNotEmpty ? session.user.name : "Member"}!'),
            backgroundColor: AppTheme.greenVerified,
            duration: const Duration(seconds: 2),
          ),
        );

        _completeLoginAndNavigateHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid mobile number or password. Please try again.';
        });
      }
    }
  }

  Future<void> _handleSaveNewUserProfile({bool isSkipped = false}) async {
    final name = _nameController.text.trim();
    final occ = _occupationController.text.trim();
    final pwd = _createPasswordController.text.trim();

    if (!isSkipped && name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name to complete registration');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final finalName = name.isNotEmpty ? name : 'Honored Guest';
    final finalOcc = occ.isNotEmpty ? occ : null;
    final finalPwd = pwd.isNotEmpty ? pwd : null;

    if (_authenticatedUser != null) {
      await ApiService.instance.updateUserProfile(
        userId: _authenticatedUser!.id,
        name: finalName,
        occupation: finalOcc,
        password: finalPwd,
        isSkipped: isSkipped,
      );
      _authenticatedUser = ApiService.instance.currentSession?.user ?? _authenticatedUser;
    }

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSkipped ? 'Welcome! Profile setup completed.' : 'Welcome, $finalName! Profile created successfully.'),
          backgroundColor: AppTheme.royalGold,
          duration: const Duration(seconds: 2),
        ),
      );

      _completeLoginAndNavigateHome();
    }
  }

  void _completeLoginAndNavigateHome() {
    widget.onLoginSuccess();
    if (mounted) {
      final isAdmin = ApiService.instance.currentSession?.user.role.toUpperCase().contains('ADMIN') ?? false;
      if (isAdmin) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showCountryPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF6EE),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6C8B0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Select Country Code',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF701322),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEADBBE)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _countryCodes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0E5D0), indent: 56),
                  itemBuilder: (context, index) {
                    final item = _countryCodes[index];
                    final isSelected = item.id == _selectedCountryId;

                    return ListTile(
                      leading: Text(item.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        item.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: const Color(0xFF2C1810),
                        ),
                      ),
                      trailing: Text(
                        item.code,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF701322) : const Color(0xFF8B5E00),
                        ),
                      ),
                      tileColor: isSelected ? const Color(0xFF701322).withOpacity(0.06) : null,
                      onTap: () {
                        setState(() => _selectedCountryId = item.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // MAIN BUILD ROUTING
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return _buildCleanLoginScreen();
  }

  // =========================================================================
  // 1. PROPER CLEAN LOGIN SCREEN WITH HIGH-RES SUNSET VILLA BACKGROUND
  // =========================================================================
  Widget _buildCleanLoginScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F0),
      body: Stack(
        children: [
          // 1. High-Resolution Sunset Wedding Villa Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Interactive Layer (Dynamically Framed Around Couple Portrait)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenH = constraints.maxHeight;
                // Adaptive spacing: generous for Step 0, compact for Step 1 & 2 so form elements & buttons fit gracefully
                final double coupleSpacing;
                if (_currentFlowStep == 0) {
                  coupleSpacing = (screenH > 640) ? (screenH * 0.26).clamp(140.0, 220.0) : 30.0;
                } else if (_currentFlowStep == 1) {
                  coupleSpacing = (screenH > 640) ? (screenH * 0.26).clamp(140.0, 220.0) : 30.0;
                } else {
                  coupleSpacing = (screenH > 640) ? (screenH * 0.05).clamp(20.0, 42.0) : 10.0;
                }

                return Column(
                  children: [
                    // Top Back Arrow
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 2),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2C1810), size: 18),
                            onPressed: () {
                              if (_currentFlowStep == 1 || _currentFlowStep == 2) {
                                setState(() => _currentFlowStep = 0);
                              } else {
                                Navigator.maybePop(context);
                              }
                            },
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),

                    // Main Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Brand Header: Official Brand App Icon + Two-Tone Title + Subtitle
                              _buildBrandHeader(),

                              // Dynamic Couple Visibility Spacing
                              SizedBox(height: coupleSpacing),

                              // The Floating Luxury Login Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF4EB).withOpacity(0.96),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0xFFEADBBE), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _currentFlowStep == 0
                                    ? _buildStepZeroPhoneInput()
                                    : (_currentFlowStep == 1 ? _buildStepOneOtpVerify() : _buildStepTwoNewUserProfile()),
                              ),

                              // Bottom clearance so background line sketch & wave remain pristine
                              const SizedBox(height: 70),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        // Proper Official Brand App Icon (Maroon House with Gold Star)
        Image.asset(
          'assets/images/app_icon_maroon.png',
          width: 58,
          height: 48,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),

        // Brand Name: Two-Tone Typography (PlotTheir in Maroon, Future in Gold)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PlotTheir',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF701322),
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                ' Future',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD49A24),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'WEDDING GIFT REGISTRY & REAL ESTATE PLATFORM',
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF701322),
              letterSpacing: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------
  // STEP 0: PHONE NUMBER INPUT (APP THEME PALETTE)
  // ------------------------------------------
  Widget _buildStepZeroPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isPasswordLoginMode ? 'Sign In with Password' : 'Sign In with Mobile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF701322),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _isPasswordLoginMode
              ? 'Enter your mobile number and account password'
              : 'Enter your mobile number to receive a verification OTP',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: const Color(0xFF5C4E46),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 18),

        // Error Banner
        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 14),
        ],

        // Mobile Number Field Label
        Text(
          'Mobile Number *',
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810)),
        ),
        const SizedBox(height: 8),

        // Rounded Capsule Input Container with Country Code Picker
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F5EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _mobileFocusNode.hasFocus ? const Color(0xFF701322) : const Color(0xFFEADBBE),
              width: _mobileFocusNode.hasFocus ? 1.5 : 1.2,
            ),
            boxShadow: _mobileFocusNode.hasFocus
                ? [
                    BoxShadow(
                      color: const Color(0xFF701322).withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              // Country Code Selector Pill
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _showCountryPickerBottomSheet,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEADBBE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedCountry.flag, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        _selectedCountry.code,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF701322),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF701322), size: 16),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: const Color(0xFFD6C8B0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _mobileController,
                  focusNode: _mobileFocusNode,
                  keyboardType: TextInputType.phone,
                  cursorColor: const Color(0xFF701322),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C1810),
                    letterSpacing: 0.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    hintText: '98480 12345',
                    hintStyle: TextStyle(color: Color(0xFFA0988A), fontWeight: FontWeight.normal),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  ),
                ),
              ),
            ],
          ),
        ),

        // If Password Login Mode: Show Password Field
        if (_isPasswordLoginMode) ...[
          const SizedBox(height: 14),
          Text(
            'Password *',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810)),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEADBBE), width: 1.2),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              cursorColor: const Color(0xFF701322),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C1810),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: false,
                isDense: true,
                hintText: 'Enter your password',
                hintStyle: const TextStyle(color: Color(0xFFA0988A), fontWeight: FontWeight.normal),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF701322), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF701322),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Action Button: Verify OTP OR Sign In with Password
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF701322), Color(0xFF8B1E2D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF701322).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_isPasswordLoginMode ? _handlePasswordLogin : _handleRequestOtp),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPasswordLoginMode ? Icons.login_rounded : Icons.verified_outlined,
                        color: Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPasswordLoginMode ? 'Sign In ➔' : 'Verify ➔',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Toggle between OTP and Password login
        Center(
          child: TextButton.icon(
            key: Key(_isPasswordLoginMode ? 'switch_to_otp_login' : 'switch_to_password_login'),
            onPressed: () {
              setState(() {
                _isPasswordLoginMode = !_isPasswordLoginMode;
                _errorMessage = null;
              });
            },
            icon: Icon(
              _isPasswordLoginMode ? Icons.sms_outlined : Icons.lock_outline_rounded,
              size: 16,
              color: const Color(0xFF701322),
            ),
            label: Text(
              _isPasswordLoginMode ? '← Sign In with Dynamic OTP instead' : 'Login with Password ➔',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF701322),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------
  // STEP 1: OTP VERIFY (APP THEME PALETTE)
  // ------------------------------------------
  Widget _buildStepOneOtpVerify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Verify 6-Digit OTP',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.crimsonMaroon,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _currentFlowStep = 0;
                _errorMessage = null;
              }),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              child: Text(
                'Edit Number',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.royalGold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the 6-digit code sent via WhatsApp to ${_mobileController.text.trim()}',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),

        // Error Banner
        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 14),
        ],

        // 6-digit OTP Field
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          cursorColor: AppTheme.crimsonMaroon,
          maxLength: 6,
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 10, color: AppTheme.crimsonMaroon),
          decoration: InputDecoration(
            counterText: '',
            hintText: '123456',
            hintStyle: GoogleFonts.outfit(fontSize: 18, color: Colors.black26, letterSpacing: 8),
            filled: true,
            fillColor: const Color(0xFFF9F5EE),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEADBBE), width: 1.2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEADBBE), width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.crimsonMaroon, width: 1.5)),
          ),
        ),
        const SizedBox(height: 12),

        // Resend Timer Row
        Center(
          child: _resendCountdown > 0
              ? Text(
                  'Resend code in 00:${_resendCountdown.toString().padLeft(2, '0')}',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _handleRequestOtp,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  child: Text(
                    'Resend OTP Code',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.royalGold),
                  ),
                ),
        ),
        const SizedBox(height: 18),

        // Verify & Continue Button in App Theme Gradient
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: AppTheme.maroonGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.crimsonMaroon.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'Verify & Continue ➔',
                    style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------
  // STEP 2: NEW USER CASUAL PROFILE (NAME + OCCUPATION)
  // ------------------------------------------
  Widget _buildStepTwoNewUserProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome! Just a Quick Intro 🎉',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF701322),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Personalize your couple registry and gifting dashboard',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: const Color(0xFF5C4E46),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 18),

        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 14),
        ],

        // Name Field Label
        Text(
          'Your Name / Couple Name *',
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          cursorColor: const Color(0xFF701322),
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF2C1810)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9F5EE),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.person_outline_rounded, color: Color(0xFF701322), size: 21),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
            hintText: 'e.g. Rahul Varma or Rahul & Sneha',
            hintStyle: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFFA0988A), fontWeight: FontWeight.normal),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEADBBE), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEADBBE), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF701322), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Profession Field Label
        Text(
          'What do you do? (Occupation)',
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _occupationController,
          cursorColor: const Color(0xFF701322),
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF2C1810)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9F5EE),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.work_outline_rounded, color: Color(0xFF8B5E00), size: 21),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
            hintText: 'e.g. Software Engineer, Architect, Doctor',
            hintStyle: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFFA0988A), fontWeight: FontWeight.normal),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEADBBE), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEADBBE), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF701322), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Quick Suggestion Chips (Luxury Gold / Maroon Pills)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _occupationSuggestions.map((occ) {
            final isSelected = _occupationController.text == occ;
            return InkWell(
              onTap: () {
                setState(() => _occupationController.text = occ);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF701322) : const Color(0xFFFBF7F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF701322) : const Color(0xFFEADBBE),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  occ,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF5A4A42),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Create Password Field Label
        Text(
          'Create a Password (Optional)',
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _createPasswordController,
          obscureText: _obscureCreatePassword,
          cursorColor: const Color(0xFF701322),
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF2C1810)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9F5EE),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.lock_outline_rounded, color: Color(0xFF701322), size: 21),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCreatePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF701322),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureCreatePassword = !_obscureCreatePassword),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
            hintText: 'e.g. at least 6 characters',
            hintStyle: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFFA0988A), fontWeight: FontWeight.normal),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEADBBE), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEADBBE), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF701322), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set a password to easily sign in with password next time.',
          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF8A7E74)),
        ),
        const SizedBox(height: 18),

        // Complete & Login Button (Pill Radius & Maroon Gradient)
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF701322), Color(0xFF8B1E2D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF701322).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleSaveNewUserProfile(isSkipped: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'Complete & Login ➔',
                    style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 8),

        // Skip Button
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () => _handleSaveNewUserProfile(isSkipped: true),
            child: Text(
              'Skip for now (I will fill later) ➔',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF8B5E00)),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
