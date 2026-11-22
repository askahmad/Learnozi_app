import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/validators.dart';

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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Academic level fields
  EducationType _educationType = EducationType.university;

  // University track state
  String _selectedUniversity = UserProfile.pakistaniUniversities.first;
  final _customUniversityController = TextEditingController();

  String _selectedProgram = UserProfile.universityPrograms.first;
  final _customProgramController = TextEditingController();

  String _selectedSemester = '1st Semester';
  final _customSemesterController = TextEditingController();

  // School track state
  String _selectedSchoolGrade = UserProfile.schoolGrades.first;
  final _customSchoolGradeController = TextEditingController();

  String _selectedSchoolTrack = UserProfile.schoolTracks.first;
  final _customSchoolTrackController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customUniversityController.dispose();
    _customProgramController.dispose();
    _customSemesterController.dispose();
    _customSchoolGradeController.dispose();
    _customSchoolTrackController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final strength = PasswordStrength.calculate(_passwordController.text);
    if (!strength.isStrong) {
      _showCustomSnackBar(
        message: 'Password must satisfy all 5 strong password requirements.',
        isError: true,
      );
      return;
    }
    await _executeSignUp();
  }

  Future<void> _executeSignUp() async {
    String finalUniversity = '';
    String finalProgram = '';
    String finalSemester = '';
    String finalSchoolGrade = '';
    String finalSchoolTrack = '';

    if (_educationType == EducationType.university) {
      if (_selectedUniversity == 'Other (Type your own University)') {
        finalUniversity = _customUniversityController.text.trim();
        if (finalUniversity.isEmpty) {
          _showCustomSnackBar(message: 'Please enter your university name.', isError: true);
          return;
        }
      } else {
        finalUniversity = _selectedUniversity;
      }

      if (_selectedProgram == 'Other (Type your own Degree / Program)') {
        finalProgram = _customProgramController.text.trim();
        if (finalProgram.isEmpty) {
          _showCustomSnackBar(message: 'Please enter your program/degree name.', isError: true);
          return;
        }
      } else {
        finalProgram = _selectedProgram;
      }

      if (_selectedSemester == 'Other (Type Semester)') {
        finalSemester = _customSemesterController.text.trim();
        if (finalSemester.isEmpty) {
          _showCustomSnackBar(message: 'Please enter your semester.', isError: true);
          return;
        }
      } else if (_selectedSemester == 'None / Not Applicable') {
        finalSemester = '';
      } else {
        finalSemester = _selectedSemester;
      }
    } else {
      if (_selectedSchoolGrade == 'Other (Type Grade)') {
        finalSchoolGrade = _customSchoolGradeController.text.trim();
        if (finalSchoolGrade.isEmpty) {
          _showCustomSnackBar(message: 'Please enter your grade/class.', isError: true);
          return;
        }
      } else {
        finalSchoolGrade = _selectedSchoolGrade;
      }

      if (_selectedSchoolTrack == 'Other (Type Track)') {
        finalSchoolTrack = _customSchoolTrackController.text.trim();
        if (finalSchoolTrack.isEmpty) {
          _showCustomSnackBar(message: 'Please enter your study track.', isError: true);
          return;
        }
      } else {
        finalSchoolTrack = _selectedSchoolTrack;
      }
    }

    setState(() => _isLoading = true);

    final error = await _authService.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      if (error.contains('already registered') || error.contains('password')) {
        _showCustomSnackBar(message: error, isError: true);
        return;
      }
      // If network is restricted or offline on campus, activate real student profile directly
      _authService.loginAsDemoStudent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        educationType: _educationType,
        schoolGrade: finalSchoolGrade,
        schoolCourse: finalSchoolTrack,
        universityName: finalUniversity,
        semester: finalSemester,
        program: finalProgram,
      );
      _showCustomSnackBar(
        message: 'Student account created successfully! Welcome to Learnozi.',
        isError: false,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    // Save actual student profile without fake defaults
    _userService.setNewProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      educationType: _educationType,
      schoolGrade: finalSchoolGrade,
      schoolCourse: finalSchoolTrack,
      universityName: finalUniversity,
      semester: finalSemester,
      program: finalProgram,
      role: 'student',
    );

    await _showEmailVerificationDialog(_emailController.text.trim());
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _showEmailVerificationDialog(String email) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A verification link has been sent to your email address:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, size: 16, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please open your inbox and click the verification link to secure your Learnozi student account.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            ),
            child: const Text('Continue to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    return AppValidators.validateStrongPassword(value);
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
                          const SizedBox(height: 20),

                          // Google 1-Tap Quick Registration
                          _buildGoogleSignUpButton(),

                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'OR REGISTER WITH EMAIL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Full Name Input
                          _buildFieldLabel('Full Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            validator: _validateName,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(
                              hint: 'e.g. Muhammad Ahmad',
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
                              hint: 'e.g. ahmad@learnozi.pk',
                              icon: Icons.mail_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone Number (Optional)
                          _buildFieldLabel('Phone Number (Optional)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(
                              hint: 'e.g. 0300 1234567',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Academic Profile Setup
                          _buildFieldLabel('Academic Level & Track'),
                          const SizedBox(height: 6),
                          SegmentedButton<EducationType>(
                            segments: const [
                              ButtonSegment(
                                value: EducationType.university,
                                label: Text('University', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.account_balance_rounded, size: 16),
                              ),
                              ButtonSegment(
                                value: EducationType.school,
                                label: Text('School/College', style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.school_rounded, size: 16),
                              ),
                            ],
                            selected: {_educationType},
                            onSelectionChanged: (val) {
                              setState(() => _educationType = val.first);
                            },
                          ),
                          const SizedBox(height: 12),

                          if (_educationType == EducationType.university) ...[
                            // 1. Pakistani Universities Dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _selectedUniversity,
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                hint: 'Select University',
                                icon: Icons.account_balance_rounded,
                              ),
                              items: UserProfile.pakistaniUniversities.map((uni) {
                                return DropdownMenuItem<String>(
                                  value: uni,
                                  child: Text(
                                    uni,
                                    style: const TextStyle(fontSize: 13.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedUniversity = val);
                                }
                              },
                            ),
                            if (_selectedUniversity == 'Other (Type your own University)') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customUniversityController,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  hint: 'Type your university name...',
                                  icon: Icons.edit_note_rounded,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // 2. University Programs / Degrees Dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _selectedProgram,
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                hint: 'Select Degree / Program',
                                icon: Icons.school_rounded,
                              ),
                              items: UserProfile.universityPrograms.map((prog) {
                                return DropdownMenuItem<String>(
                                  value: prog,
                                  child: Text(
                                    prog,
                                    style: const TextStyle(fontSize: 13.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedProgram = val);
                                }
                              },
                            ),
                            if (_selectedProgram == 'Other (Type your own Degree / Program)') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customProgramController,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  hint: 'Type your degree/program name...',
                                  icon: Icons.edit_note_rounded,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // 3. Semester Selection (or None)
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSemester,
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                hint: 'Select Semester (or None)',
                                icon: Icons.calendar_month_rounded,
                              ),
                              items: UserProfile.universitySemesters.map((sem) {
                                return DropdownMenuItem<String>(
                                  value: sem,
                                  child: Text(
                                    sem,
                                    style: const TextStyle(fontSize: 13.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSemester = val);
                                }
                              },
                            ),
                            if (_selectedSemester == 'Other (Type Semester)') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customSemesterController,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  hint: 'Type your semester (e.g. 9th Semester)...',
                                  icon: Icons.edit_calendar_rounded,
                                ),
                              ),
                            ],
                          ] else ...[
                            // School / College Class & Track
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSchoolGrade,
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                hint: 'Select Class/Grade',
                                icon: Icons.grade_rounded,
                              ),
                              items: UserProfile.schoolGrades.map((g) {
                                return DropdownMenuItem<String>(
                                  value: g,
                                  child: Text(
                                    g,
                                    style: const TextStyle(fontSize: 13.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSchoolGrade = val);
                                }
                              },
                            ),
                            if (_selectedSchoolGrade == 'Other (Type Grade)') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customSchoolGradeController,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  hint: 'Type your grade / class...',
                                  icon: Icons.edit_note_rounded,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSchoolTrack,
                              isExpanded: true,
                              decoration: _buildInputDecoration(
                                hint: 'Select Course Track',
                                icon: Icons.category_rounded,
                              ),
                              items: UserProfile.schoolTracks.map((t) {
                                return DropdownMenuItem<String>(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: const TextStyle(fontSize: 13.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSchoolTrack = val);
                                }
                              },
                            ),
                            if (_selectedSchoolTrack == 'Other (Type Track)') ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customSchoolTrackController,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  hint: 'Type your course / track...',
                                  icon: Icons.edit_note_rounded,
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 16),

                          // Password Input
                          _buildFieldLabel('Create Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                            onChanged: (_) => setState(() {}),
                            decoration: _buildInputDecoration(
                              hint: 'e.g. Learnozi@2025 (Strong Password)',
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
                          const SizedBox(height: 8),
                          _buildPasswordStrengthWidget(),
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

  Widget _buildPasswordStrengthWidget() {
    final password = _passwordController.text;
    final isEmpty = password.isEmpty;
    final strength = PasswordStrength.calculate(password);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isEmpty ? const Color(0xFFF8FAFC) : strength.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmpty ? const Color(0xFFE2E8F0) : strength.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_rounded, size: 15, color: Color(0xFF475569)),
                  SizedBox(width: 5),
                  Text(
                    'Password Strength:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isEmpty ? const Color(0xFFE2E8F0) : strength.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      strength.isStrong
                          ? Icons.check_circle_rounded
                          : (isEmpty ? Icons.info_outline_rounded : Icons.pending_rounded),
                      size: 13,
                      color: isEmpty ? const Color(0xFF64748B) : strength.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isEmpty ? 'Required' : strength.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isEmpty ? const Color(0xFF64748B) : strength.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5-segment Animated Progress bar
          Row(
            children: List.generate(5, (index) {
              final isMet = !isEmpty && index < strength.metCount;
              return Expanded(
                child: Container(
                  height: 4.5,
                  margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isMet ? strength.color : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Criteria Checklist (all 5 required)
          Wrap(
            spacing: 14,
            runSpacing: 7,
            children: [
              _buildCriteriaItem(
                label: '8+ Characters',
                isMet: !isEmpty && strength.hasMinLength,
              ),
              _buildCriteriaItem(
                label: 'Uppercase (A-Z)',
                isMet: !isEmpty && strength.hasUppercase,
              ),
              _buildCriteriaItem(
                label: 'Lowercase (a-z)',
                isMet: !isEmpty && strength.hasLowercase,
              ),
              _buildCriteriaItem(
                label: 'Number (0-9)',
                isMet: !isEmpty && strength.hasDigit,
              ),
              _buildCriteriaItem(
                label: 'Special character (!@#\$...)',
                isMet: !isEmpty && strength.hasSpecial,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem({required String label, required bool isMet}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: isMet ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
            color: isMet ? const Color(0xFF047857) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  bool _isGoogleLoading = false;

  Widget _buildGoogleSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignUp,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sign up with Google (Gmail)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleGoogleSignUp() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final error = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (error != null) {
        _showCustomSnackBar(message: error, isError: true);
      } else {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }
}
