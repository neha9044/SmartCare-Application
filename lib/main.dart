import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/splash_screen.dart';
import 'package:smartcare_app/screens/registration_screen.dart';
import 'package:smartcare_app/screens/login_screen.dart';
import 'package:smartcare_app/screens/patient/patient_dashboard.dart';
import 'package:smartcare_app/screens/doctor/doctor_dashboard.dart';

void main() {
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
      home: SplashScreen(), // Starts the app with the SplashScreen
      routes: {
        '/splash': (context) => SplashScreen(),
        '/register': (context) => RegistrationScreen(),
        '/login': (context) => LoginScreen(),
        '/patient-dashboard': (context) => PatientDashboard(),
        '/doctor-dashboard': (context) => DoctorDashboardScreen(),
      },
    );
  }
}