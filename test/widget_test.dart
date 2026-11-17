import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plot_their_future/main.dart';
import 'package:plot_their_future/screens/home_screen.dart';
import 'package:plot_their_future/screens/login_screen.dart';
import 'package:plot_their_future/screens/profile_screen.dart';
import 'package:plot_their_future/screens/security_faq_screen.dart';
import 'package:plot_their_future/screens/marriage_registration_screen.dart';
import 'package:plot_their_future/screens/landing_page_screen.dart';
import 'package:plot_their_future/screens/admin_dashboard_screen.dart';
import 'package:plot_their_future/screens/floor_plan_screen.dart';
import 'package:plot_their_future/screens/host_dispatch_screen.dart';
import 'package:plot_their_future/models/api_user_model.dart';
import 'package:plot_their_future/services/api_service.dart';
import 'package:plot_their_future/services/local_marriage_storage_service.dart';
import 'package:plot_their_future/widgets/gift_sqft_sheet.dart';
import 'package:plot_their_future/widgets/guest_platform_spec_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  testWidgets('App loads and renders title test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PlotTheirFutureApp(),
      ),
    );
    await tester.pump();

    expect(find.text('PlotTheir'), findsWidgets);
    expect(find.text('Future'), findsWidgets);
  });

  testWidgets('App renders on narrow 320px screen without AppBar overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plot Their Future'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SecurityFaqScreen renders on narrow screen without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(340, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SecurityFaqScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WHAT HAPPENS TO YOUR MONEY?'), findsOneWidget);
    expect(find.text('1. Guest UPI'), findsOneWidget);
    expect(find.text('2. Bank Escrow'), findsOneWidget);
    expect(find.text('3. RERA Builder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GiftSqFtSheet bottom total bar renders without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(340, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GiftSqFtSheet(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TOTAL FOUNDATION GIFT'), findsOneWidget);
    expect(find.text('Gift & Mint Deed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GuestPlatformSpecSheet renders required platform spec and guest content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GuestPlatformSpecSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PlotTheirFuture'), findsWidgets);
    expect(find.text('APP CONTENT & PLATFORM SPEC'), findsOneWidget);
    expect(find.text('M/s PLOT THEIR FUTURE • Confidential & Proprietary'), findsOneWidget);
    expect(find.text('1. What is PlotTheirFuture?'), findsOneWidget);
    expect(find.text('2. For the Couple'), findsOneWidget);
    expect(find.text('3. For the Guest'), findsOneWidget);
    expect(find.text('“Celebrate the wedding. Build the future.”'), findsOneWidget);
    expect(find.text('Enter Wedding Registry as Guest ➔'), findsOneWidget);
  });

  testWidgets('LoginScreen renders clean professional branding and mobile input', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LoginScreen(onLoginSuccess: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PlotTheir'), findsWidgets);
    expect(find.text(' Future'), findsWidgets);
    expect(find.text('Sign In with Mobile'), findsOneWidget);
    expect(find.text('Verify ➔'), findsOneWidget);
  });

  testWidgets('Complete Login Flow: Mobile -> OTP -> Casual Profile (Skip) -> Logged-in Hub with Marriage Registration', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LoginScreen(onLoginSuccess: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Enter new user mobile number
    final phoneFinder = find.byType(TextField).first;
    await tester.enterText(phoneFinder, '+91 91234 56780');
    await tester.pump();

    // 2. Tap Send OTP
    final sendBtn = find.text('Verify ➔');
    await tester.ensureVisible(sendBtn);
    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    // Verify OTP step is visible
    expect(find.text('Verify 6-Digit OTP'), findsOneWidget);
    final verifyBtn = find.text('Verify & Continue ➔');
    expect(verifyBtn, findsOneWidget);

    // 3. Tap Verify OTP
    await tester.ensureVisible(verifyBtn);
    await tester.tap(verifyBtn);
    await tester.pumpAndSettle();

    // 4. New user casual profile setup appears
    expect(find.text('Welcome! Just a Quick Intro 🎉'), findsOneWidget);
    expect(find.text('Your Name / Couple Name *'), findsOneWidget);
    expect(find.text('What do you do? (Occupation)'), findsOneWidget);
    final skipBtn = find.text('Skip for now (I will fill later) ➔');
    expect(skipBtn, findsOneWidget);

    // 5. User taps Skip -> Navigates to HomeScreen!
    await tester.ensureVisible(skipBtn);
    await tester.tap(skipBtn);
    await tester.pumpAndSettle();

    // 6. User is routed to HomeScreen!
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Plot Their Future'), findsWidgets);

    // 7. Clicking the profile button opens ProfileScreen!
    final profileBtn = find.byKey(const Key('home_profile_button'));
    expect(profileBtn, findsOneWidget);
    await tester.tap(profileBtn);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('REGISTER FOR MARRIAGE'), findsOneWidget);
    expect(find.text('Start Marriage Registration (3 Steps) ➔'), findsOneWidget);
    expect(find.text('Enter Wedding Microsite & Registry ➔'), findsOneWidget);
  });

  testWidgets('Marriage Registration & Admin Workflow: Submit -> Admin Review -> Assign Flat & Approve', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Launch Marriage Registration Wizard
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MarriageRegistrationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Step 1: Couple & Contact Details
    expect(find.text('1. Couple & Contact Details'), findsOneWidget);
    expect(find.text('BRIDE DETAILS'), findsOneWidget);
    expect(find.text('GROOM DETAILS'), findsOneWidget);
    expect(find.text('ADMIN VERIFICATION CONTACTS'), findsOneWidget);

    // 2. Advance to Step 2: Wedding Card & Story
    final nextBtn1 = find.text('Next Step ➔');
    await tester.ensureVisible(nextBtn1);
    await tester.tap(nextBtn1);
    await tester.pumpAndSettle();

    expect(find.text('2. Wedding Card & Couple Story'), findsOneWidget);

    // 3. Advance to Step 3: Dynamic Ceremonies
    final nextBtn2 = find.text('Next Step ➔');
    await tester.ensureVisible(nextBtn2);
    await tester.tap(nextBtn2);
    await tester.pumpAndSettle();

    expect(find.text('3. Wedding Ceremonies & Functions'), findsOneWidget);
    expect(find.text('Haldi & Mangala Snanam'), findsOneWidget);
    expect(find.text('Wedding Muhurtham (Sumuhurtham)'), findsOneWidget);
    expect(find.text('Grand Wedding Reception'), findsOneWidget);

    // 4. Submit Registration
    final submitBtn = find.text('SUBMIT FOR ADMIN APPROVAL ➔');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify Confirmation Step
    expect(find.text('Marriage Registration Received!'), findsOneWidget);
    expect(find.text('STATUS: UNDER ADMIN REVIEW'), findsOneWidget);

    // 5. Open Admin Dashboard to test approval
    final openAdminBtn = find.text('Open Admin Dashboard & Approve Now ➔');
    await tester.ensureVisible(openAdminBtn);
    await tester.tap(openAdminBtn);
    await tester.pumpAndSettle();

    // Verify Admin Dashboard opens and shows pending tabs
    expect(find.text('Admin Moderation Console'), findsOneWidget);
    expect(find.text('Inspect & Assign Flat ➔'), findsWidgets);
  });

  testWidgets('Marriage Registration: Image Upload Modal & Custom Ceremony Name Entry', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MarriageRegistrationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Advance to Step 2: Wedding Card & Couple Cover Photo Upload
    final nextBtn1 = find.text('Next Step ➔');
    await tester.ensureVisible(nextBtn1);
    await tester.tap(nextBtn1);
    await tester.pumpAndSettle();

    // Verify Image Upload sections exist and NO raw URL text field exists
    expect(find.text('Digital Wedding Card Invitation *'), findsOneWidget);
    expect(find.text('Couple Cover Photo / Portrait *'), findsOneWidget);
    expect(find.text('Wedding Card URL or Cloud PDF link'), findsNothing);

    // Tap Select & Upload for Wedding Card to open Image Upload Modal
    final uploadBtn = find.text('Upload Invitation');
    expect(uploadBtn, findsOneWidget);
    await tester.tap(uploadBtn);
    await tester.pumpAndSettle();

    // Verify Image Upload Sheet opened with Camera, Gallery, and Files
    expect(find.text('Take Photo with Camera'), findsOneWidget);
    expect(find.text('Choose from Photo Gallery'), findsOneWidget);
    expect(find.text('Browse Files & PDF Documents'), findsOneWidget);

    // Select Gallery source
    final galleryOption = find.text('Choose from Photo Gallery');
    await tester.tap(galleryOption);
    await tester.pumpAndSettle();

    // Clear any transient snackbar to ensure buttons are clickable
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pumpAndSettle();

    // 2. Advance to Step 3: Ceremonies & Custom Ceremony Name
    final nextBtn2 = find.text('Next Step ➔');
    await tester.ensureVisible(nextBtn2);
    await tester.tap(nextBtn2);
    await tester.pumpAndSettle();

    // Tap "Add Another Custom Ceremony ➔"
    final addCustomBtn = find.text('Add Another Custom Ceremony ➔');
    await tester.ensureVisible(addCustomBtn);
    await tester.tap(addCustomBtn);
    await tester.pumpAndSettle();

    // Verify Custom Ceremony Name input & suggestions are visible
    expect(find.text('Custom Ceremony / Function Name *'), findsOneWidget);
    expect(find.text('Pellikoduku'), findsOneWidget);
    expect(find.text('Engagement Ceremony'), findsOneWidget);

    // Tap suggestion chip Pellikoduku
    final pellikodukuChip = find.text('Pellikoduku');
    await tester.ensureVisible(pellikodukuChip);
    await tester.tap(pellikodukuChip);
    await tester.pumpAndSettle();

    // Header now reflects the custom ceremony name
    expect(find.text('Pellikoduku'), findsWidgets);
  });

  testWidgets('Marriage Registration: Input boxes start empty and ceremony details validation enforces entry', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MarriageRegistrationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify all input fields start empty without dummy text
    final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    for (final field in textFields) {
      expect(field.controller?.text ?? '', isEmpty);
    }

    // 2. Advance to Step 2
    final nextBtn1 = find.text('Next Step ➔');
    await tester.ensureVisible(nextBtn1);
    await tester.tap(nextBtn1);
    await tester.pumpAndSettle();

    // 3. Advance to Step 3 (Ceremonies)
    final nextBtn2 = find.text('Next Step ➔');
    await tester.ensureVisible(nextBtn2);
    await tester.tap(nextBtn2);
    await tester.pumpAndSettle();

    // 4. Toggle ON Reception ceremony (which starts with empty venue)
    final switches = find.byType(Switch);
    expect(switches, findsWidgets);

    // Scroll to Reception switch and toggle ON
    await tester.ensureVisible(switches.at(4));
    await tester.tap(switches.at(4));
    await tester.pumpAndSettle();

    // Verify it opened the Edit Ceremony Details sheet because details are required
    expect(find.text('Edit Ceremony Details'), findsOneWidget);
    expect(find.text('Venue Name *'), findsOneWidget);
    expect(find.text('Venue Address *'), findsOneWidget);

    // Close the sheet without entering venue name
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Now attempt to proceed via Save & Continue ➔
    final saveBtn = find.text('Save & Continue ➔');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify validation blocked navigation and re-opened the Edit Ceremony Details sheet
    expect(find.text('Edit Ceremony Details'), findsOneWidget);
    expect(find.text('Marriage Registration Received!'), findsNothing);
  });

  test('Session Persistence & Role-Based Auth: User & Admin lifecycle', () async {
    // 0. Mock platform channel for SharedPreferences in test environment
    SharedPreferences.setMockInitialValues({});

    // 1. Initialize API Service
    await ApiService.instance.init();

    // 2. Clear any residual session
    ApiService.instance.clearSession();
    expect(ApiService.instance.isAuthenticated, isFalse);
    expect(ApiService.instance.currentSession, isNull);

    // 3. Admin login with password
    final adminSession = await ApiService.instance.loginWithPassword(
      mobileNumber: '+919848012345',
      password: 'AdminPassword123!',
    );
    expect(adminSession.user.role, 'ADMIN');
    expect(ApiService.instance.isAuthenticated, isTrue);

    // 4. Test User creation API
    final newUser = await ApiService.instance.createUser(
      name: 'Aditya Rao',
      mobileNumber: '+919988776655',
      role: 'ROLE_USER',
      occupation: 'Architect',
    );
    expect(newUser, isNotNull);
    expect(newUser!.name, 'Aditya Rao');
    expect(newUser.role, 'ROLE_USER');

    // 5. Test Profile Update
    final updatedUser = await ApiService.instance.updateUserProfile(
      userId: 1,
      name: 'Sanvi Reddy Updated',
      occupation: 'Lead Solutions Architect',
    );
    expect(updatedUser, isNotNull);
    expect(updatedUser!.name, 'Sanvi Reddy Updated');

    // 6. Test fetch me
    final me = await ApiService.instance.getMe();
    expect(me, isNotNull);
    expect(me!.name, 'Sanvi Reddy Updated');

    // 7. Test Logout / Clear session
    ApiService.instance.clearSession();
    expect(ApiService.instance.isAuthenticated, isFalse);
    expect(ApiService.instance.currentSession, isNull);
  });

  testWidgets('LoginScreen toggles between Dynamic OTP and Password Login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.instance.init();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(onLoginSuccess: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial view shows "Sign In with Mobile" and "Login with Password ➔" button
    expect(find.text('Sign In with Mobile'), findsOneWidget);
    expect(find.text('Login with Password ➔'), findsOneWidget);

    // 2. Tap "Login with Password ➔"
    final passwordToggle = find.text('Login with Password ➔');
    await tester.ensureVisible(passwordToggle);
    await tester.tap(passwordToggle);
    await tester.pumpAndSettle();

    // 3. View toggles to "Sign In with Password" with Password input field
    expect(find.text('Sign In with Password'), findsOneWidget);
    expect(find.text('Password *'), findsOneWidget);
    expect(find.text('← Sign In with Dynamic OTP instead'), findsOneWidget);

    // 4. Tap "← Sign In with Dynamic OTP instead"
    final otpToggle = find.text('← Sign In with Dynamic OTP instead');
    await tester.ensureVisible(otpToggle);
    await tester.tap(otpToggle);
    await tester.pumpAndSettle();

    // 5. Returns to "Sign In with Mobile"
    expect(find.text('Sign In with Mobile'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders Edit Profile button and Tax Exemption info dialog', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.instance.init();

    // Set logged-in session
    ApiService.instance.setSession(
      const AuthSession(
        token: 'test-token',
        expiresIn: 604800,
        user: ApiUser(
          id: 1,
          name: 'Sanvi Reddy',
          mobileNumber: '+919848012345',
          role: 'ADMIN',
          registered: true,
          occupation: 'Senior Software Architect',
        ),
        accessibleWeddings: ['sanvi-santosh'],
        message: 'Auth ok',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Edit Profile buttons are rendered
    expect(find.byKey(const Key('account_edit_profile_button')), findsOneWidget);
    expect(find.byKey(const Key('hero_edit_profile_button')), findsOneWidget);

    // Verify Tax Exemption Status is rendered
    expect(find.text('Tax Exemption Status'), findsOneWidget);
    expect(find.text('Sec 56(2)(x) 100% Tax-Free Compliant'), findsOneWidget);

    // Tap Edit Profile button to open bottom sheet
    final editBtn = find.byKey(const Key('account_edit_profile_button'));
    await tester.ensureVisible(editBtn);
    await tester.tap(editBtn);
    await tester.pumpAndSettle();

    // Verify Edit Profile Dossier modal content
    expect(find.text('Edit Profile Dossier'), findsOneWidget);
    expect(find.text('Create / Change Password (Optional)'), findsOneWidget);
    expect(find.text('Save Profile Changes ➔'), findsOneWidget);
  });

  testWidgets('LandingPageScreen renders on narrow mobile screens (320px and 360px) without any RenderFlex overflow', (WidgetTester tester) async {
    for (final width in [320.0, 360.0, 390.0, 412.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LandingPageScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow exception occurred
      expect(tester.takeException(), isNull, reason: 'Overflow occurred on width: $width');

      // Verify Brand elements exist
      expect(find.text('PlotTheir'), findsWidgets);
      expect(find.text('Future'), findsWidgets);

      // Verify Navigation Links
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('For Couple'), findsOneWidget);
      expect(find.text('For Guest'), findsOneWidget);

      // Verify Hero typography
      expect(find.text('The wedding gift'), findsOneWidget);
      expect(find.text('that becomes their'), findsOneWidget);
      expect(find.text('forever.'), findsOneWidget);

      // Verify Section Headings
      expect(find.text('What is PlotTheirFuture?'), findsOneWidget);
      expect(find.text('For the Couple'), findsOneWidget);
      expect(find.text('For the Guest'), findsOneWidget);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Admin Panel: Flat Management, Analytics KPIs, and Transactions Module Navigation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.instance.init();

    // Set logged-in ADMIN session
    ApiService.instance.setSession(
      const AuthSession(
        token: 'admin-test-token',
        expiresIn: 604800,
        user: ApiUser(
          id: 1,
          name: 'Platform Administrator',
          mobileNumber: '+919999999999',
          role: 'ADMIN',
          registered: true,
          occupation: 'Curator',
        ),
        accessibleWeddings: ['sanvi-santosh', 'rahul-sneha'],
        message: 'Admin authenticated',
      ),
    );

    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial Module: Submissions
    expect(find.text('Admin Moderation Console'), findsOneWidget);
    expect(find.text('Submissions'), findsWidgets);
    expect(find.text('Flat Management'), findsWidgets);
    expect(find.text('Weddings'), findsWidgets);
    expect(find.text('Analytics'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);

    // 2. Switch to Flat Management Module
    final flatMgmtPill = find.text('Flat Management').first;
    await tester.ensureVisible(flatMgmtPill);
    await tester.tap(flatMgmtPill);
    await tester.pumpAndSettle();

    expect(find.text('Register Flat'), findsOneWidget);
    expect(find.text('Search flats by name, ID, or location...'), findsOneWidget);

    // 3. Switch to Weddings Module
    final weddingsPill = find.text('Weddings').first;
    await tester.ensureVisible(weddingsPill);
    await tester.tap(weddingsPill);
    await tester.pumpAndSettle();

    expect(find.text('Wedding Campaigns & Flat Assignments'), findsOneWidget);

    // 4. Switch to Analytics Module
    final analyticsPill = find.text('Analytics').first;
    await tester.ensureVisible(analyticsPill);
    await tester.tap(analyticsPill);
    await tester.pumpAndSettle();

    expect(find.text('Platform Portfolio & Gifting KPI Metrics'), findsOneWidget);
    expect(find.text('Total Gift Amount'), findsOneWidget);
    expect(find.text('Section-wise Gifting Distribution'), findsOneWidget);

    // 5. Switch to Transactions Module
    final transactionsPill = find.text('Transactions').first;
    await tester.ensureVisible(transactionsPill);
    await tester.tap(transactionsPill);
    await tester.pumpAndSettle();

    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Search by guest name, mobile, or reference ID...'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Flat Registration BottomSheet: Starts empty without dummy data, uses image selection modal', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.instance.init();

    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Switch to Flat Management
    final flatMgmtPill = find.text('Flat Management').first;
    await tester.ensureVisible(flatMgmtPill);
    await tester.tap(flatMgmtPill);
    await tester.pumpAndSettle();

    // 2. Open Register Flat bottom sheet
    final registerBtn = find.text('Register Flat').first;
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    // Verify BottomSheet opened
    expect(find.text('Register New Flat'), findsWidgets);
    expect(find.text('Step 1 of 5 • Basic Flat Information'), findsOneWidget);

    // 3. Advance to Step 2: Photos & Gallery
    final nextBtn = find.text('Next Step ➔');
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    expect(find.text('Primary Flat Cover Photo'), findsOneWidget);
    expect(find.text('Tap to Select & Upload Cover Photo'), findsOneWidget);
    // Verify no raw URL text field exists
    expect(find.text('Cover Image URL / Asset Path'), findsNothing);

    // Tap cover dropzone to open Image Picker Modal
    final uploadTile = find.text('Tap to Select & Upload Cover Photo');
    await tester.tap(uploadTile);
    await tester.pumpAndSettle();

    expect(find.text('Upload Flat Cover Photo'), findsOneWidget);
    expect(find.text('Take Photo with Camera'), findsOneWidget);
    expect(find.text('Choose from Photo Gallery'), findsOneWidget);
    expect(find.text('Modern Tower (Bhooja)'), findsOneWidget);

    // Pick preset
    await tester.tap(find.text('Modern Tower (Bhooja)'));
    await tester.pumpAndSettle();

    expect(find.text('Cover Photo Selected'), findsOneWidget);

    // 4. Advance to Step 3: Room Templates & SFT Area
    await tester.tap(find.text('Next Step ➔'));
    await tester.pumpAndSettle();

    // Verify rooms are auto-generated from Step 1 counts
    expect(find.text('Master Bedroom'), findsOneWidget);
    expect(find.text('Hall / Living Room'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);

    // 5. Advance to Step 4: Pricing & Bricks
    await tester.tap(find.text('Next Step ➔'));
    await tester.pumpAndSettle();
    expect(find.text('Automatic Conversion Matrix'), findsOneWidget);

    // 6. Advance to Step 5: Review & Submit (Verify zero pixel overflow on narrow mobile screen)
    await tester.tap(find.text('Next Step ➔'));
    await tester.pumpAndSettle();

    expect(find.text('Review Flat Configuration'), findsOneWidget);
    expect(find.text('Submit for Approval ➔'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin Dossier Sheet: Displays Wedding Media, Ceremonies, and Flat Inventory Dropdown', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ApiService.instance.init();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Admin Dashboard Submissions tab is loaded
    expect(find.text('Submissions'), findsWidgets);

    // Tap on the first pending/review submission dossier to open detail modal sheet
    final reviewBtn = find.text('Inspect & Assign Flat ➔').first;
    await tester.ensureVisible(reviewBtn);
    await tester.tap(reviewBtn);
    await tester.pumpAndSettle();

    // 1. Verify Section 1: Contact Dossier & Verification
    expect(find.text('1. CONTACT DOSSIER & VERIFICATION'), findsOneWidget);

    // 2. Verify Section 2: Wedding Media & Invitations Showcase
    expect(find.text('2. WEDDING MEDIA & INVITATIONS'), findsOneWidget);
    expect(find.text('Couple Photo / Portrait Banner'), findsOneWidget);
    expect(find.text('Official Digital Wedding Invitation Card'), findsOneWidget);
    expect(find.text('Wedding Reel Video / Live Stream'), findsOneWidget);

    // 3. Verify Section 3: Ceremony Itinerary
    expect(find.textContaining('3. CEREMONY ITINERARY'), findsOneWidget);

    // 4. Verify Section 4: Real Estate Flat Allocation
    expect(find.text('4. REAL ESTATE FLAT ALLOCATION'), findsOneWidget);
    expect(find.text('APPROVE & ATTACH FLAT UNIT ➔'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('FloorPlanScreen: Loads Assigned Flat specs, Escrow details, and Dynamic Section modules without dummy data', (WidgetTester tester) async {
    LocalMarriageStorageService.instance.seedInitialSubmissionsForTest();
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FloorPlanScreen(weddingSlug: 'sanvi-santosh', showAppBar: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Brand title in header
    expect(find.text('PlotTheir'), findsWidgets);
    expect(find.text('Future'), findsWidgets);

    // Verify Verified Assigned Flat details
    expect(find.text('ASSIGNED FLAT VERIFIED'), findsOneWidget);
    expect(find.textContaining('Santosh & Sanvi'), findsWidgets);
    expect(find.textContaining('Prestige Lakeside Habitat'), findsOneWidget);
    expect(find.textContaining('1,200 Sq.Ft.'), findsOneWidget);

    // Verify Section-Wise Gifting without hardcoded dummy couple text
    expect(find.text('Select a Section to Gift'), findsOneWidget);
    expect(find.textContaining("Santosh & Sanvi's future home"), findsOneWidget);
    expect(find.text('Select Area to Gift'), findsOneWidget);
    expect(find.text('Gift This Space'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('HostDispatchScreen: Loads Approved Wedding, Guest Contacts, Custom Ceremony Passes, and Backend Dispatch', (WidgetTester tester) async {
    LocalMarriageStorageService.instance.seedInitialSubmissionsForTest();
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HostDispatchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Brand title & Header
    expect(find.text('Send Wedding Invitations'), findsOneWidget);
    expect(find.text('APPROVED WEDDING'), findsOneWidget);
    expect(find.textContaining('Santosh & Sanvi'), findsOneWidget);

    // Verify Ceremonies selection
    expect(find.text('Select Events'), findsOneWidget);
    expect(find.text('Import & Select Guest Contacts'), findsOneWidget);

    // Verify imported / seeded contacts
    expect(find.text('Venkatesh Rao (Uncle)'), findsOneWidget);
    expect(find.text('Ananya Sharma'), findsOneWidget);
    expect(find.text('Invited Ceremonies:'), findsWidgets);

    // Verify Action Buttons
    expect(find.text('Send Invitations & Sync Backend'), findsOneWidget);
    expect(find.text('Send WhatsApp Broadcast'), findsOneWidget);

    // Tap Send Invitations & Sync Backend to trigger backend update
    final syncBtn = find.text('Send Invitations & Sync Backend');
    await tester.ensureVisible(syncBtn);
    await tester.tap(syncBtn);
    await tester.pumpAndSettle();

    // Verify confirmation modal
    expect(find.text('Invitations Dispatched!'), findsOneWidget);
    expect(find.textContaining('Successfully recorded and synced'), findsOneWidget);

    final doneBtn = find.text('Done');
    await tester.tap(doneBtn);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
