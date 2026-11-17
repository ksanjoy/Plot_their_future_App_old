import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../models/flat_model.dart';
import '../services/api_service.dart';

typedef FlatRegistrationWizardBottomSheet = FlatRegistrationWizardDialog;

/// Internal editable representation of a flat section with live controllers
class _SectionItem {
  final String id;
  String name;
  final TextEditingController areaCtrl;
  final TextEditingController lengthCtrl;
  final TextEditingController widthCtrl;
  final TextEditingController priceCtrl;
  String imageUrl;
  String? description;

  _SectionItem({
    required this.id,
    required this.name,
    required int initialArea,
    required this.imageUrl,
    double? initialPrice,
    double? length,
    double? width,
    this.description,
  })  : areaCtrl = TextEditingController(text: initialArea > 0 ? initialArea.toString() : ''),
        lengthCtrl = TextEditingController(text: length != null && length > 0 ? length.toString() : ''),
        widthCtrl = TextEditingController(text: width != null && width > 0 ? width.toString() : ''),
        priceCtrl = TextEditingController(text: initialPrice != null && initialPrice > 0 ? initialPrice.toStringAsFixed(0) : '');

  int get area => int.tryParse(areaCtrl.text.trim()) ?? 0;
  double get price => double.tryParse(priceCtrl.text.trim()) ?? 0.0;
  double get totalPrice => area * price;

  FlatSectionModel toModel(int flatId, double fallbackRate) {
    final effectiveRate = price > 0 ? price : fallbackRate;
    return FlatSectionModel(
      flatId: flatId,
      sectionName: name,
      areaSft: area,
      pricePerSft: effectiveRate,
      totalPrice: area * effectiveRate,
      lengthFt: double.tryParse(lengthCtrl.text.trim()),
      widthFt: double.tryParse(widthCtrl.text.trim()),
      sectionImageUrl: imageUrl,
      description: description,
    );
  }

  void dispose() {
    areaCtrl.dispose();
    lengthCtrl.dispose();
    widthCtrl.dispose();
    priceCtrl.dispose();
  }
}

class FlatRegistrationWizardDialog extends StatefulWidget {
  final FlatModel? existingFlat;
  final VoidCallback onSaved;

  const FlatRegistrationWizardDialog({
    super.key,
    this.existingFlat,
    required this.onSaved,
  });

  // ==========================================
  // IMAGE RENDERING HELPER (File / Asset / Network)
  // ==========================================
  static Widget buildAppImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    Widget img;
    if (path.startsWith('/') || path.startsWith('file://')) {
      final cleanPath = path.replaceFirst('file://', '');
      img = Image.file(
        File(cleanPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallbackImage(width, height),
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      img = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallbackImage(width, height),
      );
    } else {
      img = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallbackImage(width, height),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: img);
    }
    return img;
  }

  static Widget _fallbackImage(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFFAF6F0),
      child: const Icon(Icons.apartment, color: Color(0xFF701322)),
    );
  }

  @override
  State<FlatRegistrationWizardDialog> createState() => _FlatRegistrationWizardDialogState();
}

class _FlatRegistrationWizardDialogState extends State<FlatRegistrationWizardDialog> with SingleTickerProviderStateMixin {
  late TabController _stepController;
  int _currentStep = 0;

