import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/config_service.dart'; // Import the config file for IP and port

class AiScannerResultPage extends StatefulWidget {
  final File imageFile;
  final bool fromCamera;

  const AiScannerResultPage({
    super.key,
    required this.imageFile,
    required this.fromCamera,
  });

  @override
  State<AiScannerResultPage> createState() => _AiScannerResultPageState();
}

class _AiScannerResultPageState extends State<AiScannerResultPage> {
  String _prediction = "Analyzing...";
  bool _isProcessing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _sendImageForPrediction(widget.imageFile);
  }

  Future<void> _sendImageForPrediction(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('http://$apiIpAddress:5000/api/predict')
      );
      
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        final prediction = await response.stream.bytesToString();
        setState(() {
          _prediction = prediction;
          _isProcessing = false;
        });
      } else {
        throw Exception('Prediction failed with status ${response.statusCode}');
      }
    } catch (e) {
      print("Error during prediction: $e");
      setState(() {
        _prediction = "Prediction failed. Please try again.";
        _isProcessing = false;
        _hasError = true;
      });
    }
  }

  void _retakePicture() {
    Navigator.pop(context);
  }

  void _useThisImage() {
    // TODO: Implement logic to use the analyzed image
    // This could save the prediction, navigate to food logging, etc.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'AI Analysis Result',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          children: [
            // Analysis Status - Reduced spacing
            _buildAnalysisStatus(),
            const SizedBox(height: 20),

            // Image Preview - Smaller size
            _buildImagePreview(),
            const SizedBox(height: 20),

            // Prediction Result - Compact design
            _buildPredictionResult(),
            const SizedBox(height: 25),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 16),

            // Additional Info
            _buildAdditionalInfo(),
            
            // Extra space at bottom for better scrolling
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisStatus() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _isProcessing
          ? Column(
              key: const ValueKey('processing'),
              children: [
                const ShimmeringIcon(
                  icon: Icons.auto_awesome,
                  size: 50, // Reduced from 60
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 12), // Reduced from 16
                const Text(
                  "Analyzing Your Food...",
                  style: TextStyle(
                    fontSize: 20, // Reduced from 24
                    fontWeight: FontWeight.w700,
                    color: Colors.blueAccent,
                    letterSpacing: 0.6, // Reduced from 0.8
                  ),
                ),
                const SizedBox(height: 6), // Reduced from 8
                Text(
                  "Our AI is identifying nutritional content",
                  style: TextStyle(
                    fontSize: 13, // Reduced from 14
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          : Column(
              key: const ValueKey('result'),
              children: [
                Icon(
                  _hasError ? Icons.error_outline : Icons.verified,
                  size: 50, // Reduced from 60
                  color: _hasError ? Colors.orange : Colors.greenAccent[400],
                ),
                const SizedBox(height: 12), // Reduced from 16
                Text(
                  _hasError ? "Analysis Failed" : "Analysis Complete!",
                  style: TextStyle(
                    fontSize: 20, // Reduced from 24
                    fontWeight: FontWeight.w700,
                    color: _hasError ? Colors.orange : Colors.greenAccent[400],
                    letterSpacing: 0.6, // Reduced from 0.8
                  ),
                ),
                const SizedBox(height: 4), // Reduced from 8
              ],
            ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 220, // Reduced from 280
      width: 220,  // Reduced from 280
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Slightly smaller radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25), // Slightly lighter shadow
            blurRadius: 15, // Reduced from 20
            spreadRadius: 2, // Reduced from 3
            offset: const Offset(0, 6), // Reduced from 8
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 4, // Reduced from 5
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Match container radius
        child: Stack(
          children: [
            Image.file(widget.imageFile, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionResult() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Reduced padding
      margin: const EdgeInsets.symmetric(horizontal: 10), // Reduced margin
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.withOpacity(0.08), // Lighter opacity
            Colors.blueAccent.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16), // Slightly smaller
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.2), // Lighter border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08), // Lighter shadow
            blurRadius: 12, // Reduced from 15
            spreadRadius: 1, // Reduced from 2
            offset: const Offset(0, 3), // Reduced from 4
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "AI Analysis Result",
            style: TextStyle(
              fontSize: 16, // Reduced from 18
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple[800],
            ),
          ),
          const SizedBox(height: 8), // Reduced from 12
          Text(
            _prediction,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, // Reduced from 16
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple[800],
              letterSpacing: 0.2, // Reduced from 0.3
              height: 1.3, // Reduced from 1.4
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedButton(
          onPressed: _retakePicture,
          label: 'Retake',
          icon: Icons.camera_alt,
          backgroundColor: Colors.grey[600]!,
          iconColor: Colors.white,
        ),
        const SizedBox(width: 16), // Reduced from 20
        AnimatedButton(
          onPressed: _useThisImage,
          label: 'Use This Image',
          icon: Icons.check_circle,
          backgroundColor: Theme.of(context).primaryColor,
          iconColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        "You can always retake or choose another image",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11, // Reduced from 12
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// Updated Supporting Animation Widgets with smaller sizes
class ShimmeringIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const ShimmeringIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  State<ShimmeringIcon> createState() => _ShimmeringIconState();
}

class _ShimmeringIconState extends State<ShimmeringIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Slightly faster
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Faster animation
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reduced padding
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(20), // Slightly smaller
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withOpacity(0.3), // Lighter shadow
                blurRadius: 8, // Reduced from 10
                offset: const Offset(0, 3), // Reduced from 4
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.iconColor, size: 18), // Reduced from 20
              const SizedBox(width: 6), // Reduced from 8
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13, // Reduced from 14
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}