import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveDriversMapScreen extends StatefulWidget {
  const ActiveDriversMapScreen({super.key});

  @override
  State<ActiveDriversMapScreen> createState() => _ActiveDriversMapScreenState();
}

class _ActiveDriversMapScreenState extends State<ActiveDriversMapScreen> {
  static const int LOCATION_TIMEOUT_MINUTES = 5;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // --- NEW STATE VARIABLE ---
  Map<String, dynamic>? _tappedDriver;
  // --------------------------

  static const CameraPosition _kDefaultPosition = CameraPosition(
    target: LatLng(46.943783, 7.416562),
    zoom: 10.0,
  );

  bool _cameraMoved = false;

  bool isLocationRecent(Timestamp? lastUpdated) {
    if (lastUpdated == null) {
      return false;
    }
    final fiveMinutesAgo = DateTime.now().subtract(
      const Duration(minutes: LOCATION_TIMEOUT_MINUTES),
    );
    return lastUpdated.toDate().isAfter(fiveMinutesAgo);
  }

  // --- Function to initiate the phone call ---
  Future<void> _makeCall(String? mobileNumber, String driverName) async {
    if (mobileNumber == null || mobileNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Mobile number not available for $driverName.'),
        ),
      );
      return;
    }

    final cleanedNumber = mobileNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanedNumber);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch call to $driverName: $mobileNumber'),
        ),
      );
    }
  }

  // --- Core Function: Generate Markers (Marker now handles state update on tap) ---
  Set<Marker> _generateMarkers(List<Map<String, dynamic>> activeDrivers) {
    Set<Marker> newMarkers = {};
    LatLng? firstActiveLocation;

    for (var driver in activeDrivers) {
      final locationData = driver['locationData'] as Map<String, dynamic>;
      final lat = locationData['latitude'] as double?;
      final lng = locationData['longitude'] as double?;

      if (lat != null && lng != null) {
        final position = LatLng(lat, lng);
        if (firstActiveLocation == null) {
          firstActiveLocation = position;
        }

        final marker = Marker(
          markerId: MarkerId(driver['uid'] as String),
          position: position,

          // --- NEW: Marker onTap updates the tapped driver state ---
          onTap: () {
            setState(() {
              _tappedDriver = driver; // Store the driver's data
            });
          },

          // REMOVED: infoWindow property entirely
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        );
        newMarkers.add(marker);
      }
    }

    // Camera Movement Logic
    if (!_cameraMoved &&
        firstActiveLocation != null &&
        _mapController != null) {
      Future.microtask(() {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(firstActiveLocation!, 14.0),
        );
        _cameraMoved = true;
      });
    }

    return newMarkers;
  }

  // --- NEW: Custom Info Window Widget ---
  Widget _buildCustomInfoWindow() {
    if (_tappedDriver == null) {
      return const SizedBox.shrink();
    }

    final driverName = _tappedDriver!['name'] as String;
    final mobileNumber = _tappedDriver!['mobile'] as String?;
    final lastSeenTime = DateFormat(
      'HH:mm:ss',
    ).format((_tappedDriver!['lastUpdatedTimestamp'] as Timestamp).toDate());

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last seen: $lastSeenTime',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                // --- Clickable Call Icon ---
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green, size: 30),
                  onPressed: () {
                    // Call goes out immediately when the icon is clicked
                    _makeCall(mobileNumber, driverName);
                    // Optional: Hide the info window after calling
                    setState(() {
                      _tappedDriver = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Drivers on Map'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usersdetails')
            .snapshots(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (usersSnapshot.hasError) {
            return Center(child: Text('Error: ${usersSnapshot.error}'));
          }

          final userDocs = usersSnapshot.data?.docs ?? [];
          if (userDocs.isEmpty) {
            return const Center(
              child: Text('No users found in "usersdetails".'),
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(
              userDocs.map((userDoc) async {
                final uid = userDoc.id;
                final userData = userDoc.data() as Map<String, dynamic>;

                final locationDoc = await FirebaseFirestore.instance
                    .collection('location_history')
                    .doc(uid)
                    .get();

                Map<String, dynamic> locationData = {};
                Timestamp? lastUpdatedTimestamp;

                if (locationDoc.exists) {
                  locationData = locationDoc.data() as Map<String, dynamic>;
                  lastUpdatedTimestamp =
                      locationData['last_updated'] as Timestamp?;
                }

                final isRecent = isLocationRecent(lastUpdatedTimestamp);

                String? mobileString;
                final mobileValue = userData['mobile'];
                if (mobileValue != null) {
                  mobileString = mobileValue.toString();
                }

                return {
                  'uid': uid,
                  'name': userData['name'] ?? 'Unknown Driver',
                  'mobile': mobileString,
                  'locationData': locationData,
                  'isRecent': isRecent,
                  'lastUpdatedTimestamp': lastUpdatedTimestamp,
                };
              }),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Text('Checking driver statuses...'));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error processing statuses: ${snapshot.error}'),
                );
              }

              final activeDrivers = snapshot.data!
                  .where((driver) => driver['isRecent'] == true)
                  .toList();

              _markers = _generateMarkers(activeDrivers);

              if (_markers.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No drivers currently active (updated within the last 5 minutes).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }

              // --- STACK: Overlay Map and Custom Info Window ---
              return Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _kDefaultPosition,
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      if (!_cameraMoved && activeDrivers.isNotEmpty) {
                        final firstDriver = activeDrivers.first;
                        final lat =
                            firstDriver['locationData']['latitude'] as double?;
                        final lng =
                            firstDriver['locationData']['longitude'] as double?;
                        if (lat != null && lng != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0),
                          );
                          _cameraMoved = true;
                        }
                      }
                    },
                    // NEW: Hide the custom info window when user taps the map background
                    onTap: (LatLng) {
                      setState(() {
                        _tappedDriver = null;
                      });
                    },
                  ),

                  // Display the custom info window on top
                  _buildCustomInfoWindow(),
                ],
              );
              // ----------------------------------------------------
            },
          );
        },
      ),
    );
  }
}
