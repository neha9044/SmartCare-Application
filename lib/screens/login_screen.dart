import 'package:flutter/material.dart';
import 'package:smartcare_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedUserType = 'Patient';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF357ABD),
              Color(0xFF2C5F95),
              Color(0xFF1A3B6B),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.medical_services, size: 40, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Connecting Care, Empowering Health\nWelcome to SmartCare',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildUserTypeCard('Patient', Icons.person),
                          _buildUserTypeCard('Doctor', Icons.local_hospital),
                          _buildUserTypeCard('Pharmacy', Icons.local_pharmacy),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                            return 'Please enter a valid email';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                          prefixIcon: Icon(Icons.email, color: Colors.white.withOpacity(0.8), size: 20),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your password';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                          prefixIcon: Icon(Icons.lock, color: Colors.white.withOpacity(0.8), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white.withOpacity(0.8)),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF2C5F95),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF2C5F95), strokeWidth: 2))
                              : Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: RichText(
                            text: TextSpan(
                              text: 'Don\'t have an account? ',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                              children: [TextSpan(text: 'Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(String type, IconData icon) {
    bool isSelected = selectedUserType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedUserType = type),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.3), width: 2),
          boxShadow: isSelected ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Color(0xFF2C5F95) : Colors.white, size: 26),
            SizedBox(height: 6),
            Text(type, style: TextStyle(color: isSelected ? Color(0xFF2C5F95) : Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final isCorrectUserType = await _authService.checkUserType(
        userId: _authService.currentUser!.uid,
        expectedUserType: selectedUserType,
      );

      if (isCorrectUserType) {
        switch (selectedUserType) {
          case 'Patient':
            Navigator.pushReplacementNamed(context, '/patient-dashboard');
            break;
          case 'Doctor':
            Navigator.pushReplacementNamed(context, '/doctor-dashboard');
            break;
          case 'Pharmacy':
            Navigator.pushReplacementNamed(context, '/pharmacy-dashboard');
            break;
        }
      } else {
        await _authService.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user type selected. Please choose the correct type.'), backgroundColor: Colors.red),
        );
      }

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') message = 'No user found for that email.';
      else if (e.code == 'wrong-password') message = 'Wrong password provided.';
      else message = 'Login failed. Please check your credentials.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to login. Please try again.'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
