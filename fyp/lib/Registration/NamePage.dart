import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart';
import 'BirthdayPage.dart';

class NamePage extends StatefulWidget {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _CreativeNamePageState();
}

class _CreativeNamePageState extends State<NamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  

  final TextEditingController _nameController = TextEditingController();
  bool _nameEntered = false;

  @override
  void initState() {
    super.initState();
    displayToken();
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

  void controllerListener() {
    if (kDebugMode) {
      print('Controller value: ${_nameController.text}');
      print('Controller type: ${_nameController.runtimeType}');
    }
    // This method can be used to listen to changes in the controller
    // if needed, but currently it's not being used.
  }  

  @override
  void dispose() {
    
    controllerListener();
    // Dispose of the animation controller and text controller
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void displayToken()async{
    String token=LocalDB.getAuthToken();
    print(token);
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

              // Floating food emojis
              const Positioned(
                top: 100,
                left: 30,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🍎', style: TextStyle(fontSize: 40)),
                ),
              ),
              const Positioned(
                top: 80,
                right: 40,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('🥑', style: TextStyle(fontSize: 50)),
                ),
              ),
              const Positioned(
                bottom: 200,
                left: 50,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🍓', style: TextStyle(fontSize: 45)),
                ),
              ),
              const Positioned(
                bottom: 180,
                right: 60,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('🍊', style: TextStyle(fontSize: 48)),
                ),
              ),

              SingleChildScrollView(
                child: Column(
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                     
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Text(
                              'Your Preferred Name',
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
                              'We\'re so glad you\'re here! What would you like us to call you?',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Name input field
                          AnimatedContainer(
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
                            child: TextField(
                              controller: _nameController,
                              onChanged: (value) {
                                setState(() {
                                  _nameEntered = value.isNotEmpty;
                                });
                              },
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter your name',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  fontSize: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Continue button
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Material(
                              borderRadius: BorderRadius.circular(30),
                              elevation: 5,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: _nameEntered
                                    ? () async{
                                      await LocalDB.setUserName(_nameController.text);
                                      
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const BirthdayPage()),
                                        );
                                      }
                                    : null,
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: _nameEntered
                                        ? LinearGradient(
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.secondary,
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.grey[300]!,
                                              Colors.grey[400]!,
                                            ],
                                          ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'CONTINUE',
                                      style: textTheme.titleLarge?.copyWith(
                                        color: _nameEntered ? Colors.white : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}