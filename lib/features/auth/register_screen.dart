import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lucide_icons/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../shared/exceptions/app_exception.dart';
import '../../shared/widgets/auth_header.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedBarangay = 'Poblacion';
  final List<String> _barangays = [
    'Alitaya',
    'Amansabina',
    'Anolid',
    'Banaoang',
    'Bantayan',
    'Bari',
    'Bateng',
    'Buenlag',
    'David',
    'Embarcadero',
    'Gueguesangen',
    'Guesang',
    'Guiguilonen',
    'Guilig',
    'Inlambo',
    'Lanas',
    'Landas',
    'Maasin',
    'Macayug',
    'Malabago',
    'Merano',
    'Navaluan',
    'Nibaliw',
    'Osiem',
    'Palua',
    'Poblacion',
    'Pogo',
    'Salaan',
    'Salapingao',
    'Talogtog',
    'Tebag',
  ];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
            barangay: _selectedBarangay,
            phone: _phoneController.text.trim(),
          );
      if (mounted) {
        context.go('/report'); // Navigate to home on success
      }
    } catch (e) {
      String msg = e.toString();
      if (e is AppException) {
        msg = e.message;
      } else {
        msg = msg.replaceAll('Exception: ', '');
      }

      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F4C45)),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'Create Account',
                  subtitle: 'Sign up to get started',
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                CustomTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  prefixIcon: LucideIcons.user,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  prefixIcon: LucideIcons.lock,
                  obscureText: true,
                  validator: (value) =>
                      (value?.length ?? 0) < 6 ? 'Password too short' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter your phone number' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedBarangay),
                  // ignore: deprecated_member_use
                  value: _selectedBarangay,
                  decoration: const InputDecoration(
                    labelText: 'Barangay',
                    prefixIcon: Icon(LucideIcons.mapPin),
                    border: OutlineInputBorder(),
                  ),
                  items: _barangays.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedBarangay = newValue!;
                    });
                  },
                ),

                const SizedBox(height: 32),
                PrimaryButton(
                  onPressed: _register,
                  text: 'Register',
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
