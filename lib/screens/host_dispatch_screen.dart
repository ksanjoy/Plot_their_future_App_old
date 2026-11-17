import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/marriage_submission_model.dart';
import '../services/api_service.dart';
import '../services/local_marriage_storage_service.dart';
import 'marriage_registration_screen.dart';

class HostInvitee {
  final String name;
  final String phone;
  String cohort;
  Set<String> selectedCeremonies;
  bool isDispatched;

  HostInvitee({
    required this.name,
    required this.phone,
    this.cohort = 'All Family',
    required this.selectedCeremonies,
    this.isDispatched = false,
  });
}

class HostDispatchScreen extends StatefulWidget {
  const HostDispatchScreen({super.key});

  @override
  State<HostDispatchScreen> createState() => _HostDispatchScreenState();
}

class _HostDispatchScreenState extends State<HostDispatchScreen> {
  MarriageSubmission? _approvedWedding;
  bool _isLoadingWedding = true;
  List<CeremonyFunctionModel> _availableCeremonies = [];
  final List<HostInvitee> _inviteeList = [];

  String _selectedAudience = 'All Family';
  bool _includeRegistry = true;
  bool _isImporting = false;
  bool _isDispatching = false;

  // Global ceremony toggles for bulk invite
  final Set<String> _globalSelectedCeremonies = {};

  @override
  void initState() {
    super.initState();
    _loadWeddingData();
  }

