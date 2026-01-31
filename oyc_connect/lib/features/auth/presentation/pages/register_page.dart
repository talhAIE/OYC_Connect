import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oyc_connect/features/auth/presentation/pages/login_page.dart';
import '../../../../core/theme/app_pallete.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_field.dart';
import '../../../../core/utils/snackbar_utils.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }

      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      next.when(
        data: (_) {
          showCustomSnackBar(context, 'Account created! Please log in.');
          Navigator.pop(context); // Go back to login
        },
        error: (err, st) {
          showCustomSnackBar(context, err.toString(), isError: true);
        },
        loading: () {},
      );
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/images/oyc_logo.jpeg',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the OYC Connect community today.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withAlpha(165),
                  ),
                ),
                const SizedBox(height: 40),

                // Full Name
                CustomField(
                  hintText: 'Full Name',
                  icon: Icons.person_outline,
                  controller: _fullNameController,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                // Email
                CustomField(
                  hintText: 'Email Address',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                CustomField(
                  hintText: 'Phone Number',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    // Basic digits check
                    if (!RegExp(r'^[0-9+]+$').hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                CustomField(
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  isObscure: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomField(
                  hintText: 'Confirm Password',
                  icon: Icons.lock_outline,
                  isObscure: true,
                  controller: _confirmPasswordController,
                  validator: (value) =>
                      value!.isEmpty ? 'Confirm your password' : null,
                ),
                const SizedBox(height: 32),

                // Sign Up Button
                AuthButton(
                  text: 'Sign Up',
                  onPressed: _signUp,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.black.withAlpha(165)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(
                            0xFF1E8449,
                          ), // Greenish from the UI image for "Create Account"
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
