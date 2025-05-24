import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:fyp/NamePage.dart';
import 'package:fyp/ProfilePage.dart';
import 'package:fyp/SignUpPage.dart';
import 'package:fyp/main.dart';
import 'package:fyp/main_navigation.dart';
import 'HomePage.dart';
import 'ProfilePage.dart';

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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

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
              // Background gradient animation
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

              // Floating emojis
              Positioned(
                top: 100,
                left: 30,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 2),
                  opacity: 0.6,
                  child: const Text('🍏', style: TextStyle(fontSize: 40)),
                ),
              ),
              Positioned(
                bottom: 150,
                right: 40,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 3),
                  opacity: 0.6,
                  child: const Text('🍩', style: TextStyle(fontSize: 50)),
                ),
              ),

              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 80),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          'Welcome Back!',
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
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email Field
                      _buildAnimatedField(
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Email',
                            prefixIcon:
                                Icon(Icons.email, color: colorScheme.primary),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      _buildAnimatedField(
                        child: TextField(
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
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Material(
                          borderRadius: BorderRadius.circular(30),
                          elevation: 5,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MainNavigationWrapper(),
                                ),
                              );
                            },
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
                                child: Text(
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

                      Center(
                        child: Text(
                          'Or log in with...',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ),
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
                                builder: (context) => CreativeSignupPage(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'New here? ',
                              style: textTheme.bodyMedium?.copyWith(
                                color:
                                    colorScheme.onBackground.withOpacity(0.7),
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
