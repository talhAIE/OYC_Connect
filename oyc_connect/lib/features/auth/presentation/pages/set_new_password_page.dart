import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_pallete.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_field.dart';

class SetNewPasswordPage extends ConsumerStatefulWidget {
  const SetNewPasswordPage({super.key});

  @override
  ConsumerState<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends ConsumerState<SetNewPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _leaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final recovery = ref.read(passwordRecoveryProvider);
    if (_leaving || recovery.busy || !recovery.ready) return;
    if (_formKey.currentState?.validate() != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final completed = await recovery.complete(_passwordController.text);
    if (completed && messenger.mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated. Please log in with your new password.',
          ),
        ),
      );
    }
  }

  Future<void> _cancel() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await ref.read(passwordRecoveryProvider).cancel();
    if (mounted) setState(() => _leaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final recovery = ref.watch(passwordRecoveryProvider);
    final isLoading = recovery.busy || _leaving;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppPallete.darkText),
            tooltip: 'Cancel password reset',
            onPressed: _leaving ? null : _cancel,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: AppPallete.primary,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Set New Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a strong password for your account.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withAlpha(165),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (recovery.error != null) ...[
                      Text(
                        recovery.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (recovery.busy && !recovery.ready)
                      const Center(child: CircularProgressIndicator()),
                    if (recovery.ready) ...[
                      CustomField(
                        hintText: 'New Password',
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
                      CustomField(
                        hintText: 'Confirm New Password',
                        icon: Icons.lock_outline,
                        isObscure: true,
                        controller: _confirmController,
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
                      const SizedBox(height: 24),
                      AuthButton(
                        text: 'Update Password',
                        onPressed: _submit,
                        isLoading: isLoading,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
