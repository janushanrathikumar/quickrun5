import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORT YOUR FIREBASE OPTIONS
// Make sure this path is correct based on your project structure
import 'package:quickrun5/firebase_options.dart';

// ENTRY POINT
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Delivery App',
      initialNotificationContent: 'Tracking location...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // --- FIX IS HERE ---
  // You MUST pass options, otherwise the background service
  // doesn't know which Firebase project to write to.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase init error: $e");
  }
  // -------------------

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    await _updateLocation();
  });
}

Future<void> _updateLocation() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('user_uid');

    if (uid != null) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("Saving Location: ${position.latitude}, ${position.longitude}");

      // 1. SAVE HISTORY (Your existing code)
      await FirebaseFirestore.instance
          .collection('location_history')
          .doc(uid)
          .collection('path')
          .add({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'uid': uid,
          });

      // 2. UPDATE CURRENT LOCATION (New code for the Map View)
      // This updates the main document so we can fetch all users easily
      await FirebaseFirestore.instance
          .collection('location_history')
          .doc(uid)
          .set({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'last_updated': FieldValue.serverTimestamp(),
            'uid': uid,
            'type': 'current_location',
          }, SetOptions(merge: true));
    }
  } catch (e) {
    print("Error sending location: $e");
  }
}
