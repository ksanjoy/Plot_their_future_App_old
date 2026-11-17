import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';

/// Interactive OpenStreetMap Location Picker and In-App Navigation Component
class OSMMapPickerModal extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;
  final String title;

  const OSMMapPickerModal({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
    this.title = 'Select Location on OpenStreetMap',
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    double? initialLat,
    double? initialLng,
    String? initialAddress,
    String title = 'Select Location on OpenStreetMap',
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OSMMapPickerModal(
        initialLat: initialLat,
        initialLng: initialLng,
        initialAddress: initialAddress,
        title: title,
      ),
    );
  }

  @override
  State<OSMMapPickerModal> createState() => _OSMMapPickerModalState();
}

class _OSMMapPickerModalState extends State<OSMMapPickerModal> {
  final MapController _mapController = MapController();
  late LatLng _selectedLocation;
  String _locationName = '';
  bool _isLoadingLocation = false;
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    // Default to initial coords or Hyderabad / Vijayawada
    _selectedLocation = LatLng(
      widget.initialLat ?? 17.3850,
      widget.initialLng ?? 78.4867,
    );
    _locationName = widget.initialAddress ?? 'Hyderabad, Telangana';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAndFetchCurrentLocation(autoFetch: false);
    });
  }

  Future<void> _requestAndFetchCurrentLocation({bool autoFetch = false}) async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );

        if (mounted) {
          final newLoc = LatLng(position.latitude, position.longitude);
          setState(() {
            _selectedLocation = newLoc;
          });
          _mapController.move(newLoc, 16.0);
          _reverseGeocode(newLoc);
        }
      } else if (!autoFetch && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is needed to pinpoint your exact GPS position.'),
            backgroundColor: AppTheme.crimsonMaroon,
          ),
        );
      }
    } catch (e) {
      debugPrint('[OSMMapPicker] Location error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );
      final res = await http.get(url, headers: {'User-Agent': 'PlotTheirFuture-App/1.0'}).timeout(
        const Duration(seconds: 4),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty && mounted) {
          setState(() {
            _locationName = displayName;
          });
          return;
        }
      }
    } catch (_) {
      // Offline fallback
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }

    // Fallback if offline or timeout
    if (mounted) {
      setState(() {
        _locationName = 'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(4)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF701322).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_outlined, color: Color(0xFF701322), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF701322),
                        ),
                      ),
                      Text(
                        'Tap anywhere or drag to change the pin location',
                        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF6B5E55)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF2C1810)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: Color(0xFFEADBBE)),

          // Map Area with OpenStreetMap
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                      _reverseGeocode(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.plottheirfuture.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            size: 46,
                            color: Color(0xFF701322),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating My Location Button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'osm_my_loc',
                    backgroundColor: const Color(0xFF701322),
                    foregroundColor: Colors.white,
                    onPressed: _isLoadingLocation ? null : () => _requestAndFetchCurrentLocation(),
                    child: _isLoadingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.my_location, size: 20),
                  ),
                ),

                // Quick City Selectors
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCityChip('Hyderabad', 17.3850, 78.4867),
                        _buildCityChip('Vijayawada', 16.5062, 80.6480),
                        _buildCityChip('Bengaluru', 12.9716, 77.5946),
                        _buildCityChip('Visakhapatnam', 17.6868, 83.2185),
                        _buildCityChip('Chennai', 13.0827, 80.2707),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Selection Bar & Confirmation
          Container(
            padding: const EdgeInsets.all(16),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 16, color: Color(0xFF701322)),
                      const SizedBox(width: 6),
                      Text(
                        'Selected OpenStreetMap Location:',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF701322),
                        ),
                      ),
                      if (_isReverseGeocoding) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF701322)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _locationName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF2C1810)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GPS: ${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF8C7A70)),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final mapUrl =
                            'https://www.openstreetmap.org/?mlat=${_selectedLocation.latitude}&mlon=${_selectedLocation.longitude}#map=16/${_selectedLocation.latitude}/${_selectedLocation.longitude}';
                        Navigator.pop(context, {
                          'address': _locationName,
                          'lat': _selectedLocation.latitude,
                          'lng': _selectedLocation.longitude,
                          'mapUrl': mapUrl,
                        });
                      },
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      label: Text(
                        'Confirm Location Pin',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF701322),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityChip(String name, double lat, double lng) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(name, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFEADBBE)),
        elevation: 2,
        onPressed: () {
          final point = LatLng(lat, lng);
          setState(() {
            _selectedLocation = point;
          });
          _mapController.move(point, 14.0);
          _reverseGeocode(point);
        },
      ),
    );
  }
}

