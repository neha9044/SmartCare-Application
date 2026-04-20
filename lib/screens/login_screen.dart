import 'package:flutter/material.dart';
import 'package:smartcare_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F4FD), // Very light blue
              Color(0xFFF0F9FF), // Almost white blue
              Color(0xFFE0F2F1), // Very light teal
            ],
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo section
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF42A5F5).withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF4A90E2),
                                Color(0xFF4A90E2),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.medical_services, size: 40, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Welcome text
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sign in to continue your healthcare journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF546E7A),
                        ),
                      ),
                      SizedBox(height: 32),
                      // User type selection
                      Text(
                        'Select Account Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildUserTypeCard('Patient', Icons.person)),
                          SizedBox(width: 12),
                          Expanded(child: _buildUserTypeCard('Doctor', Icons.local_hospital)),
                          SizedBox(width: 12),
                          Expanded(child: _buildUserTypeCard('Pharmacy', Icons.local_pharmacy)),
                        ],
                      ),
                      SizedBox(height: 28),
                      // Email field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4A90E2).withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: Color(0xFF4A90E2), fontSize: 16),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your email';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                              return 'Please enter a valid email';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Color(0xFF546E7A)),
                            prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF4A90E2)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Password field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4A90E2).withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: Color(0xFF4A90E2), fontSize: 16),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Color(0xFF546E7A)),
                            prefixIcon: Icon(Icons.lock_outlined, color: Color(0xFF4A90E2)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Color(0xFF4A90E2),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      // Login button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF42A5F5),
                              Color(0xFF42A5F5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF42A5F5).withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      // Register link
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: 'Don\'t have an account? ',
                            style: TextStyle(color: Color(0xFF546E7A), fontSize: 16),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  color: Color(0xFF42A5F5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
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
        duration: Duration(milliseconds: 300),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF42A5F5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Color(0xFF42A5F5) : Color(0xFFE0E0E0),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? Color(0xFF42A5F5).withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                    blurRadius: isSelected ? 15 : 8,
                    offset: Offset(0, isSelected ? 8 : 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Color(0xFF42A5F5),
                size: 32,
              ),
            ),
            SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Color(0xFF42A5F5) : Color(0xFF546E7A),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
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
