import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_pallete.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_field.dart';
import 'register_page.dart';
import '../../../../core/utils/snackbar_utils.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state to show errors or navigate (navigation logic usually in main/router)
    // Listen to auth state to show errors or navigate (navigation logic usually in main/router)

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      next.when(
        data: (_) {
          showCustomSnackBar(context, 'Welcome back!');
          context.go('/home');
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/oyc_logo.jpeg',
                    height: 100, // Adjust height as needed
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'OYC Connect',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your spiritual journey, digitized.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  CustomField(
                    hintText: 'Email Address',
                    icon: Icons.person_outline,
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

                  // Password Field
                  CustomField(
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    isObscure: true,
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  AuthButton(
                    text: 'Continue Securely',
                    onPressed: _signIn,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Forgot Password
                  TextButton(
                    onPressed: () {
                      // TODO: Implement Forgot Password
                    },
                    child: const Text(
                      'FORGOT PASSWORD?',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New here? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Create Account',
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
      ),
    );
  }
}
