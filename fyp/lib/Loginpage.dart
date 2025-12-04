import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fyp/Registration/SignUpPage.dart';
import 'package:fyp/main_navigation.dart';
import '../services/auth_service.dart';

class CreativeLoginPage extends StatefulWidget {
  const CreativeLoginPage({super.key});

  @override
  State<CreativeLoginPage> createState() => _CreativeLoginPageState();
}

class _CreativeLoginPageState extends State<CreativeLoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authService
          .login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 10));

      // The `mounted` check here is an extra safeguard before navigating
      if (token != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigationWrapper(),
          ),
        );
      }
    } on TimeoutException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection timeout. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
    } on SocketException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // FIX: This `if (mounted)` check prevents an error if the user navigates away
      // while the async login call is still in progress.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Multi-step dialog for password reset (Creative Dialog Changes applied here)
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    // Use a single variable to store the email across dialog steps
    String resetEmail = '';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Local state for the dialog's StatefulBuilder
        bool isLoading = false;
        String dialogTitle = 'Reset Your Password'; // Creative Title
        int step = 1; // 1: Email, 2: OTP, 3: New Password
        String? errorMessage;
        String? successMessage;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setInnerState) {
            final _formKey = GlobalKey<FormState>();
            final colorScheme = Theme.of(context).colorScheme;

            Widget buildStepContent() {
              switch (step) {
                case 1: // Enter Email
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'Enter your account email to receive a password reset code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurface)),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('emailField'),
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)), // Softer border
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                case 2: // Enter OTP
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'A 6-digit code has been sent to **$resetEmail**. Please enter it below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurface)),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('otpField'),
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, letterSpacing: 10), // Creative style
                        decoration: InputDecoration(
                          labelText: 'Verification Code (OTP)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)), // Softer border
                          counterText: '', // Hide maxLength counter
                        ),
                        validator: (value) {
                          if (value == null || value.length != 6) {
                            return 'Enter the 6-digit code.';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                case 3: // Enter New Password
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Almost done! Enter and confirm your new password.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurface)),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('newPasswordField'),
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)), // Softer border
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('confirmPasswordField'),
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)), // Softer border
                          prefixIcon: const Icon(Icons.check_circle_outline),
                        ),
                        validator: (value) {
                          if (value != newPasswordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                default:
                  return const SizedBox.shrink();
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)), // Creative Shape
              backgroundColor: colorScheme.surface,
              title: Text(dialogTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colorScheme.primary, fontWeight: FontWeight.bold)), // Creative Title Style
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildStepContent(),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            '⚠️ ${errorMessage!}', // Added emoji
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (successMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            '🎉 ${successMessage!}', // Added emoji
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel',
                      style: TextStyle(color: colorScheme.onSurface)),
                  onPressed: isLoading || successMessage != null
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ), // Creative Button Style
                  child: Text(step == 1
                      ? 'Send Code'
                      : (step == 2 ? 'Verify Code' : 'Done!')), // Creative Button Text
                  onPressed: isLoading || successMessage != null
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          setInnerState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            if (step == 1) {
                              // --- Step 1: Send OTP ---
                              resetEmail = emailController.text.trim();
                              await _authService.sendPasswordResetOtp(resetEmail);
                              setInnerState(() {
                                step = 2;
                                dialogTitle = 'Enter The Code'; // Creative Title
                                isLoading = false;
                              });
                            } else if (step == 2) {
                              // --- Step 2: Verify OTP ---
                              final otp = otpController.text.trim();
                              await _authService.verifyPasswordResetOtp(
                                  resetEmail, otp);
                              setInnerState(() {
                                step = 3;
                                dialogTitle = 'Set New Password'; // Creative Title
                                isLoading = false;
                              });
                            } else if (step == 3) {
                              // --- Step 3: Reset Password ---
                              final newPassword = newPasswordController.text;
                              final otp = otpController.text.trim();

                              // FIX: Pass the three required arguments
                              await _authService.resetPassword(
                                  resetEmail, otp, newPassword);

                              setInnerState(() {
                                isLoading = false;
                                successMessage =
                                    'Success! You can now log in with your new password.'; // Creative Success Message
                              });

                              // Close dialog after a short delay
                              await Future.delayed(const Duration(seconds: 2));
                              if (mounted) Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            setInnerState(() {
                              errorMessage =
                                  e.toString().replaceAll('Exception: ', '');
                              isLoading = false;
                            });
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _bgColorAnimation = ColorTween(
      begin: Colors.pink[50],
      end: Colors.blue[50],
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Optimized build method using AnimatedBuilder's 'child' parameter
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // The AnimatedBuilder ONLY rebuilds the gradient background
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  // Use ?? Colors.xxx to safely handle null value before animation starts
                  _bgColorAnimation.value ?? Colors.pink[50]!,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            // The child parameter contains the rest of the static/self-animating UI
            child: child,
          );
        },
        // The entire Stack is passed as the 'child' to the AnimatedBuilder
        // to prevent its unnecessary rebuilding on every frame.
        child: Stack(
          children: [
            // Emojis use their own AnimatedOpacity, so they don't need the AnimatedBuilder.
            const Positioned(
              top: 100,
              left: 30,
              child: AnimatedOpacity(
                duration: Duration(seconds: 2),
                opacity: 0.6,
                child: Text('🍏', style: TextStyle(fontSize: 40)),
              ),
            ),
            const Positioned(
              bottom: 150,
              right: 40,
              child: AnimatedOpacity(
                duration: Duration(seconds: 3),
                opacity: 0.6,
                child: Text('🍩', style: TextStyle(fontSize: 50)),
              ),
            ),
            // Centered content within a SingleChildScrollView
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Center aligned
                      mainAxisAlignment: MainAxisAlignment.center, // Center vertically (useful if not full screen)
                      children: [
                        const SizedBox(height: 80),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Text(
                            'Welcome Back!',
                            textAlign: TextAlign.center, // Centered text
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: colorScheme.primary.withOpacity(0.2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          opacity: _opacityAnimation.value,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            'Log in to track your meals & moods 🍽️',
                            textAlign: TextAlign.center, // Centered text
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildAnimatedField(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Email',
                              prefixIcon:
                                  Icon(Icons.email, color: colorScheme.primary),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedField(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Password',
                              prefixIcon:
                                  Icon(Icons.lock, color: colorScheme.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              'Forgot Password?',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Material(
                            borderRadius: BorderRadius.circular(30),
                            elevation: 5,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: _isLoading ? null : _login,
                              child: Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          'LOG IN',
                                          style: textTheme.titleLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Center(
                        //   child: Text(
                        //     'Or log in with...',
                        //     style: textTheme.bodySmall?.copyWith(
                        //       color: colorScheme.onSurface.withOpacity(0.6),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialLoginButton(
                              icon: '🍎',
                              color: Colors.red[100]!,
                              onTap: () {},
                            ),
                            const SizedBox(width: 20),
                            _SocialLoginButton(
                              icon: '🍕',
                              color: Colors.blue[100]!,
                              onTap: () {},
                            ),
                            const SizedBox(width: 20),
                            _SocialLoginButton(
                              icon: '🍏',
                              color: Colors.green[100]!,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreativeSignupPage(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'New here? ',
                                style: textTheme.bodyMedium?.copyWith(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.7),
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign up',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Extra padding for scroll safety
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedField({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
  }
}