import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/activity/providers/activity_providers.dart';
import '../../domain/models/user.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            // User is authenticated, navigate to home dashboard
            context.go('/home');
          }
        },
        loading: () {},
        error: (error, stackTrace) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication error: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and title
              const Icon(
                Icons.sync,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'SyncLife',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Collaborative task management with gamification',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Social login buttons
              _buildSocialLoginButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              _buildSocialLoginButton(
                onPressed: _isLoading ? null : _signInWithApple,
                icon: Icons.apple,
                label: 'Continue with Apple',
                color: Colors.black,
              ),
              
              const SizedBox(height: 32),
              
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 32),

              // Email/Password form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Login/Register button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Toggle between login and register
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin 
                            ? "Don't have an account? Sign up"
                            : "Already have an account? Sign in",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      
      if (user != null) {
        // Create user profile with automatic region/timezone detection
        await authService.createUserProfile(user.id);
        
        // Log login activity
        final activityLogger = ref.read(activityLoggerProvider);
        await activityLogger.logLogin(user.id);
      }
    } catch (e) {
      _showErrorMessage('Google sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithApple();
      
      if (user != null) {
        // Create user profile with automatic region/timezone detection
        await authService.createUserProfile(user.id);
        
        // Log login activity
        final activityLogger = ref.read(activityLoggerProvider);
        await activityLogger.logLogin(user.id);
      }
    } catch (e) {
      _showErrorMessage('Apple sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      User? user;
      if (_isLogin) {
        user = await authService.signInWithEmail(email, password);
        
        if (user != null) {
          // Log login activity
          final activityLogger = ref.read(activityLoggerProvider);
          await activityLogger.logLogin(user.id);
        }
      } else {
        user = await authService.signUpWithEmail(email, password);
        
        if (user != null) {
          // Create user profile for new users
          await authService.createUserProfile(user.id);
          
          // Log login activity for new users too
          final activityLogger = ref.read(activityLoggerProvider);
          await activityLogger.logLogin(user.id);
        }
      }

      if (user == null) {
        _showErrorMessage('Authentication failed. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('${_isLogin ? 'Sign in' : 'Sign up'} failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}