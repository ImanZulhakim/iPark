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

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
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
      'title': 'Change Parking Lot',
      'description': 'Click here to change the parking lot.',
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
      case 1: // Find Parking - center of screen
        position =
            Offset(size.width / 2, size.height / 1.9); // Adjusted to be lower
      case 2: // Change Parking Lot - above the tutorial card
        // Calculate the position of the tutorial card
        const cardTop = 220.0; // Adjusted top margin of the card
        // Position the animation slightly above the card
        position = Offset(size.width * 0.6, cardTop - 60); // Adjusted to the right
      case 3: // Update Preferences - bottom left
        position = Offset(size.width * 0.18, size.height * 0.9); // Adjusted to the left
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
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Tutorial card
        Positioned(
          top: _currentStep == 0 || _currentStep == 3
              ? size.height *
                  0.4 // Middle of the screen for "Welcome" and "Preferences"
              : _currentStep == 1
                  ? size.height * 0.18 // Lower for "Find Parking"
                  : 200, // Adjusted to move "Change Parking Lot" card lower
          left: 48,
          right: 48,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
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
                          child: Text(_currentStep < _tutorialSteps.length - 1
                              ? 'Next'
                              : 'Done'),
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
