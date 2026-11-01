import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _userService = UserService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Academic level fields (FR-01)
  EducationType _educationType = EducationType.school;
  String _schoolGrade = '11th (FSc Part 1)';
  String _schoolCourse = 'Pre-Medical';
  final _universityController = TextEditingController(text: 'Virtual University');
  final _programController = TextEditingController(text: 'BS Computer Science');

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _universityController.dispose();
    _programController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await _authService.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showCustomSnackBar(message: error, isError: true);
    } else {
      // Save academic profile (FR-01)
      _userService.updateProfile(
        name: _nameController.text.trim(),
        educationType: _educationType,
        schoolGrade: _schoolGrade,
        schoolCourse: _schoolCourse,
        universityName: _universityController.text.trim(),
        program: _programController.text.trim(),
      );

      _showCustomSnackBar(
        message: 'Account created successfully! Welcome to Learnozi.',
        isError: false,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showCustomSnackBar({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Ambient Glow Background Orbs (Tech Aura)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF818CF8).withValues(alpha: 0.35),
                    const Color(0xFF818CF8).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA855F7).withValues(alpha: 0.25),
                    const Color(0xFFA855F7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Row with Sleek Back Button & Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: const Color(0xFFC7D2FE)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: 13,
                                      color: Color(0xFF4F46E5),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Get Started Free',
                                      style: TextStyle(
                                        color: Color(0xFF4F46E5),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Heading & Subtitle
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Join Learnozi to personalize and supercharge your study routine',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Full Name Input
                          _buildFieldLabel('Full Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            validator: _validateName,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(
                              hint: 'e.g. Sarah Jenkins',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email Input
                          _buildFieldLabel('Email Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(
                              hint: 'e.g. sarah@study.edu',
                              icon: Icons.mail_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Academic Profile Setup
                          _buildFieldLabel('Academic Level & Track'),
                          const SizedBox(height: 6),
                          SegmentedButton<EducationType>(
                            segments: const [
                              ButtonSegment(
                                value: EducationType.school,
                                label: Text('School/College', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.school_rounded, size: 16),
                              ),
                              ButtonSegment(
                                value: EducationType.university,
                                label: Text('University', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.account_balance_rounded, size: 16),
                              ),
                            ],
                            selected: {_educationType},
                            onSelectionChanged: (val) {
                              setState(() => _educationType = val.first);
                            },
                          ),
                          const SizedBox(height: 10),

                          if (_educationType == EducationType.school) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _schoolGrade,
                              decoration: _buildInputDecoration(
                                hint: 'Select Class/Grade',
                                icon: Icons.grade_rounded,
                              ),
                              items: ['9th (Matric)', '10th (Matric)', '11th (FSc Part 1)', '12th (FSc Part 2)']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _schoolGrade = val);
                              },
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _schoolCourse,
                              decoration: _buildInputDecoration(
                                hint: 'Select Course Track',
                                icon: Icons.category_rounded,
                              ),
                              items: ['Pre-Medical', 'Pre-Engineering', 'Computer Science', 'Commerce']
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _schoolCourse = val);
                              },
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _universityController,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                              decoration: _buildInputDecoration(
                                hint: 'University Name',
                                icon: Icons.business_rounded,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _programController,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                              decoration: _buildInputDecoration(
                                hint: 'Program & Semester (e.g. BSCS Sem 4)',
                                icon: Icons.book_rounded,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Password Input
                          _buildFieldLabel('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                            onChanged: (_) => setState(() {}),
                            decoration: _buildInputDecoration(
                              hint: 'At least 6 characters',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password Input
                          _buildFieldLabel('Confirm Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            validator: _validateConfirmPassword,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleRegister(),
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(
                              hint: 'Re-enter your password',
                              icon: Icons.shield_outlined,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Gradient Sign Up Button
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Terms / Privacy note
                          const Text(
                            'By creating an account, you agree to Learnozi\'s Terms of Service and Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF94A3B8),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Switch to Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.8),
      ),
    );
  }
}
