import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/constants/app_constants.dart';
import '../models/floor_plan_tile_model.dart';
import '../models/gift_contribution.dart';
import '../models/room_model.dart';
import '../models/tax_receipt_model.dart';
import '../services/api_service.dart';

class FlatRegistryState extends ChangeNotifier {
  bool _useINR = true;
  String _selectedRoomId = 'all';
  bool _isLoadingFromApi = false;
  String? _lastError;
  TaxReceiptModel? _lastGeneratedReceipt;

  // Exact 2 BHK Room Cell Breakdown from Spec & Mocks
  List<RoomModel> _rooms = [
    const RoomModel(
      id: 'living_room',
      name: 'Living & Dining',
      totalSqFt: 400,
      giftedSqFt: 0,
      description: 'The vibrant heart of the home for morning chai, family gatherings, and festivals.',
      iconName: 'weekend_outlined',
      colorValue: 0xFFD4AF37,
      startTileIndex: 0,
    ),
    const RoomModel(
      id: 'master_bedroom',
      name: 'Master Bedroom',
      totalSqFt: 250,
      giftedSqFt: 0,
      description: 'A peaceful haven for restful nights and sweet dreams for the newlyweds.',
      iconName: 'king_bed_outlined',
      colorValue: 0xFFD4AF37,
      startTileIndex: 400,
    ),
    const RoomModel(
      id: 'balcony',
      name: 'Balcony',
      totalSqFt: 80,
      giftedSqFt: 0,
      description: 'Sunset vista and potted garden for evening breezes and endless conversations.',
      iconName: 'balcony_outlined',
      colorValue: 0xFFD4AF37,
      startTileIndex: 650,
    ),
    const RoomModel(
      id: 'kitchen',
      name: 'Kitchen',
      totalSqFt: 120,
      giftedSqFt: 0,
      description: 'Where traditional aroma and modern recipes combine to feed a happy life.',
      iconName: 'kitchen_outlined',
      colorValue: 0xFF64748B,
      startTileIndex: 730,
    ),
    const RoomModel(
      id: 'bedroom_2',
      name: 'Bedroom 2',
      totalSqFt: 200,
      giftedSqFt: 0,
      description: 'Comfortable guest sanctuary ensuring parents and relatives are always welcomed.',
      iconName: 'single_bed_outlined',
      colorValue: 0xFF64748B,
      startTileIndex: 850,
    ),
    const RoomModel(
      id: 'utility',
      name: 'Bathrooms & Utility',
      totalSqFt: 150,
      giftedSqFt: 0,
      description: 'Essential utility, smart storage, and refreshing wellness spaces.',
      iconName: 'bathtub_outlined',
      colorValue: 0xFF64748B,
      startTileIndex: 1050,
    ),
  ];

  // Authentic pre-seeded contributions (empty initially until guests gift)
  final List<GiftContribution> _contributions = [];

  // Getters
  bool get useINR => _useINR;
  String get selectedRoomId => _selectedRoomId;
  List<RoomModel> get rooms => _rooms;
  List<GiftContribution> get contributions => List.unmodifiable(_contributions);
  bool get isLoadingFromApi => _isLoadingFromApi;
  String? get lastError => _lastError;
  TaxReceiptModel? get lastGeneratedReceipt => _lastGeneratedReceipt;

  int get totalSqFt => AppConstants.totalSqFt;
  int get totalGiftedSqFt => _rooms.fold(0, (sum, room) => sum + room.giftedSqFt);
  int get remainingSqFt => (totalSqFt - totalGiftedSqFt).clamp(0, totalSqFt);
  double get overallProgress => totalSqFt == 0 ? 0.0 : (totalGiftedSqFt / totalSqFt).clamp(0.0, 1.0);
  double get pricePerSqFt => AppConstants.ratePerSqFt;
  double get totalRaisedAmount => totalGiftedSqFt * pricePerSqFt;
  double get totalTargetAmount => totalSqFt * pricePerSqFt;
  int get totalContributors => _contributions.length;

  void toggleCurrency() {
    _useINR = !_useINR;
    notifyListeners();
  }

