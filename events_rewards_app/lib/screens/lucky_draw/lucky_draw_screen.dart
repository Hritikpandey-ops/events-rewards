// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../providers/rewards_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/models/reward_model.dart';

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
  DateTime? _lastSpinTime;
  bool _isLoadingData = false;

  // Dynamic rewards from backend
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _setupAnimations() {
    _wheelController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Faster base animation
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600), 
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3, 
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingData = true;
    });

    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    
    try {
      await rewardsProvider.refreshAllData();
      
      if (mounted) {
        setState(() {
          _spinsLeft = rewardsProvider.spinsLeft;
          _canSpin = rewardsProvider.canSpinToday && !_isSpinning;
          _lastSpinTime = rewardsProvider.lastSpin;
          
          if (rewardsProvider.userRewards.isNotEmpty) {
            final latestReward = rewardsProvider.userRewards.first;
            _lastReward = latestReward.reward?.name;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _spinsLeft = 3;
          _canSpin = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using offline mode - some features may be limited'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Smooth continuous spinning animation
  void _startContinuousSpinning() {
    _wheelController.stop();
    _wheelController.duration = const Duration(milliseconds: 800); // Fast spinning
    _wheelController.repeat();
  }

  // Smooth deceleration to final position
  Future<void> _decelerateToFinalPosition(int targetSegment) async {
    _wheelController.stop();
    
    // Calculate final position with dramatic extra spins
    final segments = _rewards.length;
    final segmentAngle = 1.0 / segments;
    
    // Add 5-8 full rotations for dramatic effect
    final random = Random();
    final extraSpins = 5 + random.nextInt(4); // 5 to 8 extra spins
    final finalPosition = (targetSegment * segmentAngle) + (segmentAngle * 0.5);
    final totalRotation = extraSpins + finalPosition;
    
    // Smooth deceleration with longer duration
    _wheelController.duration = const Duration(milliseconds: 4000);
    
    await _wheelController.animateTo(
      totalRotation,
      curve: _CustomDecelerationCurve(), // Custom smooth deceleration
    );
  }

  Future<void> _spinWheel() async {
    if (!_canSpin || _isSpinning) return;
    
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    
    setState(() {
      _isSpinning = true;
      _canSpin = false;
    });

    try {
      // Reset controller for clean start
      _wheelController.reset();
      
      // Start smooth continuous spinning immediately
      _startContinuousSpinning();
      
      // Start backend call while wheel spins continuously
      final spinFuture = rewardsProvider.spinWheel();
      
      // Wait for server response while wheel keeps spinning
      final SpinResponse? spinResponse = await spinFuture;
      
      if (spinResponse != null && mounted) {
        // Get random target segment for visual effect
        final random = Random();
        final targetSegment = random.nextInt(_rewards.length);
        
        // Smoothly decelerate to final position
        await _decelerateToFinalPosition(targetSegment);
        
        // Update state after wheel stops
        setState(() {
          _lastReward = spinResponse.reward?.name ?? 'Better Luck Next Time';
          _spinsLeft = rewardsProvider.spinsLeft;
          _canSpin = rewardsProvider.canSpinToday;
          _lastSpinTime = DateTime.now();
          _isSpinning = false;
        });

        // Bounce animation for reward display
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        
        // Small delay before showing dialog for better UX
        await Future.delayed(const Duration(milliseconds: 800));
        _showRewardDialog(spinResponse);
        
      } else {
        // Handle spin failure - stop spinning smoothly
        await _stopSpinningGracefully();
        
        if (mounted) {
          setState(() {
            _isSpinning = false;
            _canSpin = rewardsProvider.canSpinToday;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(rewardsProvider.error ?? 'Failed to spin wheel'),
              backgroundColor: AppColors.errorColor,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _loadInitialData,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Spin error: $e');
      
      // Stop spinning gracefully on error
      await _stopSpinningGracefully();
      
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _canSpin = _spinsLeft > 0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _stopSpinningGracefully() async {
    _wheelController.stop();
    
    // Add one more smooth rotation to stop naturally
    final currentValue = _wheelController.value;
    await _wheelController.animateTo(
      currentValue + 1.0,
      duration: const Duration(milliseconds: 1500),
      curve: Curves.decelerate,
    );
  }

  void _showRewardDialog(SpinResponse spinResponse) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          spinResponse.isNoReward ? 'Better Luck Next Time!' : 'Congratulations!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              spinResponse.isNoReward ? 'No reward this time' : 'You won:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: spinResponse.isNoReward
                    ? Colors.grey.withOpacity(0.1)
                    : AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                spinResponse.reward?.name ?? 'Better Luck Next Time',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: spinResponse.isNoReward
                      ? Colors.grey
                      : AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (spinResponse.claimCode != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.successColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Claim Code:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      spinResponse.claimCode!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Save this code to claim your reward later!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          CustomButton(
            text: spinResponse.isNoReward ? 'Try Again' : 'Awesome!',
            onPressed: () => Navigator.of(context).pop(),
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _bounceController.dispose();
    super.dispose();
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
            child: Row(
              children: [
                if (_isLoadingData)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Chip(
                    label: Text(
                      '$_spinsLeft spins left',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: _spinsLeft > 0
                        ? AppColors.successColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoadingData ? null : _loadInitialData,
                  tooltip: 'Refresh data',
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<RewardsProvider>(
        builder: (context, rewardsProvider, child) {
          return RefreshIndicator(
            onRefresh: _loadInitialData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  
                  // Spin statistics
                  if (_lastSpinTime != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Last spin: ${_formatLastSpinTime(_lastSpinTime!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 48),

                  // Spinning wheel
                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Wheel with smooth animation
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

                          // Center spin button
                          GestureDetector(
                            onTap: _spinWheel,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _canSpin && _spinsLeft > 0 && !_isLoadingData
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(_isSpinning ? 0.4 : 0.2),
                                    blurRadius: _isSpinning ? 15 : 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isSpinning
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    )
                                  : const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                            ),
                          ),

                          // Pointer
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

                  // Latest reward display
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

                  // Spin button
                  CustomButton(
                    text: _isLoadingData
                        ? 'Loading...'
                        : _spinsLeft > 0 
                            ? 'SPIN NOW!' 
                            : 'No Spins Left',
                    onPressed: (_canSpin && 
                                _spinsLeft > 0 && 
                                !_isSpinning && 
                                !_isLoadingData)
                        ? _spinWheel
                        : null,
                    isLoading: _isSpinning,
                    width: double.infinity,
                    backgroundColor: _spinsLeft > 0 
                        ? AppColors.primaryColor 
                        : Colors.grey,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _isLoadingData
                        ? 'Syncing with server...'
                        : _spinsLeft > 0
                            ? 'You have $_spinsLeft spins remaining today'
                            : 'Come back tomorrow for more spins!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Error display
                  if (rewardsProvider.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.errorColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rewardsProvider.error!,
                              style: const TextStyle(
                                color: AppColors.errorColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatLastSpinTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Custom deceleration curve for smoother wheel stopping
class _CustomDecelerationCurve extends Curve {
  @override
  double transform(double t) {
    // Custom curve that starts fast and decelerates smoothly
    return 1 - pow(1 - t, 3).toDouble();
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

      // Draw divider line
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
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
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

    // Draw center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.1, centerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}