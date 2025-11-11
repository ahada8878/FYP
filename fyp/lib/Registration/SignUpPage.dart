import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart';
import 'package:fyp/Registration/NamePage.dart';
import '../../services/auth_service.dart'; // Import your auth service
import 'package:fyp/Loginpage.dart';

// NOTE: The import for OtpVerificationPage.dart has been removed 
// because its logic is now contained in this file.

class CreativeSignupPage extends StatefulWidget {
  const CreativeSignupPage({super.key});

  @override
  State<CreativeSignupPage> createState() => _CreativeSignupPageState();
}

class _CreativeSignupPageState extends State<CreativeSignupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService(); // Initialize auth service
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isRobot = true;
  bool _isLoading = false; // Added loading state

  // --------------------------------------------------------------------------
  // 1. UPDATED SIGNUP LOGIC
  // --------------------------------------------------------------------------

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRobot) return;

    // Reset loading state for the main button
    setState(() => _isLoading = true); 

    try {
      // 1. Call the new sendOtp method 
      await _authService.sendOtp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // 2. On success, show the creative dialog (DO NOT NAVIGATE)
      

      // 🌟 CALL THE DIALOG HERE 🌟
      _showOtpVerificationDialog(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.blueAccent,
        ),
      );
    } finally {
      // Reset loading only if the dialog was not successfully shown,
      // but since we show the dialog on success, we reset it here.
      setState(() => _isLoading = false);
    }
  }
  
  // --------------------------------------------------------------------------
  // 2. DIALOG TRIGGER FUNCTION
  // --------------------------------------------------------------------------

  Future<void> _showOtpVerificationDialog(String email, String password) {
    // We use showDialog to pop up a modal over the current screen
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by tapping outside
      builder: (BuildContext context) {
        return _OtpVerificationDialog(
          email: email,
          password: password,
          authService: _authService,
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // 3. ANIMATION AND LIFECYCLE METHODS (UNCHANGED)
  // --------------------------------------------------------------------------

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
      begin: Colors.orange[50],
      end: Colors.purple[50],
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // --------------------------------------------------------------------------
  // 4. BUILD METHOD (UNCHANGED)
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _bgColorAnimation.value!,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const Positioned(
                top: 100,
                left: 30,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🍔', style: TextStyle(fontSize: 40)),
                ),
              ),
              const Positioned(
                bottom: 150,
                right: 40,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('🍣', style: TextStyle(fontSize: 50)),
                ),
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 80),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Text(
                            'Join the Foodie Club!',
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
                            'Track meals, moods, and more 🎉',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _AnimatedInputField(
                          controller: _emailController,
                          hintText: 'Email',
                          icon: Icons.email,
                          colorScheme: colorScheme,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _AnimatedInputField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock,
                          colorScheme: colorScheme,
                          isPassword: true,
                          isVisible: _isPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _AnimatedInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          icon: Icons.lock_reset,
                          colorScheme: colorScheme,
                          isPassword: true,
                          isVisible: _isPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isRobot ? Colors.red[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _isRobot ? Colors.red : Colors.green,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: !_isRobot,
                                  onChanged: (value) {
                                    setState(() {
                                      _isRobot = !value!;
                                    });
                                  },
                                  activeColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isRobot ? 'I\'m a robot 🤖' : 'I\'m human! 👩‍🍳',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: _isRobot ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Material(
                            borderRadius: BorderRadius.circular(30),
                            elevation: 5,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: _isRobot || _isLoading ? null : _signup,
                              child: Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: _isRobot || _isLoading
                                      ? LinearGradient(
                                          colors: [
                                            Colors.grey,
                                            Colors.grey[400]!,
                                          ],
                                        )
                                      : LinearGradient(
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
                                          _isRobot
                                              ? 'ROBOTS NOT ALLOWED ❌'
                                              : 'SIGN UP',
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
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              // Assuming CreativeLoginPage exists
                              Navigator.push( 
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreativeLoginPage(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Log in',
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
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 5. REUSABLE WIDGETS (UNCHANGED)
// --------------------------------------------------------------------------

class _AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;

  const _AnimatedInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.colorScheme,
    this.isPassword = false,
    this.isVisible = false,
    this.onToggleVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
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
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        validator: validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: Icon(icon, color: colorScheme.primary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: colorScheme.primary,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 6. OTP VERIFICATION DIALOG WIDGET (NEW)
// --------------------------------------------------------------------------

class _OtpVerificationDialog extends StatefulWidget {
  final String email;
  final String password;
  final AuthService authService;

  const _OtpVerificationDialog({
    required this.email,
    required this.password,
    required this.authService,
  });

  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  final _otpController = TextEditingController();
  final _dialogFormKey = GlobalKey<FormState>();
  bool _isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_dialogFormKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    try {
      final data = await widget.authService.verifyOtp(
        widget.email,
        widget.password,
        _otpController.text.trim(),
      );

      if (data['token'] != null) {
        await LocalDB.setAuthToken(data['token']);
        await LocalDB.setUser(data['userId'] as String);
        
        // Success! Close the dialog and navigate to the next page
        Navigator.pop(context); // Close the dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NamePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.lock_open,
                    color: colorScheme.primary,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verify Email',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to ${widget.email}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '******',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '', // Hide the maxLength counter
                    ),
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return 'Code must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _isVerifying
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _verifyOtp,
                            child: const Text(
                              'VERIFY',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Dismiss the dialog
                    },
                    child: const Text('Cancel / Wrong Email?'),
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