/// In-App OpenStreetMap Viewer & Navigation Component (Integrated, No External App)
class OSMNavigationModal extends StatefulWidget {
  final double venueLat;
  final double venueLng;
  final String venueName;
  final String venueAddress;

  const OSMNavigationModal({
    super.key,
    required this.venueLat,
    required this.venueLng,
    required this.venueName,
    required this.venueAddress,
  });

  static Future<void> show(
    BuildContext context, {
    required double venueLat,
    required double venueLng,
    required String venueName,
    required String venueAddress,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OSMNavigationModal(
        venueLat: venueLat,
        venueLng: venueLng,
        venueName: venueName,
        venueAddress: venueAddress,
      ),
    );
  }

  @override
  State<OSMNavigationModal> createState() => _OSMNavigationModalState();
}

class _OSMNavigationModalState extends State<OSMNavigationModal> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  double _distanceKm = 0.0;
  int _estimatedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _startNavigation();
  }

  Future<void> _startNavigation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        if (mounted) {
          final uLoc = LatLng(pos.latitude, pos.longitude);

          final distanceMeters = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            widget.venueLat,
            widget.venueLng,
          );

          setState(() {
            _userLocation = uLoc;
            _distanceKm = distanceMeters / 1000.0;
            _estimatedMinutes = (_distanceKm * 2.5).round().clamp(5, 180);
          });

          // Zoom to fit both locations
          _mapController.move(
            LatLng(
              (pos.latitude + widget.venueLat) / 2,
              (pos.longitude + widget.venueLng) / 2,
            ),
            12.5,
          );
        }
      }
    } catch (e) {
      debugPrint('[OSMNavigation] GPS error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final venuePoint = LatLng(widget.venueLat, widget.venueLng);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag bar
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF701322).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.navigation_outlined, color: Color(0xFF701322), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OpenStreetMap Navigation',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF701322),
                        ),
                      ),
                      Text(
                        widget.venueName,
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF2C1810)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 14, color: Color(0xFFEADBBE)),

          // Navigation Status Banner
          if (_userLocation != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF701322), Color(0xFF8B1E2D)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: Color(0xFFEADBBE), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route to ${widget.venueName}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_distanceKm.toStringAsFixed(1)} km away • Est. $_estimatedMinutes mins via OpenStreetMap',
                          style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFEADBBE)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Live OSM',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: venuePoint,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.plottheirfuture.app',
                    ),
                    if (_userLocation != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_userLocation!, venuePoint],
                            strokeWidth: 4.0,
                            color: const Color(0xFF701322),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Venue Marker
                        Marker(
                          point: venuePoint,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            size: 46,
                            color: Color(0xFF701322),
                          ),
                        ),
                        // User GPS Location Marker
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person_pin_circle, size: 20, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'osm_nav_recenter',
                    backgroundColor: const Color(0xFF701322),
                    foregroundColor: Colors.white,
                    onPressed: () {
                      if (_userLocation != null) {
                        _mapController.move(
                          LatLng(
                            (_userLocation!.latitude + widget.venueLat) / 2,
                            (_userLocation!.longitude + widget.venueLng) / 2,
                          ),
                          13.0,
                        );
                      } else {
                        _mapController.move(venuePoint, 15.0);
                      }
                    },
                    child: const Icon(Icons.center_focus_strong, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Venue Details Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEADBBE))),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Color(0xFF701322)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.venueName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C1810),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.venueAddress,
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF5A4A42)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'OpenStreetMap Navigation Pin: ${widget.venueLat.toStringAsFixed(4)}, ${widget.venueLng.toStringAsFixed(4)}',
                    style: GoogleFonts.outfit(fontSize: 10.5, color: const Color(0xFF8C7A70)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
