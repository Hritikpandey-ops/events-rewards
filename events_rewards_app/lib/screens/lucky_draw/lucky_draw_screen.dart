// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_button.dart';

class LuckyDrawScreen extends StatefulWidget {
  const LuckyDrawScreen({super.key});

  @override
  State<LuckyDrawScreen> createState() => _LuckyDrawScreenState();
}

class _LuckyDrawScreenState extends State<LuckyDrawScreen>
    with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  bool _isSpinning = false;
  bool _canSpin = true;
  int _spinsLeft = 3;
  String? _lastReward;

  final List<String> _rewards = [
    '100 Points',
    'Free Coffee',
    '50 Points',
    'Discount Coupon',
    '200 Points',
    'Better Luck Next Time',
    '25 Points',
    'Special Gift',
  ];

  final List<Color> _rewardColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSpinsLeft();
  }

  void _setupAnimations() {
    _wheelController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _loadSpinsLeft() {
    // In real app, load from storage or API
    setState(() {
      _spinsLeft = 3; // Example value
    });
  }

  Future<void> _spinWheel() async {
    if (!_canSpin || _spinsLeft <= 0 || _isSpinning) return;

    setState(() {
      _isSpinning = true;
      _canSpin = false;
    });

    final random = Random();
    final extraSpins = 3 + random.nextInt(3); // 3-5 full rotations
    final finalPosition = random.nextDouble(); // Random final position
    final totalRotation = extraSpins + finalPosition;

    await _wheelController.animateTo(totalRotation);

    final rewardIndex =
        (finalPosition * _rewards.length).floor() % _rewards.length;
    final reward = _rewards[rewardIndex];

    setState(() {
      _isSpinning = false;
      _spinsLeft--;
      _lastReward = reward;
    });

    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    _showRewardDialog(reward);

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _canSpin = _spinsLeft > 0;
    });
  }

  void _showRewardDialog(String reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '🎉 Congratulations!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You won:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reward,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Awesome!',
            onPressed: () => Navigator.of(context).pop(),
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Lucky Draw'),
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode
            ? Colors.grey[900]
            : AppColors.primaryColor.withOpacity(0.1),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(
                '$_spinsLeft spins left',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Spin the Wheel!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try your luck and win amazing rewards',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _wheelController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _wheelController.value * 2 * pi,
                              child: CustomPaint(
                                size: const Size(300, 300),
                                painter: WheelPainter(
                                  rewards: _rewards,
                                  colors: _rewardColors,
                                ),
                              ),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: _spinWheel,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _canSpin && _spinsLeft > 0
                                  ? AppColors.primaryColor
                                  : Colors.grey,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isSpinning
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          child: Container(
                            width: 0,
                            height: 0,
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  width: 15,
                                  color: Colors.transparent,
                                ),
                                right: BorderSide(
                                  width: 15,
                                  color: Colors.transparent,
                                ),
                                bottom: BorderSide(
                                  width: 30,
                                  color: AppColors.errorColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                if (_lastReward != null)
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bounceAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.successColor,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Latest Win:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _lastReward!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 32),
                CustomButton(
                  text: _spinsLeft > 0 ? 'SPIN NOW!' : 'No Spins Left',
                  onPressed: (_canSpin && _spinsLeft > 0 && !_isSpinning)
                      ? _spinWheel
                      : null,
                  isLoading: _isSpinning,
                  width: double.infinity,
                  backgroundColor:
                      _spinsLeft > 0 ? AppColors.primaryColor : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _spinsLeft > 0
                      ? 'You have $_spinsLeft spins remaining today'
                      : 'Come back tomorrow for more spins!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> rewards;
  final List<Color> colors;

  WheelPainter({required this.rewards, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectionAngle = 2 * pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final startAngle = i * sectionAngle - pi / 2;
      final endAngle = startAngle + sectionAngle;

      // Draw section
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectionAngle,
        true,
        paint,
      );

      // Draw divider line at endAngle
      final dividerPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2;
      final lineEnd = Offset(
        center.dx + cos(endAngle) * radius,
        center.dy + sin(endAngle) * radius,
      );
      canvas.drawLine(center, lineEnd, dividerPaint);

      // Draw text
      final textAngle = startAngle + sectionAngle / 2;
      final textRadius = radius * 0.7;
      final textCenter = Offset(
        center.dx + cos(textAngle) * textRadius,
        center.dy + sin(textAngle) * textRadius,
      );

      canvas.save();
      canvas.translate(textCenter.dx, textCenter.dy);
      canvas.rotate(textAngle + pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: rewards[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
