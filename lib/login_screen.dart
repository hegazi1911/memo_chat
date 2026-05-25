import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _isGuestMode = true; // Default to fast anonymous login
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final chatService = Provider.of<ChatService>(context, listen: false);

    try {
      if (_isGuestMode) {
        await chatService.signInAnonymously(_nameController.text.trim());
      } else {
        if (_isSignUp) {
          await chatService.signUpWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );
        } else {
          await chatService.signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Elegant animated-like gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.scaffoldBackgroundColor,
                  theme.colorScheme.surface,
                  theme.scaffoldBackgroundColor.withBlue(50),
                ],
              ),
            ),
          ),
          
          // Decorative glowing orbs (modern glassmorphism UI)
          Positioned(
            top: size.height * 0.15,
            left: size.width * 0.15,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.15,
            right: size.width * 0.15,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.08),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Central login card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: 440,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App Branding
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '💬',
                                style: TextStyle(fontSize: 34),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Chat Memo',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Premium Real-Time Workspace',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Toggle Mode Tabs (Guest vs Account)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isGuestMode = true;
                                        _errorMessage = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isGuestMode 
                                            ? theme.colorScheme.primary.withOpacity(0.15) 
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Guest Chat',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: _isGuestMode ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isGuestMode = false;
                                        _errorMessage = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isGuestMode 
                                            ? theme.colorScheme.primary.withOpacity(0.15) 
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Account Login',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: !_isGuestMode ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Error Display
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Interactive input fields based on active tab
                          if (_isGuestMode) ...[
                            // Guest Name Field
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                labelText: 'Enter Guest Nickname',
                                hintText: 'e.g. Alex, CyberNaut',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a nickname to join';
                                }
                                if (value.trim().length < 2) {
                                  return 'Nickname must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            // Account Name Field (if Sign Up)
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.badge_outlined),
                                  labelText: 'Display Name',
                                  hintText: 'Your name',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.mail_outline),
                                labelText: 'Email Address',
                                hintText: 'you@example.com',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline),
                                labelText: 'Password',
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
                          ],

                          const SizedBox(height: 28),

                          // Submit Action Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _isGuestMode 
                                          ? 'Join Chat' 
                                          : (_isSignUp ? 'Create Account' : 'Log In'),
                                    ),
                            ),
                          ),

                          // Footer account toggle (SignUp / SignIn toggle)
                          if (!_isGuestMode) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isSignUp = !_isSignUp;
                                      _errorMessage = null;
                                    });
                                  },
                                  child: Text(
                                    _isSignUp ? 'Log In' : 'Sign Up',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
