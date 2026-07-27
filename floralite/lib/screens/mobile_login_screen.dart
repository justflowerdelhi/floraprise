import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/splash/floral_background.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'onboarding_flow_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberLogin = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final success = await provider.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
      rememberLogin: _rememberLogin,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.friendlyMessage)),
      );
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
                            Icons.lock_open_rounded,
                            size: 44,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in with your mobile number or email.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 24),
                          _TextField(
                            controller: _identifierController,
                            label: 'Mobile or Email',
                            icon: Icons.person_outline_rounded,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Mobile or email is required';
                              }
                              return null;
                            },
                          ),
                          _TextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),
                          CheckboxListTile(
                            value: _rememberLogin,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Remember login'),
                            onChanged: (value) {
                              setState(() {
                                _rememberLogin = value ?? true;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: provider.isLoading ? null : _login,
                            icon: provider.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: const Text('Login'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: provider.isLoading
                                ? null
                                : () => Navigator.of(context)
                                    .pushReplacementNamed('/mobile-register'),
                            child: const Text('Create a new account'),
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
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        textInputAction: TextInputAction.next,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
