import 'package:flutter/material.dart';

// StatefulWidget since we need to maintain state
class TutorialOverlay extends StatefulWidget {
  // parentContext allows access to the parent screen's context if needed
  final BuildContext parentContext;

  // Constructor with required parentContext parameter
  const TutorialOverlay({
    super.key,
    required this.parentContext,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentStep = 0;
  final List<Map<String, String>> _tutorialSteps = [
    {
      'title': 'Welcome!',
      'description': 'Let\'s show you around.',
    },
    {
      'title': 'Find Parking',
      'description': 'Get parking recommendations based on your needs.',
    },
    {
      'title': 'Preferences',
      'description': 'Set your parking preferences here.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildTapAnimation() {
    // Get screen size for positioning
    final size = MediaQuery.of(widget.parentContext).size;
    
    // Define positions for different tutorial steps
    Offset position;
    switch (_currentStep) {
      case 1: // Start Parking - center of screen
        position = Offset(size.width / 2, size.height / 1.8);
      case 2: // Update Preferences - bottom left
        position = Offset(size.width * 0.25, size.height * 0.9);
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      left: position.dx - 30,
      top: position.dy - 30,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(1 - _animationController.value),
                width: 3,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.touch_app,
                color: Colors.white,
                size: 30,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        
        // Tutorial card
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(
              left: 48,
              right: 48,
              // Move card up during "Start Parking" step
              top: _currentStep == 1 ? 48 : 48,
              bottom: _currentStep == 1 ? MediaQuery.of(context).size.height * 0.5 : 48,
            ),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tutorialSteps[_currentStep]['title']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tutorialSteps[_currentStep]['description']!,
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentStep--;
                              });
                            },
                            child: const Text('Previous'),
                          ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            if (_currentStep < _tutorialSteps.length - 1) {
                              setState(() {
                                _currentStep++;
                              });
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(_currentStep < _tutorialSteps.length - 1 ? 'Next' : 'Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Tap animation
        _buildTapAnimation(),
      ],
    );
  }
} 