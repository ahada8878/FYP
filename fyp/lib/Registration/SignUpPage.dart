import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart';
import 'package:fyp/Registration/NamePage.dart';
import '../../services/auth_service.dart'; // Import your auth service
import 'package:fyp/Loginpage.dart';

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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRobot) return;

    setState(() => _isLoading = true);

    try {
     
      final data = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        context
      );
      
      if (data['token'] != null) {
        // Navigate to NamePage after successful registration

        //ontap
        await LocalDB.setAuthToken(data['token']);
        await LocalDB.setUser(data['userId'] as String);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NamePage()),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.blueAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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