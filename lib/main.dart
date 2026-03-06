// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/splash_screen.dart';
import 'package:smartcare_app/screens/registration_screen.dart';
import 'package:smartcare_app/screens/login_screen.dart';
import 'package:smartcare_app/screens/patient/patient_dashboard.dart';
import 'package:smartcare_app/screens/doctor/doctor_dashboard.dart';
import 'package:smartcare_app/screens/pharmacy/pharmacy_dashboard.dart';

// ZEGOCLOUD imports
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

// 🔹 Replace with your actual values from ZEGOCLOUD dashboard
const int appID = 337679718;
const String appSign =
    "cf00ab9695c467b514ec8babe34842be933c9074d03c306980c1f2f48f5af98b";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SmartCareApp());
}

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        hintColor: AppColors.accentColor,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
        ),
      ),
      home: AuthWrapper(),
      routes: {
        '/register': (context) => RegistrationScreen(),
        '/login': (context) => LoginScreen(),
        '/patient-dashboard': (context) => const PatientDashboard(),
        '/doctor-dashboard': (context) => const DoctorDashboard(),
        '/pharmacy-dashboard': (context) => const PharmacyDashboard(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  void _initZego(firebase_auth.User user) {
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: appID,
      appSign: appSign,
      userID: user.uid,
      userName: user.email ?? "User",
      plugins: [ZegoUIKitSignalingPlugin()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        if (userSnapshot.hasError) {
          return const Center(child: Text('Error. Please try again.'));
        }

        final user = userSnapshot.data;

        if (user != null) {
          // 🔹 Initialize ZEGOCLOUD when user logs in
          _initZego(user);

          // Check Doctor
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .doc(user.uid)
                .snapshots(),
            builder: (context, doctorSnapshot) {
              if (doctorSnapshot.connectionState == ConnectionState.waiting) {
                return SplashScreen();
              }

              if (doctorSnapshot.hasError) {
                return const Center(child: Text('Error fetching doctor data.'));
              }

              if (doctorSnapshot.hasData && doctorSnapshot.data!.exists) {
                return const DoctorDashboard();
              }

              // Check Patient
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, patientSnapshot) {
                  if (patientSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return SplashScreen();
                  }

                  if (patientSnapshot.hasError) {
                    return const Center(
                      child: Text('Error fetching patient data.'),
                    );
                  }

                  if (patientSnapshot.hasData && patientSnapshot.data!.exists) {
                    return const PatientDashboard();
                  }

                  // Check Pharmacy
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('pharmacies')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, pharmacySnapshot) {
                      if (pharmacySnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return SplashScreen();
                      }

                      if (pharmacySnapshot.hasError) {
                        return const Center(
                          child: Text('Error fetching pharmacy data.'),
                        );
                      }

                      if (pharmacySnapshot.hasData &&
                          pharmacySnapshot.data!.exists) {
                        return const PharmacyDashboard();
                      }

                      firebase_auth.FirebaseAuth.instance.signOut();
                      return LoginScreen();
                    },
                  );
                },
              );
            },
          );
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
