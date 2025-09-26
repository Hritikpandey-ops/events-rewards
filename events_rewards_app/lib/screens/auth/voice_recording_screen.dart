// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../providers/profile_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/loading_widget.dart';

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasRecording = false;
  Uint8List? _recordingBytes;
  String? _fileName;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final AudioRecorder _recorder = AudioRecorder();

  final String _recordingText = "Please read the following text clearly:\n\n"
      "\"I am verifying my identity for the Events and Rewards application. "
      "This is my voice sample for security purposes. Today's date is "
      "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}.\"";

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  String _generateRecordingPath() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (kIsWeb) {
      return 'voice_recording_$timestamp.wav';
    } else {
      return 'voice_recording_$timestamp.m4a';
    }
  }

  Future<void> _startRecording() async {
    _recordingTimer?.cancel();
    _pulseController.stop();

    try {
      // Check microphone permission
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission denied'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
        return;
      }


      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _hasRecording = false;
        _recordingBytes = null;
        _fileName = null;
        _recordingPath = null;
      });

      _pulseController.repeat(reverse: true);

      // Start duration timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = Duration(seconds: timer.tick);
          });
        }
      });

      final recordingPath = _generateRecordingPath();
      _recordingPath = recordingPath;
      
      await _recorder.start(
        const RecordConfig(
          encoder: kIsWeb ? AudioEncoder.wav : AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1, // Mono recording
        ),
        path: recordingPath,
      );


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Recording your voice... Speak clearly!'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      
      final path = await _recorder.stop();
      
      
      // Cancel timer and stop animations
      _recordingTimer?.cancel();
      _pulseController.stop();

      String? finalPath = path ?? _recordingPath;
      
      if (finalPath == null || finalPath.isEmpty) {
        throw Exception('No recording path available');
      }


      Uint8List? recordedBytes;
      
      if (kIsWeb) {
          
        if (finalPath.startsWith('blob:') || finalPath.startsWith('data:')) {
          
          try {
            recordedBytes = await _getWebRecordingBytes(finalPath);
          } catch (e) {
                  throw Exception('Web recording failed: $e');
          }
        } else {
          try {
            final file = File(finalPath);
            if (await file.exists()) {
              recordedBytes = await file.readAsBytes();
                    } else {
              throw Exception('Web recording file not found');
            }
          } catch (e) {
                  throw Exception('Failed to read web recording');
          }
        }
      } else {
          
        try {
          await Future.delayed(const Duration(milliseconds: 1000));
          
          final file = File(finalPath);
          bool exists = await file.exists();
          
              
          if (exists) {
            recordedBytes = await file.readAsBytes();
            int fileSize = recordedBytes.length;
            
                  
            if (fileSize == 0) {
              throw Exception('Recording file is empty');
            }
            
            try {
              await file.delete();
                    // ignore: empty_catches
                    } catch (e) {
                    }
          } else {
            throw Exception('Recording file not found at: $finalPath');
          }
        } catch (e) {
              rethrow; // Don't fall back for mobile - we want real recording
        }
      }

      if (recordedBytes.length < 1000) { // Sanity check - should be larger than 1KB
        throw Exception('Recording too short or invalid');
      }


      if (mounted) {
        setState(() {
          _isRecording = false;
          _hasRecording = true;
          _recordingBytes = recordedBytes;
          _fileName = kIsWeb 
              ? 'recording_${DateTime.now().millisecondsSinceEpoch}.wav'
              : finalPath.split('/').last;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Voice recorded successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      // Always ensure cleanup
      _recordingTimer?.cancel();
      _pulseController.stop();
    }
  }

  Future<Uint8List> _getWebRecordingBytes(String blobUrl) async {

    
    if (kIsWeb) {
      throw Exception('Web recording bytes not accessible - plugin limitation');
    }
    
    return Uint8List(0);
  }

  Future<void> _uploadVoiceRecording() async {
    if (!_hasRecording || _recordingBytes == null || _recordingBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recording available to upload'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }


    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    try {
      final success = await profileProvider.uploadVoiceBytes(_recordingBytes!);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice verification completed successfully!'),
              backgroundColor: AppColors.successColor,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileProvider.error ?? 'Upload failed'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading voice: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingBytes = null;
      _fileName = null;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Verification'),
        elevation: 0,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Voice Verification',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Instructions
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.mic,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Voice Recording',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This will record your actual voice through the microphone. Speak clearly and loudly.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Text to read
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Read this text aloud:',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _recordingText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Recording interface
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_isRecording) {
                                _stopRecording();
                              } else {
                                _startRecording();
                              }
                            },
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isRecording
                                      ? _pulseAnimation.value
                                      : 1.0,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isRecording
                                          ? AppColors.errorColor
                                          : AppColors.primaryColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isRecording
                                                  ? AppColors.errorColor
                                                  : AppColors.primaryColor)
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Status display
                          if (_isRecording) ...[
                            Text(
                              'Recording Your Voice...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDuration(_recordingDuration),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: AppColors.errorColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Speak clearly! Tap to stop when done.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (_hasRecording) ...[
                            Text(
                              'Voice Recorded!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_fileName != null) ...[
                              Text(
                                _fileName!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Duration: ${_formatDuration(_recordingDuration)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_recordingBytes != null) ...[
                                  Text(' • ',
                                      style: TextStyle(
                                          color: Colors.grey[600])),
                                  Text(
                                    'Size: ${_formatFileSize(_recordingBytes!.length)}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.errorColor,
                              ),
                              onPressed: _deleteRecording,
                              tooltip: 'Delete recording',
                            ),
                          ] else ...[
                            Text(
                              'Tap to Record Your Voice',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Real microphone recording - not simulated',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Upload button
                    if (_hasRecording)
                      CustomButton(
                        text: 'Complete Verification',
                        onPressed: profileProvider.isVoiceUploading
                            ? null
                            : _uploadVoiceRecording,
                        isLoading: profileProvider.isVoiceUploading,
                        width: double.infinity,
                        backgroundColor: AppColors.primaryColor,
                        icon: Icons.check,
                      ),
                  ],
                ),
              ),

              // Loading overlay
              if (profileProvider.isVoiceUploading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: LoadingWidget(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
