import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted && authProvider.error != null) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      theme.colorScheme.surface,
                      // ignore: deprecated_member_use
                      theme.colorScheme.surface.withOpacity(0.8),
                    ]
                  : [
                      // ignore: deprecated_member_use
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.surface,
                    ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // Header Section
                          Flexible(
                            flex: 3,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: const EdgeInsets.only(top: 40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // App Logo/Icon
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            // ignore: deprecated_member_use
                                            color: theme.colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.event_available,
                                        size: 60,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Welcome Text
                                    Text(
                                      'Welcome Back!',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        'Sign in to access events and rewards',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          // ignore: deprecated_member_use
                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Form Section
                          Flexible(
                            flex: 4,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                margin: const EdgeInsets.only(top: 20, bottom: 20),
                                child: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Email Field
                                          TextFormField(
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            textInputAction: TextInputAction.next,
                                            decoration: const InputDecoration(
                                              labelText: 'Email Address',
                                              hintText: 'Enter your email',
                                              prefixIcon: Icon(Icons.email_outlined),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Email is required';
                                              }

                                              final authProvider = Provider.of<AuthProvider>(
                                                context, 
                                                listen: false,
                                              );
                                              if (!authProvider.isValidEmail(value)) {
                                                return 'Enter a valid email address';
                                              }

                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),

                                          // Password Field
                                          TextFormField(
                                            controller: _passwordController,
                                            obscureText: true,
                                            textInputAction: TextInputAction.done,
                                            decoration: const InputDecoration(
                                              labelText: 'Password',
                                              hintText: 'Enter your password',
                                              prefixIcon: Icon(Icons.lock_outlined),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Password is required';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (_) => _handleLogin(),
                                          ),
                                          const SizedBox(height: 12),

                                          // Forgot Password
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Forgot password feature coming soon!'),
                                                  ),
                                                ),
                                              child: Text(
                                                'Forgot Password?',
                                                style: TextStyle(
                                                  color: theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Login Button
                                          Consumer<AuthProvider>(
                                            builder: (context, authProvider, child) {
                                              return SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: authProvider.isLoading ? null : _handleLogin,
                                                  icon: authProvider.isLoading
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        )
                                                      : const Icon(Icons.login),
                                                  label: Text(
                                                    authProvider.isLoading ? 'Signing In...' : 'Sign In',
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          const SizedBox(height: 20),

                                          // Divider
                                          Row(
                                            children: [
                                              const Expanded(child: Divider()),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                child: Text(
                                                  'OR',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    // ignore: deprecated_member_use
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                              ),
                                              const Expanded(child: Divider()),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          // Sign Up Button
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: _navigateToRegister,
                                              icon: const Icon(Icons.person_add),
                                              label: const Text('Create Account'),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
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

                          // Footer
                          Container(
                            padding: const EdgeInsets.only(bottom: 20, top: 10),
                            child: Text(
                              'Events & Rewards © 2025',
                              style: theme.textTheme.bodySmall?.copyWith(
                                // ignore: deprecated_member_use
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}