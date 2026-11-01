import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOtpController = TextEditingController();

  @override
  void dispose() {
    _emailOtpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyAndRegister(Map<String, dynamic> regData) async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.register(
      name: regData['name'] ?? '',
      email: regData['email'] ?? '',
      phone: regData['phone'] ?? '',
      role: regData['role'] ?? '',
      password: regData['password'] ?? '',
      street: regData['street'] ?? '',
      district: regData['district'] ?? '',
      taluk: regData['taluk'] ?? '',
      city: regData['city'] ?? '',
      skill: regData['skill'] ?? '',
      experience: regData['experience'] ?? '',
      emailOtp: _emailOtpController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final role = regData['role'] ?? 'customer';
      if (role == 'worker') {
        Navigator.pushNamedAndRemoveUntil(context, '/worker-dashboard', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/customer-home', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid verification code. Please try again.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final regData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final authService = Provider.of<AuthService>(context);

    // Development helper text: If server sent OTPs in dev mode, show them
    final String devEmailOtp = regData['devEmailOtp'] ?? '';
    final bool showDevTips = devEmailOtp.isNotEmpty;

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
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We have sent a verification code to:\n${regData['email']}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Development OTP Banner
                if (showDevTips)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bug_report, color: Colors.amber, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Development Mode OTP Tips',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Email OTP: $devEmailOtp', style: const TextStyle(fontFamily: 'monospace')),
                      ],
                    ),
                  ),

                // Email OTP Field
                TextFormField(
                  controller: _emailOtpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Email Verification Code',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email verification code is required';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                authService.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                    : CustomButton(
                        text: 'Verify & Create Account',
                        onPressed: () => _handleVerifyAndRegister(regData),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
