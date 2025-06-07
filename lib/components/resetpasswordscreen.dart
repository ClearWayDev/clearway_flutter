import 'package:clearway/services/authservice.dart';
import 'package:clearway/widgets/inputfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:clearway/utils/firebase_error.dart';
import 'package:clearway/utils/top_snackbar.dart';
import 'package:clearway/providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _mailSent = false;

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());

      setState(() => _mailSent = true);
      showTopSnackBar(context, 'Password reset link sent', type: TopSnackBarType.success);
    } on FirebaseAuthException catch (e) {
      final message = getFirebaseAuthErrorMessage(e);
      showTopSnackBar(context, 'Error: $message', type: TopSnackBarType.error);
    } catch (e) {
      showTopSnackBar(context, 'Error: ${e.toString()}', type: TopSnackBarType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final bool isLoggedIn = authState.asData?.value != null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Back Button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Main content scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        isLoggedIn
                            ? "Reset Password"
                            : "Forgot Password?",
                        style: GoogleFonts.urbanist(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E232C),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Conditional Description
                      Text(
                        isLoggedIn
                            ? "You can reset your password here by entering your account email."
                            : "Don't worry! It occurs. Please enter the email address linked with your account.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: const Color(0xFF8391A1),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Input
                      styledInputField(
                        label: 'Email',
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$')
                              .hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Send Mail Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendResetLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E232C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _mailSent ? 'Resend Email' : 'Send Mail',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Link (Conditional)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TextButton(
                onPressed: () {
                  if (isLoggedIn) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/signin');
                  }
                },
                child: Text.rich(
                  TextSpan(
                    text: isLoggedIn ? "Go back to " : "Remember Password? ",
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: isLoggedIn ? "Profile" : "Login",
                        style: GoogleFonts.urbanist(
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
