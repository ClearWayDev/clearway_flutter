import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clearway/services/authservice.dart';
import 'package:clearway/widgets/inputfield.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/providers/fcm_token_state.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:clearway/utils/firebase_error.dart';

class SigninScreen extends ConsumerStatefulWidget  {
  const SigninScreen({super.key});

  @override
  ConsumerState<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends ConsumerState<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final fcmToken = ref.watch(fcmTokenProvider) ?? '';
    final user = await _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      fcmToken,
    );

    if (user != null) {
      // Set user info in Riverpod state
      ref.read(userProvider.notifier).setUser(user);

      // Navigate to dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  } on FirebaseAuthException catch (e) {
    final message = getFirebaseAuthErrorMessage(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign In Failed: $message')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign In Failed: ${e.toString()}')),
    );
  }finally {
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 20),
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Welcome Text
                      Text(
                        'Welcome back! Glad\nto see you, Again!',
                        style: GoogleFonts.urbanist(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: -0.01,
                          color: const Color(0xFF1E232C),
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Color(0x40000000),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                     // Email Field
styledInputField(
  label: 'Enter your email',
  controller: _emailController,
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  },
),

const SizedBox(height: 20),

// Password Field
styledInputField(
  label: 'Enter your password',
  controller: _passwordController,
  obscure: _obscurePassword,
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    } else if (value.length < 6) {
      return 'Password too short';
    }
    return null;
  },
  suffixIcon: IconButton(
    icon: Icon(
      _obscurePassword ? Icons.visibility_off : Icons.visibility,
      color: Colors.grey.shade600,
    ),
    onPressed: () {
      setState(() => _obscurePassword = !_obscurePassword);
    },
  ),
),

                      const SizedBox(height: 12),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                           onPressed: () {
                            Navigator.pushNamed(context, '/forgot-password');
                            },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: const Color(0xFF6A707C),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Login Button
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E232C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Login',
                                  style: GoogleFonts.urbanist(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Text
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text.rich(
                  TextSpan(
                    text: "Don’t have an account? ",
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: 'Register Now',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