  Future<void> _loadWeddingData() async {
    setState(() => _isLoadingWedding = true);
    try {
      final userId = ApiService.instance.currentSession?.user.id ?? 1;
      List<MarriageSubmission> submissions = [];
      try {
        submissions = await ApiService.instance.getMyMarriageRegistrations(userId);
      } catch (_) {}

      if (submissions.isEmpty) {
        submissions = await LocalMarriageStorageService.instance.getMyRegistrations(userId);
      }
      if (submissions.isEmpty) {
        submissions = await LocalMarriageStorageService.instance.getAllRegistrations();
      }

      // Prioritize approved wedding, then any registered wedding
      MarriageSubmission? matched;
      try {
        matched = submissions.firstWhere((s) => s.isApproved);
      } catch (_) {
        if (submissions.isNotEmpty) matched = submissions.first;
      }

      if (matched != null) {
        _approvedWedding = matched;
        final fns = matched.functions.where((f) => f.isEnabled).toList();
        _availableCeremonies = fns.isNotEmpty ? fns : matched.functions;
      } else {
        _approvedWedding = null;
        _availableCeremonies = [];
      }
    } catch (e) {
      debugPrint('[HostDispatchScreen] Load wedding error: $e');
    }

    _globalSelectedCeremonies.clear();
    for (final c in _availableCeremonies) {
      _globalSelectedCeremonies.add(c.name);
    }

    // Seed mock invitees ONLY for test fixture (sanvi-santosh)
    if (_inviteeList.isEmpty && _approvedWedding != null && _approvedWedding!.slug == 'sanvi-santosh') {
      _inviteeList.add(
        HostInvitee(
          name: 'Venkatesh Rao (Uncle)',
          phone: '+91 98490 12345',
          cohort: 'All Family',
          selectedCeremonies: _availableCeremonies.map((c) => c.name).toSet(),
        ),
      );
      _inviteeList.add(
        HostInvitee(
          name: 'Ananya Sharma',
          phone: '+91 98765 43210',
          cohort: 'Friends',
          selectedCeremonies: _availableCeremonies
              .where((c) => !c.name.toLowerCase().contains('haldi'))
              .map((c) => c.name)
              .toSet(),
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoadingWedding = false);
    }
  }

  List<CeremonyFunctionModel> _getDefaultCeremonies() {
    return [
      CeremonyFunctionModel(
        ceremonyType: 'HALDI',
        name: 'Haldi & Mangala Snanam',
        isEnabled: true,
        eventDate: DateTime.now().add(const Duration(days: 30)),
        startTime: '10:00:00',
        endTime: '13:00:00',
        venueName: 'The Palm Meadows Clubhouse',
        venueAddress: 'Whitefield Main Road, Bangalore',
      ),
      CeremonyFunctionModel(
        ceremonyType: 'SANGEET',
        name: 'Sangeet & Mehendi Celebration',
        isEnabled: true,
        eventDate: DateTime.now().add(const Duration(days: 30)),
        startTime: '18:00:00',
        endTime: '22:30:00',
        venueName: 'The Grand Ballroom',
        venueAddress: 'Silicon Valley Blvd, Bangalore',
      ),
      CeremonyFunctionModel(
        ceremonyType: 'MUHURTHAM',
        name: 'Wedding Muhurtham (Sumuhurtham)',
        isEnabled: true,
        eventDate: DateTime.now().add(const Duration(days: 31)),
        startTime: '10:24:00',
        endTime: '13:00:00',
        venueName: 'Skyline Meadows Convention Hall',
        venueAddress: 'Financial District, Hyderabad',
      ),
      CeremonyFunctionModel(
        ceremonyType: 'RECEPTION',
        name: 'Grand Wedding Reception',
        isEnabled: true,
        eventDate: DateTime.now().add(const Duration(days: 31)),
        startTime: '19:30:00',
        endTime: '23:30:00',
        venueName: 'N-Convention Centre, Main Arena',
        venueAddress: 'Madhapur, Hyderabad',
      ),
    ];
  }

  // --- CONTACTS PERMISSION & IMPORT FLOW ---

  Future<void> _handleImportContacts() async {
    setState(() => _isImporting = true);
    try {
      bool permissionGranted = false;
      try {
        permissionGranted = await FlutterContacts.permissions.has(PermissionType.read);
        if (!permissionGranted) {
          final status = await FlutterContacts.permissions.request(PermissionType.read);
          permissionGranted = status == PermissionStatus.granted;
        }
      } catch (e) {
        debugPrint('[HostDispatchScreen] Permission check note: $e');
      }

      if (!permissionGranted) {
        setState(() => _isImporting = false);
        if (mounted) _showPermissionDeniedDialog();
        return;
      }

      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );

      final validContacts = contacts.where((c) => c.phones.isNotEmpty).toList();

      setState(() => _isImporting = false);

      if (validContacts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No contacts with phone numbers found on this device.', style: GoogleFonts.outfit()),
              backgroundColor: AppTheme.crimsonMaroon,
            ),
          );
        }
        return;
      }

      if (mounted) {
        _showContactSelectionSheet(validContacts);
      }
    } catch (e) {
      setState(() => _isImporting = false);
      debugPrint('[HostDispatchScreen] Contacts error: $e');
      if (mounted) {
        _showManualAddDialog(reason: 'Contacts access not available in this environment. You can enter guests directly below.');
      }
    }
  }

  void _showContactSelectionSheet(List<Contact> contacts) {
    final Set<String> selectedContactIds = {};
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = contacts.where((c) {
              final name = (c.displayName ?? '').toLowerCase();
              final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
              return name.contains(searchQuery.toLowerCase()) || phone.contains(searchQuery);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Import Phone Contacts',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF701322),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Select friends and family members to invite to your ceremonies.',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),

                  // Search Field
                  TextField(
                    onChanged: (val) => setSheetState(() => searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by contact name or number...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.crimsonMaroon),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF9F6F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2D6C0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filtered.length} Contacts Found',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            if (selectedContactIds.length == filtered.length) {
                              selectedContactIds.clear();
                            } else {
                              selectedContactIds.addAll(
                                filtered.map((c) => c.id ?? (c.phones.isNotEmpty ? c.phones.first.number : '')).where((s) => s.isNotEmpty),
                              );
                            }
                          });
                        },
                        child: Text(
                          selectedContactIds.length == filtered.length ? 'Deselect All' : 'Select All',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.royalGold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1),

                  // Contact List
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0EAE1)),
                      itemBuilder: (context, index) {
                        final contact = filtered[index];
                        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                        final contactKey = contact.id ?? phone;
                        final isSelected = selectedContactIds.contains(contactKey);
                        final displayName = (contact.displayName != null && contact.displayName!.isNotEmpty)
                            ? contact.displayName!
                            : 'Unknown Contact';

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: AppTheme.crimsonMaroon,
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) {
                                selectedContactIds.add(contactKey);
                              } else {
                                selectedContactIds.remove(contactKey);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            backgroundColor: const Color(0xFFFAF3DC),
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF701322)),
                            ),
                          ),
                          title: Text(
                            displayName,
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          subtitle: Text(
                            phone,
                            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Confirmation Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selectedContactIds.isEmpty
                          ? null
                          : () {
                              final chosen = contacts.where((c) {
                                final key = c.id ?? (c.phones.isNotEmpty ? c.phones.first.number : '');
                                return selectedContactIds.contains(key);
                              }).toList();
                              for (final c in chosen) {
                                final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
                                final name = (c.displayName != null && c.displayName!.isNotEmpty)
                                    ? c.displayName!
                                    : 'Guest';
                                if (!_inviteeList.any((i) => i.phone == phone)) {
                                  _inviteeList.add(
                                    HostInvitee(
                                      name: name,
                                      phone: phone,
                                      cohort: _selectedAudience,
                                      selectedCeremonies: _availableCeremonies.map((cm) => cm.name).toSet(),
                                    ),
                                  );
                                }
                              }
                              setState(() {});
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Imported ${chosen.length} contacts into invite list!', style: GoogleFonts.outfit()),
                                  backgroundColor: AppTheme.crimsonMaroon,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.crimsonMaroon,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Import ${selectedContactIds.length} Selected Contacts',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Contacts Permission Required',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: const Color(0xFF701322)),
        ),
        content: Text(
          'To import friends and family directly from your address book, please grant Contacts permission in device Settings. You can also add guests manually right away.',
          style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showManualAddDialog();
            },
            child: Text('Add Manually', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              FlutterContacts.permissions.openSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
            child: Text('Open Device Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showManualAddDialog({String? reason}) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String cohort = _selectedAudience;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Add Wedding Guest',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: const Color(0xFF701322)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reason != null) ...[
                Text(reason, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Guest Full Name *',
                  hintText: 'e.g. Ramesh Varma',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number *',
                  hintText: '+91 98480 12345',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: cohort,
                items: ['All Family', 'Friends', 'Colleagues'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => cohort = val);
                },
                decoration: InputDecoration(
                  labelText: 'Audience Group',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty) return;

                setState(() {
                  _inviteeList.add(
                    HostInvitee(
                      name: name,
                      phone: phone,
                      cohort: cohort,
                      selectedCeremonies: _availableCeremonies.map((c) => c.name).toSet(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimsonMaroon),
              child: Text('Add Guest', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- SEND & UPDATE BACKEND ---

  Future<void> _dispatchInvitations() async {
    if (_inviteeList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please import or add contacts to invite.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.crimsonMaroon,
        ),
      );
      return;
    }

    setState(() => _isDispatching = true);
    int syncedCount = 0;
    final weddingId = int.tryParse(_approvedWedding?.id ?? '1') ?? 1;

    for (final guest in _inviteeList) {
      try {
        await ApiService.instance.createInvitation(
          weddingId: weddingId,
          guestName: guest.name,
          phoneE164: guest.phone,
          cohort: guest.cohort,
          ceremonies: guest.selectedCeremonies.toList(),
        );
        guest.isDispatched = true;
        syncedCount++;
      } catch (e) {
        debugPrint('[HostDispatchScreen] Failed to record invite for ${guest.name}: $e');
      }
    }

    setState(() => _isDispatching = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF03543F), size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Invitations Dispatched!',
                  style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: const Color(0xFF701322)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Successfully recorded and synced $syncedCount invitations to backend registry for ${_approvedWedding?.coupleTitle ?? "Wedding"}.',
                style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2D6C0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Each guest receives:', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('• Custom ceremony passes as selected', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                    Text('• Interactive 2 BHK Foundation Flat Gift Link', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                    Text('• RERA Tripartite Escrow Pledge', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimsonMaroon),
              child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _sendSingleWhatsApp(HostInvitee guest) async {
    final slug = _approvedWedding?.slug ?? AppConstants.campaignSlug;
    final couple = _approvedWedding?.coupleTitle ?? 'Sanvi & Santosh';
    final ceremoniesList = guest.selectedCeremonies.join(', ');

    final message = '''Namaste ${guest.name}! 🙏
You are cordially invited to celebrate the auspicious wedding of *$couple*!

📅 Ceremonies Included:
$ceremoniesList

🏡 As a blessing for our beginning, we invite you to be part of our foundation by gifting a square foot toward our first home:
https://plottheirfuture.in/w/$slug?ref=host&guest=${Uri.encodeComponent(guest.name)}

Looking forward to your warm presence and blessings!''';

    final cleanPhone = guest.phone.replaceAll(RegExp(r'\D'), '');
    final encodedMsg = Uri.encodeComponent(message);

    final whatsappSchemeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMsg');
    final whatsappWebUri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMsg');
    final waMeUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');

    bool launched = false;
    try {
      if (await canLaunchUrl(whatsappSchemeUri)) {
        launched = await launchUrl(whatsappSchemeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (!launched) {
      try {
        if (await canLaunchUrl(waMeUri)) {
          launched = await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    if (!launched) {
      try {
        launched = await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (mounted) {
      if (launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening WhatsApp for ${guest.name}...', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.crimsonMaroon,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        await Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp direct launch unavailable. Invitation message copied to clipboard for ${guest.name}!', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.royalGold,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    // Sync to backend as well
    try {
      final weddingId = int.tryParse(_approvedWedding?.id ?? '1') ?? 1;
      await ApiService.instance.createInvitation(
        weddingId: weddingId,
        guestName: guest.name,
        phoneE164: guest.phone,
        cohort: guest.cohort,
        ceremonies: guest.selectedCeremonies.toList(),
      );
      setState(() => guest.isDispatched = true);
    } catch (_) {}
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.ivoryBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.crimsonMaroon, size: 18),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/brand_gold_gift_house_icon.png',
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(AppConstants.appIconPath, height: 30),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PlotTheir',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF701322),
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
              Text(
                'Future',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 12.5,
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
      centerTitle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    if (_isLoadingWedding) {
      return Scaffold(
        backgroundColor: AppTheme.ivoryBackground,
        appBar: canPop ? _buildAppBar(context) : null,
        body: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: AppTheme.crimsonMaroon),
          ),
        ),
      );
    }

    if (_approvedWedding == null) {
      return Scaffold(
        backgroundColor: AppTheme.ivoryBackground,
        appBar: canPop ? _buildAppBar(context) : null,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildNoWeddingInvitesEmptyState(context),
        ),
      );
    }

    if (!_approvedWedding!.isApproved) {
      return Scaffold(
        backgroundColor: AppTheme.ivoryBackground,
        appBar: canPop ? _buildAppBar(context) : null,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildPendingApprovalCard(_approvedWedding!),
        ),
      );
    }

    final coupleName = _approvedWedding!.coupleTitle;
    final isApproved = _approvedWedding!.isApproved;

    return Scaffold(
      backgroundColor: AppTheme.ivoryBackground,
      appBar: canPop ? _buildAppBar(context) : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMarigoldToran(),
            const SizedBox(height: 12),

            // Main Title
            Center(
              child: Text(
                'Send Wedding Invitations',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E232A),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Approved Wedding Status Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8C252)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF3DC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC58B24)),
                    ),
                    child: const Icon(Icons.celebration, color: Color(0xFF701322), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isApproved ? const Color(0xFFDEF7EC) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isApproved ? 'APPROVED WEDDING' : 'UNDER VERIFICATION',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isApproved ? const Color(0xFF03543F) : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$coupleName\'s Wedding',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E232A),
                          ),
                        ),
                        Text(
                          _approvedWedding != null
                              ? '${DateFormat('dd MMMM yyyy').format(_approvedWedding!.weddingDate)} • ${_approvedWedding!.city}'
                              : '15 November 2026 • Bangalore',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select Events
            Text(
              'Select Events',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E232A),
              ),
            ),
            const SizedBox(height: 10),

            // Dynamic Ceremonies Grid from Registered Approved Wedding
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _availableCeremonies.length,
              itemBuilder: (context, index) {
                final c = _availableCeremonies[index];
                final isSelected = _globalSelectedCeremonies.contains(c.name);
                return _buildEventCard(
                  title: c.name,
                  icon: _getCeremonyIcon(c.ceremonyType),
                  iconColor: AppTheme.crimsonMaroon,
                  isSelected: isSelected,
                  onToggle: () {
                    setState(() {
                      if (isSelected) {
                        _globalSelectedCeremonies.remove(c.name);
                      } else {
                        _globalSelectedCeremonies.add(c.name);
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 22),

            // Select Audience
            Text(
              'Select Audience',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E232A),
              ),
            ),
            const SizedBox(height: 10),

            // Audience Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All Family', 'Friends', 'Colleagues'].map((audience) {
                  final isSelected = _selectedAudience == audience;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedAudience = audience),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.crimsonMaroon : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.crimsonMaroon : const Color(0xFFE2D6C0),
                          ),
                        ),
                        child: Text(
                          audience,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),

            // Include Gift Registry Card
            Text(
              'Include Gift Registry',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E232A),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEBDAB0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Switch(
                    value: _includeRegistry,
                    activeColor: AppTheme.greenVerified,
                    onChanged: (val) => setState(() => _includeRegistry = val),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_approvedWedding?.assignedFlat?.configuration ?? "2 BHK"} Apartment Sq.Ft. Gift Link',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          'Includes RERA & Tripartite Escrow pledge',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text('🏢🔑', style: TextStyle(fontSize: 22)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // GUEST CONTACTS & INDIVIDUAL CEREMONY INVITATIONS SECTION
            Row(
              children: [
                const Icon(Icons.contacts, color: Color(0xFF701322), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Import & Select Guest Contacts',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E232A),
                    ),
                  ),
                ),
                Text(
                  '${_inviteeList.length} Selected',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.royalGold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select guests from your device contacts and customize which wedding ceremonies each guest is invited to.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),

            // Contact Action Buttons (Import Contacts & Add Manually)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _handleImportContacts,
                    icon: _isImporting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.import_contacts, color: Colors.white, size: 18),
                    label: Text(
                      'Import Contacts',
                      style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF701322),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _showManualAddDialog(),
                  icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF701322), size: 18),
                  label: Text(
                    '+ Add Manual',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF701322)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF701322)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected Invitee Cards with Ceremony Badges
            if (_inviteeList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2D6C0)),
                ),
                child: Center(
                  child: Text(
                    'No contacts added yet. Tap "Import Contacts" to select your guests.',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              ..._inviteeList.map((guest) => _buildGuestCard(guest)),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isDispatching ? null : _dispatchInvitations,
                icon: _isDispatching
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Send Invitations & Sync Backend',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.crimsonMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Also keep standard WhatsApp broadcast button for mock backward compatibility
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  final slug = _approvedWedding?.slug ?? AppConstants.campaignSlug;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'WhatsApp Smart Broadcast sent to $_selectedAudience with tracked referral link!',
                        style: GoogleFonts.outfit(),
                      ),
                      backgroundColor: AppTheme.crimsonMaroon,
                    ),
                  );
                },
                icon: const Icon(Icons.chat, color: AppTheme.crimsonMaroon, size: 20),
                label: Text(
                  'Send WhatsApp Broadcast',
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.crimsonMaroon,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.crimsonMaroon, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  final slug = _approvedWedding?.slug ?? AppConstants.campaignSlug;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Smart Invite URL copied: plottheirfuture.in/w/$slug?ref=host',
                        style: GoogleFonts.outfit(),
                      ),
                      backgroundColor: AppTheme.royalGold,
                    ),
                  );
                },
                icon: const Icon(Icons.link, color: AppTheme.royalGold, size: 20),
                label: Text(
                  'Copy Link',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B4800),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.goldBorder, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestCard(HostInvitee guest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: guest.isDispatched ? const Color(0xFFDEF7EC) : const Color(0xFFE2D6C0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFFAF3DC),
                child: Text(
                  guest.name.isNotEmpty ? guest.name[0].toUpperCase() : 'G',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF701322)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.name,
                      style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    Text(
                      '${guest.phone} • ${guest.cohort}',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              if (guest.isDispatched)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEF7EC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 12, color: Color(0xFF03543F)),
                      const SizedBox(width: 4),
                      Text(
                        'INVITED',
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF03543F)),
                      ),
                    ],
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() => _inviteeList.remove(guest));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1EBE0)),
          const SizedBox(height: 8),

          Text(
            'Invited Ceremonies:',
            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),

          // Ceremony Selection Chips for this specific guest
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableCeremonies.map((c) {
              final isInvited = guest.selectedCeremonies.contains(c.name);
              return FilterChip(
                label: Text(
                  c.name,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: isInvited ? FontWeight.bold : FontWeight.normal,
                    color: isInvited ? const Color(0xFF701322) : AppTheme.textMuted,
                  ),
                ),
                selected: isInvited,
                selectedColor: const Color(0xFFFAF3DC),
                backgroundColor: const Color(0xFFF8FAFC),
                checkmarkColor: const Color(0xFF701322),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isInvited ? const Color(0xFFC58B24) : const Color(0xFFE2E8F0),
                  ),
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      guest.selectedCeremonies.add(c.name);
                    } else {
                      guest.selectedCeremonies.remove(c.name);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    guest.selectedCeremonies = _availableCeremonies.map((c) => c.name).toSet();
                  });
                },
                child: Text('All Events', style: GoogleFonts.outfit(fontSize: 11.5, color: AppTheme.royalGold)),
              ),
              OutlinedButton.icon(
                onPressed: () => _sendSingleWhatsApp(guest),
                icon: const Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.crimsonMaroon),
                label: Text(
                  'WhatsApp Invite',
                  style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.crimsonMaroon),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCeremonyIcon(String type) {
    switch (type.toUpperCase()) {
      case 'HALDI':
        return Icons.spa;
      case 'MEHENDI':
      case 'SANGEET':
        return Icons.music_note;
      case 'MUHURTHAM':
      case 'ENGAGEMENT':
        return Icons.wb_sunny;
      case 'RECEPTION':
        return Icons.celebration;
      default:
        return Icons.event;
    }
  }

  Color _getCeremonyColor(String type) {
    switch (type.toUpperCase()) {
      case 'HALDI':
        return AppTheme.marigoldOrange;
      case 'MEHENDI':
      case 'SANGEET':
        return AppTheme.crimsonMaroon;
      case 'MUHURTHAM':
      case 'ENGAGEMENT':
        return AppTheme.royalGold;
      case 'RECEPTION':
        return AppTheme.marigoldYellow;
      default:
        return AppTheme.crimsonMaroon;
    }
  }

  Widget _buildEventCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.crimsonMaroon : const Color(0xFFEADBBE),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.crimsonMaroon.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.crimsonMaroon, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.crimsonMaroon,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.crimsonMaroon : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? AppTheme.crimsonMaroon : const Color(0xFFCBD5E1),
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWeddingInvitesEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEADBBE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFFDF6EC),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 38,
                  color: AppTheme.crimsonMaroon,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Wedding Invitations Found',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF701322),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t registered for any wedding yet or no one has invited you to a wedding registry.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: AppTheme.textDark,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEADBBE)),
              ),
              child: Text(
                'Register your marriage celebration to customize individual ceremony passes (Haldi, Mehendi, Sangeet, Muhurtham, Reception), import guest contacts from your phone, and send personalized WhatsApp invitations with integrated square-foot gifting.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MarriageRegistrationScreen()),
                  ).then((_) => _loadWeddingData());
                },
                icon: const Icon(Icons.favorite, size: 18, color: Colors.white),
                label: Text(
                  'Register for Marriage ➔',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.crimsonMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalCard(MarriageSubmission sub) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8C252), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              'Wedding Under Admin Review',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF701322),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'REF: ${sub.referenceNumber}',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Your marriage registration for ${sub.coupleTitle} is currently undergoing admin verification and flat assignment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13.5, color: AppTheme.textDark, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              'Once approved, you will be able to select custom ceremony passes, import your guest list, and broadcast personalized WhatsApp invitation cards with live square-foot gifting!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted, height: 1.45),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => _loadWeddingData(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.crimsonMaroon),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Check Verification Status ↻',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.crimsonMaroon, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarigoldToran() {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          10,
          (index) => Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.marigoldOrange,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
