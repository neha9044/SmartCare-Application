import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String selectedUserType = 'Patient';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _licenseController = TextEditingController();

  // NEW DOCTOR FIELDS
  final _experienceController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _locationController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicLocationController = TextEditingController();
  final _consultationFeesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F4FD),
              Color(0xFFF0F9FF),
              Color(0xFFE0F2F1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF42A5F5).withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Color(0xFF42A5F5)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42A5F5),
                      ),
                    ),
                    Spacer(),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // User type selection
                          Text(
                            'Select Account Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF42A5F5),
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
                          SizedBox(height: 24),
                          // Form fields
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          // Doctor-specific fields
                          if (selectedUserType == 'Doctor') ...[
                            _buildTextField(
                              controller: _specialtyController,
                              label: 'Specialty',
                              icon: Icons.medical_services_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your specialty';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _experienceController,
                              label: 'Years of Experience',
                              icon: Icons.work_outline,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your experience';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _qualificationController,
                              label: 'Qualifications (e.g., MBBS, MD)',
                              icon: Icons.school_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your qualifications';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _locationController,
                              label: 'Your City/Location',
                              icon: Icons.location_city_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your location';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _clinicNameController,
                              label: 'Clinic Name',
                              icon: Icons.business_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your clinic name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _clinicLocationController,
                              label: 'Clinic Address',
                              icon: Icons.place_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your clinic address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: _consultationFeesController,
                              label: 'Consultation Fees (\$)',
                              icon: Icons.attach_money_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your consultation fees';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                          ],
                          // License field for Doctor and Pharmacy
                          if (selectedUserType == 'Doctor' || selectedUserType == 'Pharmacy') ...[
                            _buildTextField(
                              controller: _licenseController,
                              label: selectedUserType == 'Doctor'
                                  ? 'Medical License Number'
                                  : 'Pharmacy License Number',
                              icon: Icons.verified_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your license number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                          ],
                          // Password fields
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outlined,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            icon: Icons.lock_outlined,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 32),
                          // Register button
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
                              onPressed: _isLoading ? null : _handleRegistration,
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
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          // Login link
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(color: Color(0xFF546E7A), fontSize: 16),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
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
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF42A5F5).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Color(0xFF42A5F5), fontSize: 16),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color(0xFF546E7A)),
          prefixIcon: Icon(icon, color: Color(0xFF42A5F5)),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Color(0xFF42A5F5),
            ),
            onPressed: onToggleVisibility,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.registerUserWithFirestore(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userType: selectedUserType,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        specialty: selectedUserType == 'Doctor' ? _specialtyController.text.trim() : null,
        licenseNumber: (selectedUserType == 'Doctor' || selectedUserType == 'Pharmacy') ? _licenseController.text.trim() : null,

        // Pass NEW Doctor-specific data
        experience: selectedUserType == 'Doctor' ? _experienceController.text.trim() : null,
        qualification: selectedUserType == 'Doctor' ? _qualificationController.text.trim() : null,
        location: selectedUserType == 'Doctor' ? _locationController.text.trim() : null,
        clinicName: selectedUserType == 'Doctor' ? _clinicNameController.text.trim() : null,
        clinicLocation: selectedUserType == 'Doctor' ? _clinicLocationController.text.trim() : null,
        consultationFees: selectedUserType == 'Doctor' ? double.tryParse(_consultationFeesController.text.trim()) : null,
      );

      // Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = 'An unexpected error occurred. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create account. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();

    // Dispose NEW Doctor controllers
    _experienceController.dispose();
    _qualificationController.dispose();
    _locationController.dispose();
    _clinicNameController.dispose();
    _clinicLocationController.dispose();
    _consultationFeesController.dispose();

    super.dispose();
  }
}
