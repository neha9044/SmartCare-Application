// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/splash_screen.dart';
import 'package:smartcare_app/screens/registration_screen.dart';
import 'package:smartcare_app/screens/login_screen.dart';
import 'package:smartcare_app/screens/patient/patient_dashboard.dart';
import 'package:smartcare_app/screens/doctor/doctor_dashboard.dart';
import 'package:smartcare_app/screens/pharmacy/pharmacy_home_page.dart';
import 'package:smartcare_app/screens/pharmacy/pharmacy_dashboard.dart'; // Add this import

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
        '/pharmacy-dashboard': (context) => const PharmacyDashboard(), // FIX: Change this line
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        if (userSnapshot.hasError) {
          return const Center(child: Text('Error. Please try again.'));
        }

        final user = userSnapshot.data;

        if (user != null) {
          // Check if the user is a Doctor
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('doctors').doc(user.uid).snapshots(),
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

              // If not a doctor, check if they are a Patient
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('patients').doc(user.uid).snapshots(),
                builder: (context, patientSnapshot) {
                  if (patientSnapshot.connectionState == ConnectionState.waiting) {
                    return SplashScreen();
                  }
                  if (patientSnapshot.hasError) {
                    return const Center(child: Text('Error fetching patient data.'));
                  }
                  if (patientSnapshot.hasData && patientSnapshot.data!.exists) {
                    return const PatientDashboard();
                  }

                  // If not a patient, check if they are a Pharmacy
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('pharmacies').doc(user.uid).snapshots(),
                    builder: (context, pharmacySnapshot) {
                      if (pharmacySnapshot.connectionState == ConnectionState.waiting) {
                        return SplashScreen();
                      }
                      if (pharmacySnapshot.hasError) {
                        return const Center(child: Text('Error fetching pharmacy data.'));
                      }
                      if (pharmacySnapshot.hasData && pharmacySnapshot.data!.exists) {
                        return const PharmacyDashboard(); // FIX: Change this line
                      }

                      // User is logged in but their document doesn't exist, log them out.
                      FirebaseAuth.instance.signOut();
                      return LoginScreen();
                    },
                  );
                },
              );
            },
          );
        } else {
          // If no user is logged in, show the login screen
          return LoginScreen();
        }
      },
    );
  }
}