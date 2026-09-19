import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../data/models/employee.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../settings/widgets/cloud_account_modal.dart';
import '../widgets/forgot_pin_recovery_modal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isOwnerMode = true;
  String _enteredPin = '';
  String? _selectedStaffId;
  String? _errorMessage;
  bool _isLoading = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = Provider.of<GarageRepository>(context, listen: false);
      if (repo.isAppLocked && repo.currentUser != null) {
        if (repo.currentUser!.isStaff) {
          setState(() {
            _isOwnerMode = false;
            _selectedStaffId = repo.currentUser!.staffId ?? repo.currentUser!.id;
          });
        } else {
          setState(() {
            _isOwnerMode = true;
          });
        }
      }
    });
  }

  Future<void> _checkBiometrics() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() => _canUseBiometrics = false);
      }
      return;
    }
    final available = await BiometricAuthService().isBiometricAvailable();
    if (mounted) {
      setState(() => _canUseBiometrics = available);
    }
  }

  void _onKeypadTap(String value) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += value;
        _errorMessage = null;
      });
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin(GarageRepository repo, AppLocaleManager locale) async {
    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage = locale.isBangla
            ? 'অন্তত ৪-সংখ্যার পিন প্রবেশ করান'
            : 'Please enter at least a 4-digit PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = false;
    if (repo.isAppLocked) {
      success = await repo.unlockWithPin(_enteredPin);
    } else if (_isOwnerMode) {
      success = await repo.loginOwner(_enteredPin);
    } else {
      if (_selectedStaffId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = locale.isBangla
              ? 'অনুগ্রহ করে একজন স্টাফ সদস্য নির্বাচন করুন'
              : 'Please select a staff member';
        });
        return;
      }
      success = await repo.loginStaff(_selectedStaffId!, _enteredPin);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      setState(() {
        _errorMessage = locale.isBangla
            ? 'ভুল পিন কোড! আবার চেষ্টা করুন।'
            : 'Incorrect PIN. Please try again.';
      });
    }
  }

  void _handleForgotPin(BuildContext context, GarageRepository repo, AppLocaleManager locale) {
    final isStaffMode = !_isOwnerMode || (repo.isAppLocked && repo.currentUser?.isStaff == true);
    if (isStaffMode) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  locale.isBangla ? 'স্টাফ পিন রিসেট' : 'Staff PIN Reset',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(
            locale.isBangla
                ? 'আপনার অ্যাক্সেস পিন রিসেট করতে অনুগ্রহ করে গ্যারেজ মালিকের সাথে যোগাযোগ করুন।'
                : 'Please contact the Garage Owner to reset your access PIN.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(locale.isBangla ? 'ঠিক আছে' : 'OK'),
            ),
          ],
        ),
      );
    } else {
      ForgotPinRecoveryModal.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final profile = repo.workshopProfile;
    final workshopName = profile['name']?.isNotEmpty == true
        ? profile['name']!
        : (locale.isBangla ? 'এপেক্স অটো ওয়ার্কশপ' : 'Apex Auto Workshop');

    final activeStaff = repo.employees.where((e) => e.isLoginEnabled).toList();
    if (!_isOwnerMode) {
      if (_selectedStaffId == null || activeStaff.every((e) => e.id != _selectedStaffId)) {
        _selectedStaffId = activeStaff.isNotEmpty ? activeStaff.first.id : null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Workshop Logo & Name
                  _buildWorkshopHeader(repo, workshopName, locale),
                  const SizedBox(height: 24),

                  // 2. Role Selector (Owner vs Staff)
                  _buildRoleSelector(locale),
                  const SizedBox(height: 20),

                  // 3. Staff Selector Dropdown (when in Staff mode)
                  if (!_isOwnerMode) ...[
                    _buildStaffDropdown(activeStaff, locale),
                    const SizedBox(height: 16),
                  ],

                  // 4. PIN Dots Display
                  _buildPinDisplay(locale),
                  const SizedBox(height: 12),

                  // Error Message Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 5. Numeric Keypad (Glove-Friendly Touch Targets)
                  _buildKeypad(),
                  const SizedBox(height: 6),

                  // Subtle "Forgot PIN?" text button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _handleForgotPin(context, repo, locale),
                      child: Text(
                        locale.isBangla ? 'পিন ভুলে গেছেন?' : 'Forgot PIN?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 6. Login Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOwnerMode ? AppColors.primary : AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : () => _handleLogin(repo, locale),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              repo.isAppLocked
                                  ? (locale.isBangla ? 'আনলক করুন' : 'Unlock Garage')
                                  : (_isOwnerMode
                                      ? (locale.isBangla ? 'মালিক হিসেবে প্রবেশ করুন' : 'Login as Owner')
                                      : (locale.isBangla ? 'স্টাফ হিসেবে প্রবেশ করুন' : 'Login as Staff')),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                    ),
                  ),

                  // 7. Biometrics Button (Mobile only, graceful Web fallback)
                  if (!kIsWeb && _canUseBiometrics && repo.biometricEnabled) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.fingerprint_rounded, size: 22),
                        label: Text(
                          locale.isBangla ? 'বায়োমেট্রিক দিয়ে আনলক করুন' : 'Unlock with Biometrics',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        onPressed: _isLoading ? null : () async {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          final success = await repo.unlockWithBiometrics();
                          if (!mounted) return;
                          setState(() => _isLoading = false);
                          if (!success) {
                            setState(() {
                              _errorMessage = locale.isBangla
                                  ? 'বায়োমেট্রিক যাচাইকরণ ব্যর্থ হয়েছে বা বাতিল করা হয়েছে।'
                                  : 'Biometric verification failed or was cancelled.';
                            });
                          }
                        },
                      ),
                    ),
                  ],

                  if (repo.isAppLocked) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: Text(
                        locale.isBangla ? 'লগআউট / ব্যবহারকারী পরিবর্তন' : 'Log Out / Switch User',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      onPressed: () async {
                        await repo.logout();
                        _onClear();
                      },
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Initial Hint for Owner PIN
                  if (_isOwnerMode && !repo.isAppLocked) ...[
                    Text(
                      locale.isBangla
                          ? 'ডিফল্ট মালিক পিন: 1234 (সেটিংস থেকে পরিবর্তনযোগ্য)'
                          : 'Default Owner PIN: 1234 (changeable in Settings)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.cloud_download_rounded, size: 18, color: AppColors.primary),
                      label: Text(
                        locale.isBangla ? 'ক্লাউড অ্যাকাউন্ট থেকে রিস্টোর করুন' : 'Restore from Cloud Account',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () {
                        CloudAccountModal.show(
                          context,
                          isRestoreFlow: true,
                          onLoginSuccess: () async {
                            await repo.completeCloudRestoreSetup();
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkshopHeader(GarageRepository repo, String workshopName, AppLocaleManager locale) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: (repo.workshopLogoBase64 != null && repo.workshopLogoBase64!.isNotEmpty)
              ? Image.memory(
                  base64Decode(repo.workshopLogoBase64!),
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => const Icon(
                    Icons.garage_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                )
              : const Icon(
                  Icons.garage_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
        ),
        const SizedBox(height: 12),
        Text(
          workshopName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: repo.isAppLocked ? AppColors.warningLight : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: repo.isAppLocked ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (repo.isAppLocked) ...[
                const Icon(Icons.lock_clock_rounded, size: 12, color: AppColors.warning),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  repo.isAppLocked
                      ? (locale.isBangla ? 'অটো-লক • পিন দিয়ে খুলুন' : 'Auto-Locked • Enter PIN')
                      : (locale.isBangla ? 'গ্যারেজ অ্যাকাউন্টিং প্রো • অফলাইন অ্যাক্সেস' : 'Garage Accounting Pro • Offline Access'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: repo.isAppLocked ? AppColors.warning : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector(AppLocaleManager locale) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isOwnerMode = true;
                  _enteredPin = '';
                  _errorMessage = null;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isOwnerMode ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 18,
                      color: _isOwnerMode ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      locale.isBangla ? 'মালিক (Owner)' : 'Owner',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _isOwnerMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isOwnerMode = false;
                  _enteredPin = '';
                  _errorMessage = null;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isOwnerMode ? AppColors.primaryDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      size: 18,
                      color: !_isOwnerMode ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      locale.isBangla ? 'স্টাফ (Staff)' : 'Staff',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: !_isOwnerMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffDropdown(List<Employee> employees, AppLocaleManager locale) {
    if (employees.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                locale.isBangla
                    ? 'কোন স্টাফের লগইন সক্ষম নেই। মালিক সেটিংস বা স্টাফ বিভাগ থেকে পিন সেট করতে পারেন।'
                    : 'No staff logins enabled. Owner can assign PINs & enable access in Settings or Staff.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStaffId,
          isExpanded: true,
          hint: Text(locale.isBangla ? 'স্টাফ বেছে নিন' : 'Select Staff Member'),
          items: employees.map((emp) {
            return DropdownMenuItem<String>(
              value: emp.id,
              child: Row(
                children: [
                  const Icon(Icons.person_pin_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${emp.name} • ${emp.role}',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedStaffId = val;
                _enteredPin = '';
                _errorMessage = null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPinDisplay(AppLocaleManager locale) {
    return Column(
      children: [
        Text(
          _isOwnerMode
              ? (locale.isBangla ? 'মালিক পিন প্রবেশ করান' : 'Enter Owner PIN')
              : (locale.isBangla ? 'স্টাফ পিন প্রবেশ করান' : 'Enter Staff PIN'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < _enteredPin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? (_isOwnerMode ? AppColors.primary : AppColors.primaryDark)
                    : AppColors.surface,
                border: Border.all(
                  color: isFilled ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          children: [
            _buildKeypadButton('1'),
            const SizedBox(width: 10),
            _buildKeypadButton('2'),
            const SizedBox(width: 10),
            _buildKeypadButton('3'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKeypadButton('4'),
            const SizedBox(width: 10),
            _buildKeypadButton('5'),
            const SizedBox(width: 10),
            _buildKeypadButton('6'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKeypadButton('7'),
            const SizedBox(width: 10),
            _buildKeypadButton('8'),
            const SizedBox(width: 10),
            _buildKeypadButton('9'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKeypadButton('C', isAction: true, onTap: _onClear),
            const SizedBox(width: 10),
            _buildKeypadButton('0'),
            const SizedBox(width: 10),
            _buildKeypadButton('⌫', isAction: true, onTap: _onBackspace),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(
    String label, {
    bool isAction = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: SizedBox(
        height: 52,
        child: Material(
          color: isAction ? AppColors.background : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap ?? () => _onKeypadTap(label),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isAction ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    color: isAction ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
