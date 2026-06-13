//lib\features\auth\register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final String? redirect;

  const RegisterScreen({
    super.key,
    this.redirect,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    fullNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/home');
  }

  String _loginPath() {
    final redirect = widget.redirect;

    if (redirect == null || redirect.trim().isEmpty) {
      return '/login';
    }

    return '/login?redirect=${Uri.encodeComponent(redirect)}';
  }

  Future<void> _register(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await AuthService().register(
        fullName: fullNameController.text,
        mobile: mobileController.text,
        email: emailController.text,
        password: passwordController.text,
      );

      if (!context.mounted) return;

      if (response.user == null) {
        setState(() {
          error = 'Registration failed. Please try again.';
        });
        return;
      }

      if (response.session == null) {
        setState(() {
          error =
              'Account created successfully. Please verify your email or login manually.';
        });
        return;
      }

      context.go(widget.redirect ?? '/home');
    } catch (exception) {
      if (!mounted) return;

      setState(() {
        error = exception.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        _goBack(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: _AuthBackground(
          child: SafeArea(
            child: Column(
              children: [
                _AuthTopBar(
                  title: 'Create Account',
                  onBack: () => _goBack(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _AuthHero(
                            title: 'Join the game',
                            subtitle:
                                'Create your account and start predicting match scores.',
                          ),
                          const SizedBox(height: 18),
                          _AuthCard(
                            child: Column(
                              children: [
                                AppTextField(
                                  controller: fullNameController,
                                  label: 'Full name',
                                  validator: (value) {
                                    return Validators.required(
                                      value,
                                      'Full name',
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: mobileController,
                                  label: 'Mobile number',
                                  keyboardType: TextInputType.phone,
                                  validator: Validators.mobile,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: emailController,
                                  label: 'Email address',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: passwordController,
                                  label: 'Password',
                                  obscure: true,
                                  validator: Validators.password,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: confirmPasswordController,
                                  label: 'Confirm password',
                                  obscure: true,
                                  validator: (value) {
                                    if (value != passwordController.text) {
                                      return 'Passwords do not match';
                                    }

                                    return null;
                                  },
                                ),
                                if (error != null) ...[
                                  const SizedBox(height: 12),
                                  _ErrorBox(message: error!),
                                ],
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: AppButton(
                                    label: 'Register',
                                    loading: loading,
                                    onPressed: loading
                                        ? null
                                        : () => _register(context),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Already registered?',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: loading
                                          ? null
                                          : () => context.push(_loginPath()),
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  final Widget child;

  const _AuthBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.background),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            right: -140,
            child: _GlowBlob(
              color: AppTheme.teal,
              size: 320,
              opacity: 0.20,
            ),
          ),
          Positioned(
            bottom: -160,
            left: -150,
            child: _GlowBlob(
              color: AppTheme.blue,
              size: 300,
              opacity: 0.09,
            ),
          ),
          Positioned(
            bottom: 120,
            right: -160,
            child: _GlowBlob(
              color: AppTheme.gold,
              size: 260,
              opacity: 0.05,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: 100,
            spreadRadius: 46,
          ),
        ],
      ),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _AuthTopBar({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: onBack,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.045),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthHero({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 128,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF063E35),
            Color(0xFF07121B),
            Color(0xFF102333),
          ],
        ),
        border: Border.all(color: AppTheme.teal.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -34,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 112,
              color: Colors.white.withOpacity(0.045),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.teal.withOpacity(0.12),
                  border: Border.all(
                    color: AppTheme.teal.withOpacity(0.18),
                  ),
                ),
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  color: AppTheme.teal,
                  size: 20,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final Widget child;

  const _AuthCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface2.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.075)),
      ),
      child: child,
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}