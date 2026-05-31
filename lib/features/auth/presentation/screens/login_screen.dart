import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/database/database_service.dart';
import '../../../../shared/widgets/premium_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final String _correctPin = "1234"; // Default sample PIN for demonstration
  String _enteredPin = "";
  bool _isAuthenticating = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric auth on start if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBiometrics();
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    final db = DatabaseService.instance;
    final isBiometricsEnabled = db.getSetting('biometrics_enabled', defaultValue: false) as bool;
    
    if (!isBiometricsEnabled) return;

    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return;

      setState(() {
        _isAuthenticating = true;
        _errorMessage = "";
      });

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock your LifeFlow dashboard',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        await db.saveSetting('session_authenticated', true);
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = "Biometric authentication failed. Use PIN.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Biometrics unavailable. Enter passcode.";
      });
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _onPinKeyTapped(String value) async {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += value;
      _errorMessage = "";
    });

    if (_enteredPin.length == 4) {
      if (_enteredPin == _correctPin) {
        final db = DatabaseService.instance;
        await db.saveSetting('session_authenticated', true);
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        setState(() {
          _enteredPin = "";
          _errorMessage = "Invalid Passcode. Please try again.";
        });
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Graphic glows
          Positioned(
            top: -120,
            left: -120,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.06),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Glowing visual fingerprint indicator or App Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.08),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.12),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_person_outlined,
                      size: 64,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Welcome Back",
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter Passcode to Unlock LifeFlow",
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  // Passcode Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final bool isFilled = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: AppTransitions.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppColors.primaryLight : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? AppColors.primaryLight : AppColors.textMuted.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: isFilled
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryLight.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                  const Spacer(),
                  // Premium glassmorphic custom numeric keypad
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeypadButton("1"),
                          _buildKeypadButton("2"),
                          _buildKeypadButton("3"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeypadButton("4"),
                          _buildKeypadButton("5"),
                          _buildKeypadButton("6"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeypadButton("7"),
                          _buildKeypadButton("8"),
                          _buildKeypadButton("9"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Left action: Biometrics quick trigger
                          _buildIconButton(
                            Icons.fingerprint,
                            _authenticateWithBiometrics,
                            color: AppColors.primaryLight.withOpacity(0.8),
                          ),
                          _buildKeypadButton("0"),
                          // Right action: Backspace
                          _buildIconButton(
                            Icons.backspace_outlined,
                            _onBackspace,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Demo hint at the very bottom
                  Text(
                    "Hint: Sample PIN is 1234",
                    style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onPinKeyTapped(digit),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              digit,
              style: AppTextStyles.titleMedium.copyWith(fontSize: 26),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
