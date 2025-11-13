import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; 

class RateUsScreen extends StatefulWidget {
  const RateUsScreen({super.key});

  @override
  State<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _cardAnimationController;
  late Animation<double> _scaleAnimation;
  
  double _rating = 3.0;
  bool _isSubmitting = false;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    
    _scaleAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _feedbackController.dispose(); 
    super.dispose();
  }

  void _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    
    // String feedback = _feedbackController.text.trim();
    // In a real app, send _rating and feedback to a backend service here.

    // --- Submission Logic Simulation ---
    await Future.delayed(const Duration(seconds: 2));
    // --- End Submission Logic ---

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar( // RESTORED CONFIRMATION
        SnackBar(
          content: Text('Thank you for rating us $_rating stars!'),
          backgroundColor: Colors.green.shade400,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color ratingColor = _rating >= 4.0
        ? Colors.green.shade500
        : _rating >= 2.5
            ? Colors.orange.shade500
            : Colors.red.shade500;
            
    // Use Stack to layer the background and the foreground content
    return Scaffold(
      body: Stack( 
        children: [
          // 1. Animated Background (Fills the entire Stack, which is full screen)
          const _LivingAnimatedBackground(),
          
          // 2. Foreground content wrapped in a SingleChildScrollView for keyboard safety
          SingleChildScrollView( 
            child: ConstrainedBox(
              // Constrain the content area to be at least the screen height
              // This ensures the background always fills the viewport when content is short.
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column( 
                // Distribute space vertically to center the card when there's extra room
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 3. App Bar/Back Button (Outside the card)
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                  ),

                  // 2. Main Content (Centered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0), // Padding for the bottom
                    child: Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _GlassyCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  
                                  // Icon and Header Text
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    size: 60,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Love the app? Rate us!',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.grey[900],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Your feedback drives our motivation and improvement.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 40),

                                  // Star Rating Bar
                                  RatingBar.builder(
                                    initialRating: _rating,
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    itemBuilder: (context, _) => Icon(
                                      Icons.star_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 36,
                                    ),
                                    onRatingUpdate: (rating) {
                                      setState(() {
                                        _rating = rating;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 15),

                                  // Enhanced Rating Display
                                  
                                  const SizedBox(height: 30),

                                  // Feedback Text Field
                                  _buildFeedbackField(context),
                                  
                                  const SizedBox(height: 40),

                                  // Submit Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting ? null : _submitRating,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        elevation: _isSubmitting ? 0 : 8,
                                        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                      ),
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              ),
                                            )
                                          : const Text(
                                              'Submit Feedback',
                                              style: TextStyle(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Spacer at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Text(
            'Tell us more (Optional):',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
        ),
        TextFormField(
          controller: _feedbackController,
          maxLines: 4,
          minLines: 2,
          decoration: InputDecoration(
            hintText: 'What did you love or how can we improve?',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
            ),
            fillColor: Colors.white.withOpacity(0.95),
            filled: true,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

// --- HELPER WIDGETS ---

/// A card that mimics the semi-transparent white style (Glassmorphism).
class _GlassyCard extends StatelessWidget {
  final Widget child;
  const _GlassyCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.7)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The animated gradient background from the home page.
class _LivingAnimatedBackground extends StatefulWidget {
  const _LivingAnimatedBackground();
  @override
  State<_LivingAnimatedBackground> createState() =>
      _LivingAnimatedBackgroundState();
}

class _LivingAnimatedBackgroundState extends State<_LivingAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 40))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // These colors define a gentle, animated gradient shift
    final colors = [
      Color.lerp(
          const Color(0xffa8edea), const Color(0xfffed6e3), _controller.value)!,
      Color.lerp(
          const Color(0xfffed6e3), const Color(0xffa8edea), _controller.value)!,
    ];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        ),
      ),
    );
  }
}