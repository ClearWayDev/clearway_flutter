import 'package:clearway/constants/policies.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clearway/widgets/inputfield.dart';
import 'package:clearway/widgets/policypopup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clearway/providers/fcm_token_state.dart';
import 'package:clearway/services/authservice.dart';
import 'package:clearway/providers/user_state.dart';
import 'package:clearway/providers/auth_provider.dart';

import 'package:clearway/models/user.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:clearway/utils/firebase_error.dart';
import 'package:clearway/utils/top_snackbar.dart';
import 'package:latlong2/latlong.dart';
import 'package:clearway/widgets/location_picker.dart';
import 'package:clearway/services/imagedescription.dart';
import 'package:clearway/constants/tts_messages.dart';

class SignupFlowScreen extends ConsumerStatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  ConsumerState<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends ConsumerState<SignupFlowScreen> {
      @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 500), () {
    // Describe the screen
    ImageDescriptionService().speak(TtsMessages.signupScreen);
  });
  }

    final _formKey = GlobalKey<FormState>();
    final _authService = AuthService();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureCPassword = true;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();

   // Location variables
  LatLng? _selectedLocation;
  String _locationText = 'Enter a familiar location for guidance.';
  bool _showLocationPicker = false;
  String? _locationValidationError;

  UserType? _accountType;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else 
    { 
    ImageDescriptionService().stopSpeak();
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context);
    });
  }
  }

 void _openLocationPicker() {
    setState(() {
      _showLocationPicker = true;
    });
  }

  void _closeLocationPicker() {
    setState(() {
      _showLocationPicker = false;
    });
  }

  void _onLocationSelected(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _locationText = 'Lat: ${location.latitude.toStringAsFixed(4)}, '
                      'Lng: ${location.longitude.toStringAsFixed(4)}';
      _showLocationPicker = false; // Close popup after selection
    });
  }


  void _goToLogin() {
     ImageDescriptionService().stopSpeak();
        Future.delayed(const Duration(milliseconds: 500), () {
    Navigator.pushReplacementNamed(context, '/signin');
    });
  }
  
void _validateform() {
  bool isFormValid = true;
  
  // Clear previous location validation error
  setState(() {
    _locationValidationError = null;
  });
  
  // Validate form fields
  if (!(_formKey.currentState?.validate() ?? false)) {
    isFormValid = false;
  }
  
  // Validate location for blind users
  if (_accountType == UserType.blind && _selectedLocation == null) {
    setState(() {
      _locationValidationError = 'Location is required for accessibility services';
    });
    isFormValid = false;
  }
  
  if (isFormValid) {
    // Proceed with registration
    _nextStep();
  }
}


 Future<void> _register() async {
       ImageDescriptionService().stopSpeak();
    setState(() => _isLoading = true);

  try {
    final fcmToken = ref.watch(fcmTokenProvider) ?? '';
    final user = await _authService.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
      _accountType!,
      fcmToken,
      _selectedLocation,
    );

    if (user != null) {
      // Set user info in Riverpod state
      ref.read(userProvider.notifier).setUser(user);
      showTopSnackBar(context, 'User registered successfully!', type: TopSnackBarType.success);
      // Navigate to next step
        _dashboardAccess();
    }
  } on FirebaseAuthException catch (e) {
    final message = getFirebaseAuthErrorMessage(e);
    showTopSnackBar(context, 'Signup Failed: $message', type: TopSnackBarType.error);
  } catch (e) {
    showTopSnackBar(context, 'Signup Failed: ${e.toString()}', type: TopSnackBarType.error);
  } finally {
    setState(() => _isLoading = false);
  }
}
Future<void> _dashboardAccess() async {
      final authState = ref.watch(authStateProvider).value;
      final userState = ref.watch(userProvider);
  if (authState != null) {
      if(userState?.userType == UserType.blind){
       Navigator.pushNamedAndRemoveUntil(context, '/dashboard/blind/home', (route) => false);
        } else {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard/guide/home', (route) => false);
      }
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _currentStep,
          children: [
            _buildAccountTypeStep(),
            _buildSignupFormStep(),
            _buildPrivacyStep(),
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
                  'Register As a Volunteer',
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



Widget _buildSignupFormStep() => Stack(
      children: [
        // Your existing form (wrapped in Stack)
        Padding(
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
                styledInputField(
                  label: 'Username',
                  controller: _nameController,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Enter a username' : null,
                ),
                const SizedBox(height: 16),

                // Email Field
                styledInputField(
                  label: 'Email',
                  controller: _emailController,
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : 'Enter a valid email',
                ),
                const SizedBox(height: 16),

                // Password Field
                styledInputField(
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
                styledInputField(
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

                // Location Selection for Blind Users Only
                if (_accountType == UserType.blind) ...[
                  const SizedBox(height: 16),
                  
                  // Location Selection Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _locationValidationError != null 
                            ? Colors.red 
                            : Colors.grey.shade300
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: _openLocationPicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: _selectedLocation != null ? Colors.teal : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Location *',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _locationText,
                                    style: GoogleFonts.urbanist(
                                      fontSize: 14,
                                      color: _selectedLocation != null 
                                          ? Colors.black 
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Location Validation Error
                  if (_locationValidationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16),
                      child: Text(
                        _locationValidationError!,
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 32),

                // Register Button
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateform,
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
        ),
        
        // Location Picker Overlay (conditionally shown)
        if (_showLocationPicker)
          LocationPickerOverlay(
            initialLocation: _selectedLocation,
            onLocationSelected: _onLocationSelected,
            onClose: _closeLocationPicker,
          ),
      ],
    );

  Widget _buildPrivacyStep() => GestureDetector(
      // Add this to dismiss keyboard when tapping anywhere
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Back Button (top-left)
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // Dismiss keyboard before navigating back
                    FocusScope.of(context).unfocus();
                    _previousStep();
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                'Privacy & Terms',
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

              const SizedBox(height: 16),

              // Intro text
              const Text(
                'To use ClearWay, you agree to the following,',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/icon/camera-icon.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ClearWay can record, review, and share videos and images for safety, quality, and as further described in the Privacy Policy.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF4F5D73),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Terms & Privacy Buttons in column
              Column(
                children: [
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Ensure keyboard is dismissed before showing popup
                        FocusScope.of(context).unfocus();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          showPolicyPopup(
                            context: context,
                            title: 'Terms of Service',
                            content: termsOfService,
                          );
                        });
                      },
                      child: const Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: Color(0xFF1E232C),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Ensure keyboard is dismissed before showing popup
                        FocusScope.of(context).unfocus();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          showPolicyPopup(
                            context: context,
                            title: 'Privacy Policy',
                            content: privacyPolicy,
                          );
                        });
                      },
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFF1E232C),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Disclaimer text above button
              const Text(
                'By clicking "I agree", I agree to everything above and accept the Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF2E2E43),
                ),
              ),

              const SizedBox(height: 16),

              // I Agree button
              SizedBox(
                width: 331,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E232C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : () {
                    // Dismiss keyboard before registering
                    FocusScope.of(context).unfocus();
                    _register();
                  },
                  child: const Text(
                    'I Agree',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
}


