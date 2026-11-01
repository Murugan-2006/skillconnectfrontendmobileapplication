import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _streetController = TextEditingController();
  final _districtController = TextEditingController();
  final _talukController = TextEditingController();
  final _cityController = TextEditingController();

  final _experienceController = TextEditingController();
  String? _selectedSkill;
  
  final List<String> _skillsList = ['Electrician', 'Plumber', 'AC Repair', 'Electronic Repair'];
  
  String _selectedRole = 'customer'; // Default role
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _streetController.dispose();
    _districtController.dispose();
    _talukController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final otpData = await authService.requestRegisterOtp(
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (otpData != null) {
      Navigator.pushNamed(
        context,
        '/otp-verification',
        arguments: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': _selectedRole,
          'password': _passwordController.text,
          'street': _streetController.text.trim(),
          'district': _districtController.text.trim(),
          'taluk': _talukController.text.trim(),
          'city': _cityController.text.trim(),
          'skill': _selectedRole == 'worker' ? (_selectedSkill ?? '') : '',
          'experience': _selectedRole == 'worker' ? _experienceController.text.trim() : '',
          'devEmailOtp': otpData['emailOtp'] ?? '',
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send verification code. Please try again.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConstants.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge, vertical: AppConstants.paddingSmall),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join SkillConnect and connect with local services or find jobs.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  validator: Validator.validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 16),
                // Address Section
                TextFormField(
                  controller: _streetController,
                  decoration: InputDecoration(
                    labelText: 'Street Address',
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Street is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _talukController,
                        decoration: InputDecoration(
                          labelText: 'Taluk / Subdistrict',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Taluk is required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _districtController,
                        decoration: InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'District is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'City is required' : null,
                ),
                const SizedBox(height: 20),
                // Role Selection
                const Text(
                  'Select Your Account Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'customer'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'customer' ? AppConstants.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            border: Border.all(
                              color: _selectedRole == 'customer' ? AppConstants.primaryColor : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Customer',
                            style: TextStyle(
                              color: _selectedRole == 'customer' ? Colors.white : AppConstants.textPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'worker'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'worker' ? AppConstants.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            border: Border.all(
                              color: _selectedRole == 'worker' ? AppConstants.primaryColor : Colors.grey.shade300,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Service Provider',
                            style: TextStyle(
                              color: _selectedRole == 'worker' ? Colors.white : AppConstants.textPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedRole == 'worker') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Professional Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedSkill,
                    decoration: InputDecoration(
                      labelText: 'Select Your Skill / Trade',
                      prefixIcon: const Icon(Icons.handyman_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                    items: _skillsList.map((String skill) {
                      return DropdownMenuItem<String>(
                        value: skill,
                        child: Text(skill),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSkill = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a skill' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _experienceController,
                    decoration: InputDecoration(
                      labelText: 'Years of Experience',
                      prefixIcon: const Icon(Icons.work_outline),
                      hintText: 'e.g., 3 years',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                    validator: (value) {
                      if (_selectedRole == 'worker' && (value == null || value.isEmpty)) {
                        return 'Experience is required for service providers';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 32),
                authService.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                    : CustomButton(
                        text: 'Register',
                        onPressed: _handleRegister,
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
