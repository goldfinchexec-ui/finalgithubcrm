import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/ui/components/shad_text_field.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
      if (!mounted) return;
      context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e));
    } catch (e) {
      setState(() => _error = 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user is disabled.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome back', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Sign in to continue', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.slate600)),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.roseSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate700))),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ShadTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'you@company.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 12),
                    ShadTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      hint: '••••••••',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    ShadButton(
                      label: _loading ? 'Signing in…' : 'Sign in',
                      icon: Icons.login,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : () => context.go('/signup'),
                      child: const Text('Create an account'),
                    ),
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