  // Step 1: Basic Information Controllers - Start EMPTY (No dummy data)
  final _nameController = TextEditingController();
  final _flatIdController = TextEditingController();
  final _descController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _carpetAreaController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '2');
  final _bathroomsController = TextEditingController(text: '2');
  final _balconiesController = TextEditingController(text: '1');
  final _hallsController = TextEditingController(text: '1');
  final _kitchensController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();

  // Step 2: Images - Direct Image Picker & Upload (No raw URLs)
  String? _selectedCoverImage;
  String _coverImageFileName = '';
  final List<String> _galleryImages = [];

  // Step 3: Sections - Dynamic editable builder
  final List<_SectionItem> _sectionItems = [];

  // Step 4: Pricing & Bricks
  final _pricePerSftController = TextEditingController();
  final _bricksPerSftController = TextEditingController(text: '10');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _stepController = TabController(length: 5, vsync: this);
    _stepController.addListener(() {
      if (!_stepController.indexIsChanging && _currentStep != _stepController.index) {
        setState(() => _currentStep = _stepController.index);
      }
    });

    if (widget.existingFlat != null) {
      final f = widget.existingFlat!;
      _nameController.text = f.name;
      _flatIdController.text = f.flatId;
      _descController.text = f.description ?? '';
      _totalAreaController.text = f.builtUpAreaSft.toString();
      _carpetAreaController.text = f.carpetAreaSft.toString();
      _bedroomsController.text = f.bedrooms > 0 ? f.bedrooms.toString() : '2';
      _bathroomsController.text = f.bathrooms > 0 ? f.bathrooms.toString() : '2';
      _balconiesController.text = f.balconies > 0 ? f.balconies.toString() : '1';
      _hallsController.text = f.halls > 0 ? f.halls.toString() : '1';
      _kitchensController.text = f.kitchens > 0 ? f.kitchens.toString() : '1';
      _locationController.text = f.location;
      _addressController.text = f.address;
      _selectedCoverImage = f.coverImageUrl;
      _coverImageFileName = f.coverImageUrl.split('/').last;
      _galleryImages.addAll(f.galleryImages);
      _pricePerSftController.text = f.pricePerSft.toStringAsFixed(0);
      _bricksPerSftController.text = f.bricksPerSft.toString();

      for (final sec in f.sections) {
        _sectionItems.add(
          _SectionItem(
            id: UniqueKey().toString(),
            name: sec.sectionName,
            initialArea: sec.areaSft,
            imageUrl: sec.sectionImageUrl,
            initialPrice: sec.pricePerSft,
            length: sec.lengthFt,
            width: sec.widthFt,
            description: sec.description,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stepController.dispose();
    _nameController.dispose();
    _flatIdController.dispose();
    _descController.dispose();
    _totalAreaController.dispose();
    _carpetAreaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _balconiesController.dispose();
    _hallsController.dispose();
    _kitchensController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _pricePerSftController.dispose();
    _bricksPerSftController.dispose();
    for (final sec in _sectionItems) {
      sec.dispose();
    }
    super.dispose();
  }

  int get _declaredTotalArea => int.tryParse(_totalAreaController.text.trim()) ?? 0;
  int get _totalSectionArea => _sectionItems.fold<int>(0, (sum, sec) => sum + sec.area);
  bool get _isAreaMatched => _declaredTotalArea > 0 && _declaredTotalArea == _totalSectionArea;

  double get _configuredPricePerSft => double.tryParse(_pricePerSftController.text.trim()) ?? 0.0;
  int get _configuredBricksPerSft => int.tryParse(_bricksPerSftController.text.trim()) ?? 10;
  double get _calculatedPricePerBrick => (_configuredBricksPerSft > 0 && _configuredPricePerSft > 0)
      ? (_configuredPricePerSft / _configuredBricksPerSft)
      : 0.0;

  void _goToStep(int step) {
    if (step >= 0 && step <= 4) {
      // Auto-populate room sections if navigating to Step 3 and sections are empty
      if (step == 2 && _sectionItems.isEmpty) {
        _syncRoomsFromInventory(autoDistribute: true);
      }
      _stepController.animateTo(step);
      setState(() => _currentStep = step);
    }
  }

  // ==========================================
  // IMAGE PICKER & UPLOAD MODAL (CAMERA + GALLERY + PRESETS)
  // ==========================================
  void _openImagePickerModal({
    required String title,
    required String subtitle,
    required Function(String imagePath, String fileName) onImagePicked,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(modalCtx).size.height * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
                        Text(subtitle, style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF5A4A42))),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                ],
              ),
              const Divider(height: 20),

              // Source 1: Real Camera Capture
              _buildUploadOptionTile(
                icon: Icons.camera_alt_outlined,
                iconColor: const Color(0xFF701322),
                title: 'Take Photo with Camera',
                subtitle: 'Capture real estate view or room live with your camera',
                onTap: () async {
                  Navigator.pop(modalCtx);
                  await _pickImage(ImageSource.camera, onImagePicked);
                },
              ),
              const SizedBox(height: 10),

              // Source 2: Real Phone Photo Gallery
              _buildUploadOptionTile(
                icon: Icons.photo_library_outlined,
                iconColor: const Color(0xFFC58B24),
                title: 'Choose from Photo Gallery',
                subtitle: 'Select architectural photo, blueprint, or render from device',
                onTap: () async {
                  Navigator.pop(modalCtx);
                  await _pickImage(ImageSource.gallery, onImagePicked);
                },
              ),
              const SizedBox(height: 16),

              Text('OR SELECT SAMPLE ARCHITECTURAL PRESET', style: GoogleFonts.cinzel(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFC58B24))),
              const SizedBox(height: 10),

              // Preset options
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildPresetImageCard('Modern Tower (Bhooja)', 'assets/images/apartment_poster.jpg', modalCtx, onImagePicked),
                  _buildPresetImageCard('Luxury Sky Villa', 'assets/images/luxury_apartment.jpg', modalCtx, onImagePicked),
                  _buildPresetImageCard('Dream Sunset Villa', 'assets/images/Dreamy Sunset Wedding Villa.png', modalCtx, onImagePicked),
                  _buildPresetImageCard('Sunset Panorama', 'assets/images/landing_sunset_panorama.jpg', modalCtx, onImagePicked),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, Function(String, String) onImagePicked) async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (photo != null) {
        onImagePicked(photo.path, photo.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access image: $e. Please verify camera & gallery permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUploadOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEADBBE)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: iconColor.withOpacity(0.3))),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2C1810))),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF78655A))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF78655A)),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetImageCard(String label, String assetPath, BuildContext ctx, Function(String, String) onPicked) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        onPicked(assetPath, assetPath.split('/').last);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEADBBE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(assetPath, height: 80, width: 150, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(label, style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ROOM AUTO-GENERATION FROM INVENTORY
  // ==========================================
  void _syncRoomsFromInventory({bool autoDistribute = false}) {
    final bhk = int.tryParse(_bedroomsController.text.trim()) ?? 2;
    final baths = int.tryParse(_bathroomsController.text.trim()) ?? 2;
    final balconies = int.tryParse(_balconiesController.text.trim()) ?? 1;
    final halls = int.tryParse(_hallsController.text.trim()) ?? 1;
    final kitchens = int.tryParse(_kitchensController.text.trim()) ?? 1;

    final List<Map<String, dynamic>> roomTemplates = [];

    // Master Bedroom
    roomTemplates.add({
      'name': 'Master Bedroom',
      'weight': 30.0,
      'image': 'assets/images/luxury_apartment.jpg',
    });

    // Additional Bedrooms
    for (int i = 2; i <= bhk; i++) {
      roomTemplates.add({
        'name': 'Bedroom $i',
        'weight': 22.0,
        'image': 'assets/images/luxury_apartment.jpg',
      });
    }

    // Halls / Living Rooms
    for (int i = 1; i <= halls; i++) {
      roomTemplates.add({
        'name': halls == 1 ? 'Hall / Living Room' : 'Living Room $i',
        'weight': 25.0,
        'image': 'assets/images/apartment_poster.jpg',
      });
    }

    // Kitchens
    for (int i = 1; i <= kitchens; i++) {
      roomTemplates.add({
        'name': kitchens == 1 ? 'Kitchen' : 'Kitchen $i',
        'weight': 13.0,
        'image': 'assets/images/apartment_poster.jpg',
      });
    }

    // Balconies
    for (int i = 1; i <= balconies; i++) {
      roomTemplates.add({
        'name': balconies == 1 ? 'Balcony' : 'Balcony $i',
        'weight': 6.0,
        'image': 'assets/images/landing_sunset_panorama.jpg',
      });
    }

    // Bathrooms
    for (int i = 1; i <= baths; i++) {
      roomTemplates.add({
        'name': baths == 1 ? 'Bathroom' : 'Bathroom $i',
        'weight': 6.0,
        'image': 'assets/images/apartment_poster.jpg',
      });
    }

    // Calculate allocated areas if autoDistribute or if totalArea is specified
    final totalArea = _declaredTotalArea;
    double totalWeight = roomTemplates.fold(0.0, (sum, t) => sum + (t['weight'] as double));

    List<int> allocatedAreas = [];
    if (totalArea > 0 && autoDistribute) {
      int allocatedSum = 0;
      for (int idx = 0; idx < roomTemplates.length; idx++) {
        if (idx == roomTemplates.length - 1) {
          // Last room takes remainder so sum matches exactly
          allocatedAreas.add((totalArea - allocatedSum).clamp(0, totalArea));
        } else {
          final weight = roomTemplates[idx]['weight'] as double;
          final portion = ((weight / totalWeight) * totalArea).round();
          allocatedAreas.add(portion);
          allocatedSum += portion;
        }
      }
    } else {
      allocatedAreas = List.filled(roomTemplates.length, 0);
    }

    // Clear existing and rebuild
    for (final sec in _sectionItems) {
      sec.dispose();
    }
    _sectionItems.clear();

    for (int idx = 0; idx < roomTemplates.length; idx++) {
      final tpl = roomTemplates[idx];
      _sectionItems.add(
        _SectionItem(
          id: UniqueKey().toString(),
          name: tpl['name'] as String,
          initialArea: allocatedAreas[idx],
          imageUrl: tpl['image'] as String,
          initialPrice: _configuredPricePerSft,
        ),
      );
    }

    setState(() {});
  }

  void _distributeTargetAreaAcrossCurrentSections() {
    final totalArea = _declaredTotalArea;
    if (totalArea <= 0 || _sectionItems.isEmpty) return;

    int portion = (totalArea / _sectionItems.length).floor();
    int remainder = totalArea - (portion * _sectionItems.length);

    for (int i = 0; i < _sectionItems.length; i++) {
      final assigned = portion + (i == 0 ? remainder : 0);
      _sectionItems[i].areaCtrl.text = assigned.toString();
    }
    setState(() {});
  }

  // ==========================================
  // SECTION BUILDER MODAL (FOR CUSTOM ROOMS)
  // ==========================================
  void _openAddSectionModal({String? presetName}) {
    final secNameCtrl = TextEditingController(text: presetName ?? '');
    final secAreaCtrl = TextEditingController();
    final secLengthCtrl = TextEditingController();
    final secWidthCtrl = TextEditingController();
    final secPriceCtrl = TextEditingController(text: _pricePerSftController.text.trim());
    String secImage = 'assets/images/apartment_poster.jpg';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setSecState) {
          void autoCalcArea() {
            final l = double.tryParse(secLengthCtrl.text.trim());
            final w = double.tryParse(secWidthCtrl.text.trim());
            if (l != null && w != null && l > 0 && w > 0) {
              final calculated = (l * w).round();
              secAreaCtrl.text = calculated.toString();
            }
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(modalCtx).size.height * 0.9),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Custom Section', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                    ],
                  ),
                  const Divider(height: 20),

                  _buildFormInput(
                    label: 'Section / Room Name *',
                    controller: secNameCtrl,
                    hint: 'e.g. Master Bedroom, Dining Hall, Pooja Room',
                    prefixIcon: Icons.meeting_room_outlined,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildFormInput(
                          label: 'Length (Feet)',
                          controller: secLengthCtrl,
                          hint: '15',
                          prefixIcon: Icons.straighten,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => autoCalcArea(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFormInput(
                          label: 'Width (Feet)',
                          controller: secWidthCtrl,
                          hint: '10',
                          prefixIcon: Icons.straighten,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => autoCalcArea(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildFormInput(
                    label: 'Section Area (Sq. Ft.) *',
                    controller: secAreaCtrl,
                    hint: '150',
                    prefixIcon: Icons.square_foot,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = secNameCtrl.text.trim();
                        final area = int.tryParse(secAreaCtrl.text.trim()) ?? 0;
                        if (name.isEmpty || area <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter Section Name and valid Area in Sq. Ft.'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        final rate = double.tryParse(secPriceCtrl.text.trim()) ?? _configuredPricePerSft;

                        setState(() {
                          _sectionItems.add(
                            _SectionItem(
                              id: UniqueKey().toString(),
                              name: name,
                              initialArea: area,
                              imageUrl: secImage,
                              initialPrice: rate,
                              length: double.tryParse(secLengthCtrl.text.trim()),
                              width: double.tryParse(secWidthCtrl.text.trim()),
                            ),
                          );
                        });
                        Navigator.pop(modalCtx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF701322),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Add Section to Flat ➔', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // SUBMISSION LOGIC
  // ==========================================
  Future<void> _handleSaveFlat({bool submitForApproval = false}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter Flat Name.');
      _goToStep(0);
      return;
    }

    if (_declaredTotalArea <= 0) {
      setState(() => _errorMessage = 'Please enter a valid Total Flat Area (Sq. Ft.).');
      _goToStep(0);
      return;
    }

    if (submitForApproval && !_isAreaMatched) {
      setState(() => _errorMessage = 'Cannot submit for approval: Sum of room sections ($_totalSectionArea Sq. Ft.) does not equal declared Total Flat Area ($_declaredTotalArea Sq. Ft.).');
      _goToStep(2);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = {
      'name': name,
      if (_flatIdController.text.trim().isNotEmpty) 'flatId': _flatIdController.text.trim(),
      'description': _descController.text.trim(),
      'builtUpAreaSft': _declaredTotalArea,
      'carpetAreaSft': int.tryParse(_carpetAreaController.text.trim()) ?? (_declaredTotalArea * 0.8).round(),
      'bedrooms': int.tryParse(_bedroomsController.text.trim()) ?? 2,
      'bathrooms': int.tryParse(_bathroomsController.text.trim()) ?? 2,
      'balconies': int.tryParse(_balconiesController.text.trim()) ?? 1,
      'halls': int.tryParse(_hallsController.text.trim()) ?? 1,
      'kitchens': int.tryParse(_kitchensController.text.trim()) ?? 1,
      'location': _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : 'Hyderabad',
      'address': _addressController.text.trim(),
      'coverImageUrl': _selectedCoverImage ?? 'assets/images/apartment_poster.jpg',
      'galleryImages': _galleryImages,
      'pricePerSft': _configuredPricePerSft > 0 ? _configuredPricePerSft : 4500.0,
      'bricksPerSft': _configuredBricksPerSft,
      'pricePerBrick': _calculatedPricePerBrick,
      'sections': _sectionItems.map((s) => s.toModel(widget.existingFlat?.id ?? 0, _configuredPricePerSft)).map((s) => s.toJson()).toList(),
    };

    try {
      FlatModel savedFlat;
      if (widget.existingFlat != null) {
        savedFlat = await ApiService.instance.updateFlat(widget.existingFlat!.id, payload);
      } else {
        savedFlat = await ApiService.instance.createFlat(payload);
      }

      if (submitForApproval) {
        await ApiService.instance.submitFlatForApproval(savedFlat.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(submitForApproval ? 'Flat submitted for Admin approval!' : 'Flat draft saved successfully!'),
          backgroundColor: AppTheme.greenVerified,
        ),
      );
      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save flat: $e';
      });
    }
  }

  // ==========================================
  // MAIN BUILD METHOD WITH KEYBOARD INSETS HANDLING
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.94),
        decoration: const BoxDecoration(
          color: Color(0xFFFAF6F0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // 1. Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // 2. Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF701322).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apartment, color: Color(0xFF701322), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingFlat != null ? 'Edit Flat: ${widget.existingFlat!.name}' : 'Register New Flat',
                          style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF701322)),
                        ),
                        Text(
                          'Step ${_currentStep + 1} of 5 • ${_getStepTitle(_currentStep)}',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF78655A)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF78655A)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEADBBE)),

            // 3. Step Pills Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStepPill(0, '1. Basic Info'),
                    const SizedBox(width: 6),
                    _buildStepPill(1, '2. Photos & Gallery'),
                    const SizedBox(width: 6),
                    _buildStepPill(2, '3. Rooms & SFT (${_sectionItems.length})'),
                    const SizedBox(width: 6),
                    _buildStepPill(3, '4. Pricing & Bricks'),
                    const SizedBox(width: 6),
                    _buildStepPill(4, '5. Review'),
                  ],
                ),
              ),
            ),

            // Error Banner
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!, style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.red.shade800)),
                    ),
                  ],
                ),
              ),

            // 4. Tab Body Content
            Expanded(
              child: TabBarView(
                controller: _stepController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2PhotosAndGallery(),
                  _buildStep3Sections(),
                  _buildStep4PricingAndBricks(),
                  _buildStep5Review(),
                ],
              ),
            ),

            // 5. Responsive Sticky Bottom Action Bar (Zero Pixel Overflows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEADBBE))),
              ),
              child: _currentStep == 4
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _handleSaveFlat(submitForApproval: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF701322),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Submit for Approval ➔', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _goToStep(_currentStep - 1),
                                icon: const Icon(Icons.arrow_back, size: 15, color: Color(0xFF701322)),
                                label: Text('Back', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFC58B24)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => _handleSaveFlat(submitForApproval: false),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF701322)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                                child: Text('Save Draft', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          OutlinedButton.icon(
                            onPressed: () => _goToStep(_currentStep - 1),
                            icon: const Icon(Icons.arrow_back, size: 15, color: Color(0xFF701322)),
                            label: Text('Back', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC58B24)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF78655A))),
                          ),
                        ElevatedButton(
                          onPressed: () => _goToStep(_currentStep + 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF701322),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text('Next Step ➔', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPill(int step, String label) {
    final isSelected = _currentStep == step;
    return InkWell(
      onTap: () => _goToStep(step),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF701322) : const Color(0xFFFAF6F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF701322) : const Color(0xFFEADBBE)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF701322),
          ),
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basic Flat Information';
      case 1:
        return 'Cover Image & Photos';
      case 2:
        return 'Room Templates & Area';
      case 3:
        return 'Pricing & Brick Conversion';
      case 4:
        return 'Review & Submit';
      default:
        return '';
    }
  }

  // ==========================================
  // STEP 1: BASIC INFORMATION (CLEAR "TOTAL FLAT AREA", NO JARGON)
  // ==========================================
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormInput(
            label: 'Flat Name *',
            controller: _nameController,
            hint: 'e.g. My Home Bhooja Luxury 3BHK',
            prefixIcon: Icons.apartment,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildFormInput(
                  label: 'Flat ID (Optional)',
                  controller: _flatIdController,
                  hint: 'e.g. FLAT-2026-HYD-005',
                  prefixIcon: Icons.tag,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFormInput(
                  label: 'City / Location *',
                  controller: _locationController,
                  hint: 'e.g. Financial District, Hyderabad',
                  prefixIcon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildFormInput(
            label: 'Complete Address & Unit Number',
            controller: _addressController,
            hint: 'e.g. Tower B, Flat 804, Serene Heights',
            prefixIcon: Icons.home_outlined,
          ),
          const SizedBox(height: 12),

          // Total Flat Area - Single Clear Label
          _buildFormInput(
            label: 'Total Flat Area (Sq. Ft.) *',
            controller: _totalAreaController,
            hint: 'e.g. 500',
            prefixIcon: Icons.square_foot,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Room Inventory Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Room Inventory Breakdown', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810))),
              Text('Auto-builds rooms in Step 3', style: GoogleFonts.outfit(fontSize: 10.5, color: const Color(0xFFC58B24), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildFormInput(label: 'Bedrooms', controller: _bedroomsController, hint: '2', keyboardType: TextInputType.number)),
              const SizedBox(width: 6),
              Expanded(child: _buildFormInput(label: 'Bathrooms', controller: _bathroomsController, hint: '2', keyboardType: TextInputType.number)),
              const SizedBox(width: 6),
              Expanded(child: _buildFormInput(label: 'Balconies', controller: _balconiesController, hint: '1', keyboardType: TextInputType.number)),
              const SizedBox(width: 6),
              Expanded(child: _buildFormInput(label: 'Halls', controller: _hallsController, hint: '1', keyboardType: TextInputType.number)),
              const SizedBox(width: 6),
              Expanded(child: _buildFormInput(label: 'Kitchens', controller: _kitchensController, hint: '1', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),

          _buildFormInput(
            label: 'Flat Description',
            controller: _descController,
            hint: 'Describe builder quality, floor level, park view, lifestyle amenities...',
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: PHOTOS & GALLERY (UPLOAD DIRECTLY)
  // ==========================================
  Widget _buildStep2PhotosAndGallery() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Primary Flat Cover Photo', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
          const SizedBox(height: 4),
          Text('Guests will see this prominent cover photo across the gifting microsite.', style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF78655A))),
          const SizedBox(height: 12),

          // Cover Image Card Dropzone
          InkWell(
            onTap: () {
              _openImagePickerModal(
                title: 'Upload Flat Cover Photo',
                subtitle: 'Take a photo with camera or choose from gallery',
                onImagePicked: (path, fileName) {
                  setState(() {
                    _selectedCoverImage = path;
                    _coverImageFileName = fileName;
                  });
                },
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEADBBE), width: 1.2),
              ),
              child: _selectedCoverImage != null
                  ? Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlatRegistrationWizardDialog.buildAppImage(
                            _selectedCoverImage!,
                            width: 100,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFF16A34A).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text('Cover Photo Selected', style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
                              ),
                              const SizedBox(height: 4),
                              Text(_coverImageFileName.isNotEmpty ? _coverImageFileName : 'flat_cover.jpg', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text('Tap to change ➔', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    onPressed: () => setState(() {
                                      _selectedCoverImage = null;
                                      _coverImageFileName = '';
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF701322).withOpacity(0.08), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF701322), size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text('Tap to Select & Upload Cover Photo', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
                        const SizedBox(height: 4),
                        Text('Camera, Photo Gallery, or Architectural Presets', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF78655A))),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Multi-image Flat Gallery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Flat Photo Gallery (${_galleryImages.length})', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
              TextButton.icon(
                onPressed: () {
                  _openImagePickerModal(
                    title: 'Add Photo to Gallery',
                    subtitle: 'Add bedroom, living, balcony, or interior photos',
                    onImagePicked: (path, _) {
                      setState(() => _galleryImages.add(path));
                    },
                  );
                },
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: Color(0xFF701322)),
                label: Text('+ Add Photo', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_galleryImages.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEADBBE)),
              ),
              child: Center(
                child: Text('No gallery photos added yet. Tap "+ Add Photo" above.', style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF78655A))),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _galleryImages.asMap().entries.map((entry) {
                final idx = entry.key;
                final img = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEADBBE)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlatRegistrationWizardDialog.buildAppImage(img, width: 90, height: 90, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => setState(() => _galleryImages.removeAt(idx)),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: DYNAMIC ROOM SECTIONS WITH INLINE AREA INPUT
  // ==========================================
  Widget _buildStep3Sections() {
    return Column(
      children: [
        // Live Area Reconciliation Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _isAreaMatched
              ? const Color(0xFFDCFCE7)
              : (_totalSectionArea > _declaredTotalArea ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
          child: Row(
            children: [
              Icon(
                _isAreaMatched ? Icons.check_circle : Icons.warning_amber_rounded,
                color: _isAreaMatched
                    ? const Color(0xFF16A34A)
                    : (_totalSectionArea > _declaredTotalArea ? Colors.red : const Color(0xFFD97706)),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAreaMatched
                          ? 'Area Verified: All rooms ($_totalSectionArea SFT) match Total Flat Area ($_declaredTotalArea SFT).'
                          : (_totalSectionArea < _declaredTotalArea
                              ? 'Remaining to allocate: ${_declaredTotalArea - _totalSectionArea} Sq. Ft. (Target: $_declaredTotalArea SFT)'
                              : 'Rooms exceed Total Area by ${_totalSectionArea - _declaredTotalArea} Sq. Ft.!'),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _isAreaMatched
                            ? const Color(0xFF14532D)
                            : (_totalSectionArea > _declaredTotalArea ? Colors.red.shade900 : const Color(0xFF78350F)),
                      ),
                    ),
                    Text(
                      'Combined Rooms: $_totalSectionArea SFT • Flat Target: $_declaredTotalArea SFT',
                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF78655A)),
                    ),
                  ],
                ),
              ),
              if (!_isAreaMatched && _declaredTotalArea > 0)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF701322),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _distributeTargetAreaAcrossCurrentSections(),
                  child: Text('Auto-Fill', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),

        // Quick Controls Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Room Sections (${_sectionItems.length})',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810)),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _syncRoomsFromInventory(autoDistribute: true),
                icon: const Icon(Icons.sync, size: 14, color: Color(0xFF701322)),
                label: Text('Sync Counts', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF701322))),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF701322),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openAddSectionModal(),
                icon: const Icon(Icons.add, size: 13, color: Colors.white),
                label: const Text('Add Room', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Section Cards List with Inline Area Inputs
        Expanded(
          child: _sectionItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dashboard_customize_outlined, size: 40, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text('No rooms configured.', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810))),
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          onPressed: () => _syncRoomsFromInventory(autoDistribute: true),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF701322)),
                          icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                          label: Text('Generate Rooms from Step 1 Counts', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                  itemCount: _sectionItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final item = _sectionItems[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: item.area > 0 ? const Color(0xFFEADBBE) : Colors.orange.shade300,
                          width: item.area > 0 ? 1 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Room Photo Thumbnail with Tap to Change Photo
                          InkWell(
                            onTap: () {
                              _openImagePickerModal(
                                title: 'Update Room Photo',
                                subtitle: 'Take photo with camera or choose from gallery',
                                onImagePicked: (path, _) {
                                  setState(() => item.imageUrl = path);
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FlatRegistrationWizardDialog.buildAppImage(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Color(0xFF701322), shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Room Name & Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
                                const SizedBox(height: 2),
                                Text(
                                  'Bricks: ${item.area * _configuredBricksPerSft}',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),

                          // Inline Area Input Box
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Area (Sq. Ft.) *', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF78655A))),
                              const SizedBox(height: 2),
                              SizedBox(
                                width: 95,
                                height: 38,
                                child: TextField(
                                  controller: item.areaCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF701322)),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    suffixText: 'SFT',
                                    suffixStyle: GoogleFonts.outfit(fontSize: 10, color: Colors.black54),
                                    filled: true,
                                    fillColor: const Color(0xFFFAF6F0),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEADBBE))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEADBBE))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF701322), width: 1.5)),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 6),

                          // Delete Room Action
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              setState(() {
                                final removed = _sectionItems.removeAt(i);
                                removed.dispose();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: PRICING & BRICKS
  // ==========================================
  Widget _buildStep4PricingAndBricks() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Square-Foot & Brick Pricing Configuration', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
          const SizedBox(height: 4),
          Text(
            'Configure real estate square-foot pricing. Each square foot is converted into bricks (1 Sq. Ft. = 10 Bricks) for guest emotional appeal.',
            style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF78655A)),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildFormInput(
                  label: 'Price Per 1 Sq. Ft. (₹) *',
                  controller: _pricePerSftController,
                  hint: 'e.g. 5200',
                  prefixIcon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormInput(
                  label: 'Bricks Per Sq. Ft.',
                  controller: _bricksPerSftController,
                  hint: '10',
                  prefixIcon: Icons.view_in_ar,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Live Conversion Display Matrix
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEADBBE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate_outlined, color: Color(0xFF701322), size: 18),
                    const SizedBox(width: 8),
                    Text('Automatic Conversion Matrix', style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
                  ],
                ),
                const Divider(height: 20),
                _buildConversionRow('1 Sq. Ft.', '$_configuredBricksPerSft Bricks', '₹${_configuredPricePerSft.toStringAsFixed(0)}'),
                _buildConversionRow('5 Sq. Ft.', '${5 * _configuredBricksPerSft} Bricks', '₹${(5 * _configuredPricePerSft).toStringAsFixed(0)}'),
                _buildConversionRow('10 Sq. Ft.', '${10 * _configuredBricksPerSft} Bricks', '₹${(10 * _configuredPricePerSft).toStringAsFixed(0)}'),
                if (_declaredTotalArea > 0)
                  _buildConversionRow('Whole Flat ($_declaredTotalArea SFT)', '${_declaredTotalArea * _configuredBricksPerSft} Bricks', '₹${(_declaredTotalArea * _configuredPricePerSft).toStringAsFixed(0)}'),
                const Divider(height: 20),
                Text(
                  'Equivalent Price per Brick: ₹${_calculatedPricePerBrick.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFF701322)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionRow(String sft, String bricks, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(sft, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(bricks, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF78655A))),
          Text(price, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF701322))),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 5: REVIEW & APPROVAL (NO PIXEL OVERFLOW, CLEAN LABELS)
  // ==========================================
  Widget _buildStep5Review() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Flat Configuration', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF701322))),
          const SizedBox(height: 12),

          // Validation Badge Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isAreaMatched ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isAreaMatched ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                Icon(_isAreaMatched ? Icons.verified : Icons.error_outline, color: _isAreaMatched ? const Color(0xFF16A34A) : Colors.red, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAreaMatched ? 'AREA RECONCILIATION PASSED' : 'AREA RECONCILIATION REQUIRED',
                        style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 11.5, color: _isAreaMatched ? const Color(0xFF14532D) : Colors.red.shade900),
                      ),
                      Text(
                        _isAreaMatched
                            ? 'Flat Total Area ($_declaredTotalArea SFT) matches combined room sections. Ready for admin submission.'
                            : 'Flat area mismatch! Target Total Area: $_declaredTotalArea SFT, combined room sections: $_totalSectionArea SFT. Please adjust in Step 3.',
                        style: GoogleFonts.outfit(fontSize: 11, color: _isAreaMatched ? const Color(0xFF166534) : Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEADBBE)),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Flat Name', _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Unnamed Flat'),
                _buildSummaryRow('Location', '${_locationController.text} • ${_addressController.text}'),
                _buildSummaryRow('Total Flat Area', '$_declaredTotalArea Sq. Ft.'),
                _buildSummaryRow('Room Sections', '${_sectionItems.length} rooms ($_totalSectionArea Sq. Ft.)'),
                _buildSummaryRow('Rate per Sq. Ft.', '₹${_configuredPricePerSft.toStringAsFixed(0)}'),
                _buildSummaryRow('Bricks Equivalent', '${_declaredTotalArea * _configuredBricksPerSft} Bricks (1 SFT = $_configuredBricksPerSft Bricks)'),
                _buildSummaryRow('Total Valuation Goal', '₹${(_declaredTotalArea * _configuredPricePerSft).toStringAsFixed(0)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11.5, color: const Color(0xFF78655A))),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2C1810))),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED FORM INPUT WIDGET
  // ==========================================
  Widget _buildFormInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C1810),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF2C1810)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.black26),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF701322), size: 18) : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              borderSide: const BorderSide(color: Color(0xFF701322), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
