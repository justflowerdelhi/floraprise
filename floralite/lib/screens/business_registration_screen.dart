import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../managers/onboarding_manager.dart';
import '../presentation/splash/floral_background.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'onboarding_flow_screen.dart';
import 'mobile_login_screen.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() =>
      _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState
    extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _onboardingManager = OnboardingManager();

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final registered = await provider.register(
      companyName: _businessNameController.text,
      ownerName: _ownerNameController.text,
      mobile: _mobileController.text,
      address: _addressController.text,
      city: _cityController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (!registered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.friendlyMessage),
        ),
      );
      return;
    }

    final completed = await _onboardingManager.isOnboardingCompleted();
    if (!mounted) return;
    if (completed) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const FloralBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size: 44,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Business Registration',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your Floraprise account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 24),
                          _TextField(
                            controller: _businessNameController,
                            label: 'Business Name',
                            icon: Icons.local_florist_rounded,
                          ),
                          _TextField(
                            controller: _ownerNameController,
                            label: 'Owner Name',
                            icon: Icons.person_outline_rounded,
                          ),
                          _TextField(
                            controller: _mobileController,
                            label: 'Mobile',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            validator: _mobileValidator,
                          ),
                          _TextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.location_on_outlined,
                            keyboardType: TextInputType.streetAddress,
                          ),
                          _TextField(
                            controller: _cityController,
                            label: 'City',
                            icon: Icons.location_city_outlined,
                          ),
                          _TextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _emailValidator,
                          ),
                          _TextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) {
                              final text = value ?? '';
                              if (text.isEmpty) return 'Password is required';
                              if (text.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          _TextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            icon: Icons.lock_reset_outlined,
                            obscureText: true,
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Confirm password is required';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed:
                                provider.isLoading ? null : () => _register(),
                            icon: provider.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.verified_user_outlined),
                            label: const Text('Register'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MobileLoginScreen(),
                                      ),
                                    );
                                  },
                            child: const Text('Already have an account? Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _mobileValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Mobile is required';
    if (text.length < 8) return 'Enter a valid mobile number';
    return null;
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!text.contains('@') || !text.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: validator ??
            (value) =>
                (value ?? '').trim().isEmpty ? '$label is required' : null,
      ),
    );
  }
}
