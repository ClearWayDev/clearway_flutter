import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum UserType { blind, volunteer }

class SignupFlowScreen extends StatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  State<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends State<SignupFlowScreen> {
    final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureCPassword = true;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();

  UserType? _accountType;

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else 
    {            
    Navigator.pop(context);
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/signin');
  }
  
  Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;
  _nextStep();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _currentStep,
          children: [
            _buildAccountTypeStep(),
            _buildSignupFormStep(),
            _buildPrivacyStep(),
            _buildMediaAccessStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeStep() => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Top Back Button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousStep,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
                        'Your Account Type ?',
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

            const Spacer(),

            // User Button
            SizedBox(
              width: 331,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _accountType = UserType.blind;
                  });
                  _nextStep();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Register As a User',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Assistant Button
            SizedBox(
              width: 331,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _accountType = UserType.volunteer;
                  });
                  _nextStep();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Register As an Assistant',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Bottom Link
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton(
                onPressed: _goToLogin,
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: "Login Now",
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
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



Widget _buildSignupFormStep() => Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                    _previousStep();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
                        'Register to get started',
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
           
            const SizedBox(height: 40),

            // Username Field
            _styledInputField(
              label: 'Username',
              controller: _nameController,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a username' : null,
            ),
            const SizedBox(height: 16),

            // Email Field
            _styledInputField(
              label: 'Email',
              controller: _emailController,
              validator: (value) => value != null && value.contains('@')
                  ? null
                  : 'Enter a valid email',
            ),
            const SizedBox(height: 16),

            // Password Field
            _styledInputField(
              label: 'Password',
              controller: _passwordController,
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password too short';
                }
                final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$');
                if (!regex.hasMatch(value)) {
                  return 'Use upper, lower, number (min 6 chars)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            _styledInputField(
              label: 'Confirm password',
              controller: _confirmController,
              obscure: _obscureCPassword,
              suffixIcon: IconButton(
                icon: Icon(_obscureCPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscureCPassword = !_obscureCPassword;
                  });
                },
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Register Button
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E232C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Register',
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const Spacer(),

            // Already have account
            Center(
              child: TextButton(
                onPressed: _goToLogin,
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: "Login Now",
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
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


  Widget _buildPrivacyStep() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Privacy & Terms',
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E232C),
                ),
                onPressed: _nextStep,
                child: const Text('I Agree'),
              ),
            ),
            const SizedBox(height: 32)
          ],
        ),
      );

  Widget _buildMediaAccessStep() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Hardware Access',
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 24),
            Image.asset('assets/image/app-permission.png', height: 200),
            const SizedBox(height: 16),
            const Text(
              'Microphone, Camera & Bluetooth',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'To make video calls, give access to your microphone & camera. To use Bluetooth devices, please give access to Bluetooth.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {},
                child: const Text('Give Access'),
              ),
            )
          ],
        ),
      );

  
Widget _styledInputField({
  required String label,
  required TextEditingController controller,
  bool obscure = false,
  Widget? suffixIcon,
  String? Function(String?)? validator,
}) {
  return Container(
    height: 56,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Center(
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    ),
  );
}
}