  void selectRoom(String roomId) {
    _selectedRoomId = roomId;
    notifyListeners();
  }

  RoomModel? getRoomById(String id) {
    try {
      return _rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // REST API SYNC METHODS
  // ==========================================

  /// Fetch live floor plan zones & successful contributions from REST API
  Future<void> fetchRegistryFromApi({int weddingId = 1}) async {
    _isLoadingFromApi = true;
    _lastError = null;
    notifyListeners();

    try {
      final zones = await ApiService.instance.getFloorPlanZones(weddingId);
      if (zones.isNotEmpty) {
        // Map API zones into rooms
        final updatedRooms = <RoomModel>[];
        final seenRoomIds = <String>{};
        int tileOffset = 0;
        for (var z in zones) {
          final lower = z.roomName.toLowerCase();
          String roomId;
          if (lower.contains('living') || lower.contains('dining') || lower.contains('hall')) {
            roomId = 'living_room';
          } else if (lower.contains('master')) {
            roomId = 'master_bedroom';
          } else if (lower.contains('balcony')) {
            roomId = 'balcony';
          } else if (lower.contains('kitchen')) {
            roomId = 'kitchen';
          } else if (lower.contains('bedroom 2') || lower.contains('bedroom_2')) {
            roomId = 'bedroom_2';
          } else if (lower.contains('bath') || lower.contains('utility')) {
            roomId = 'utility';
          } else {
            roomId = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
          }

          if (seenRoomIds.add(roomId)) {
            updatedRooms.add(
              RoomModel(
                id: roomId,
                name: z.roomName,
                totalSqFt: z.totalSft,
                giftedSqFt: z.fundedSft,
                description: 'Authentic 2 BHK space in Skyline Meadows Unit 402.',
                iconName: 'weekend_outlined',
                colorValue: z.fundedSft > 0 ? 0xFFD4AF37 : 0xFF64748B,
                startTileIndex: tileOffset,
              ),
            );
            tileOffset += z.totalSft;
          }
        }
        if (updatedRooms.isNotEmpty) {
          _rooms = updatedRooms;
        }
      }

      final liveContribs = await ApiService.instance.getSuccessfulContributions(weddingId);
      if (liveContribs.isNotEmpty) {
        // Merge without duplicating
        final existingIds = _contributions.map((c) => c.id).toSet();
        for (var c in liveContribs) {
          if (!existingIds.contains(c.id)) {
            _contributions.insert(0, c);
          }
        }
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[FlatRegistryState] Api fetch notice: $e');
    } finally {
      _isLoadingFromApi = false;
      notifyListeners();
    }
  }

  /// 8.8 Temporary 10-Minute Cart Hold (Concurrency Safe)
  Future<FloorPlanTile?> holdTileForCart(int tileId, {required String phone}) async {
    try {
      final tile = await ApiService.instance.lockTile(
        tileId: tileId,
        phone: phone,
        minutes: 10,
      );
      notifyListeners();
      return tile;
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }

  /// 9.5 & 9.7 & 10.5 Gifting with REST API Checkout & Tax Exemption Receipt
  Future<GiftContribution> giftSqFtViaApi({
    required String donorName,
    required String relationship,
    required int sqFt,
    required String roomId,
    required String blessingMessage,
    String? guestMobile,
    String? guestEmail,
    String paymentMethod = "Escrow UPI Confirmed",
    int weddingId = 5,
    int invitationId = 1,
  }) async {
    final effectiveRoomId = roomId == 'all' ? _rooms.first.id : roomId;
    final room = getRoomById(effectiveRoomId) ?? _rooms.first;
    final totalAmount = sqFt * pricePerSqFt;

    int contributionId = DateTime.now().millisecondsSinceEpoch % 100000;
    String txnId = 'TXN_UPI_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    String bankRef = 'HDFC000${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    try {
      // 1. Initiate contribution with guest and room metadata
      final initRes = await ApiService.instance.initiateContribution(
        weddingId: weddingId,
        invitationId: invitationId,
        unitsSft: sqFt,
        amount: totalAmount,
        blessingMessage: blessingMessage,
        guestName: donorName,
        guestMobile: guestMobile,
        guestEmail: guestEmail,
        sectionName: room.name,
      );
      if (initRes != null && initRes['id'] != null) {
        contributionId = (initRes['id'] is int) ? initRes['id'] : int.tryParse(initRes['id'].toString()) ?? contributionId;
      }

      // 2. Confirm payment
      await ApiService.instance.confirmContribution(
        contributionId: contributionId,
        txnId: txnId,
        bankRef: bankRef,
      );

      // 3. Sync FloorPlanZone in MySQL
      try {
        final zones = await ApiService.instance.getFloorPlanZones(weddingId);
        final matchZone = zones.firstWhere(
          (z) => z.roomName.toLowerCase().contains(room.name.toLowerCase().split(' ').first),
          orElse: () => zones.first,
        );
        await ApiService.instance.updateFloorPlanZoneFunded(matchZone.id, matchZone.fundedSft + sqFt);
      } catch (e) {
        debugPrint('[FlatRegistryState] Floor plan zone sync notice: $e');
      }

      // 4. Generate Section 56(2)(x) Tax Receipt
      final receipt = await ApiService.instance.generateTaxReceipt(
        contributionId: contributionId,
      );
      _lastGeneratedReceipt = receipt;
    } catch (e) {
      debugPrint('[FlatRegistryState] Gifting api notice: $e');
    }

    // Update room allocation in state
    _rooms = _rooms.map((r) {
      if (r.id == room.id) {
        return r.copyWith(giftedSqFt: r.giftedSqFt + sqFt);
      }
      return r;
    }).toList();

    final deedToken = _lastGeneratedReceipt?.receiptNo ?? 'PTF-ESC-$contributionId';
    final newContribution = GiftContribution(
      id: 'contrib_$contributionId',
      donorName: donorName.trim().isEmpty ? 'Loving Guest' : donorName.trim(),
      relationship: relationship.trim().isEmpty ? 'Family & Friends' : relationship.trim(),
      sqFt: sqFt,
      amount: totalAmount,
      roomId: room.id,
      roomName: room.name,
      blessingMessage: blessingMessage.trim().isEmpty
          ? 'Hearty congratulations to the beautiful couple on your new home!'
          : blessingMessage.trim(),
      timestamp: DateTime.now(),
      deedToken: deedToken,
      paymentMethod: paymentMethod,
    );

    _contributions.insert(0, newContribution);
    notifyListeners();
    return newContribution;
  }

  /// Synchronous fallback
  GiftContribution giftSqFt({
    required String donorName,
    required String relationship,
    required int sqFt,
    required String roomId,
    required String blessingMessage,
    String paymentMethod = "UPI Confirmed",
  }) {
    final effectiveRoomId = roomId == 'all' ? _rooms.first.id : roomId;
    final room = getRoomById(effectiveRoomId) ?? _rooms.first;

    _rooms = _rooms.map((r) {
      if (r.id == room.id) {
        return r.copyWith(giftedSqFt: r.giftedSqFt + sqFt);
      }
      return r;
    }).toList();

    final deedToken = 'PTF-ESC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final newContribution = GiftContribution(
      id: 'contrib_${DateTime.now().millisecondsSinceEpoch}',
      donorName: donorName.trim().isEmpty ? 'Loving Guest' : donorName.trim(),
      relationship: relationship.trim().isEmpty ? 'Family & Friends' : relationship.trim(),
      sqFt: sqFt,
      amount: sqFt * pricePerSqFt,
      roomId: room.id,
      roomName: room.name,
      blessingMessage: blessingMessage.trim().isEmpty
          ? 'Hearty congratulations Sanvi & Santosh on your new beginning!'
          : blessingMessage.trim(),
      timestamp: DateTime.now(),
      deedToken: deedToken,
      paymentMethod: paymentMethod,
    );

    _contributions.insert(0, newContribution);
    notifyListeners();
    return newContribution;
  }
}

final flatRegistryProvider = ChangeNotifierProvider<FlatRegistryState>((ref) {
  return FlatRegistryState();
});
