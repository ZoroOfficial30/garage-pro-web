import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/repositories/garage_repository.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _showCreateWorkshopModal(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
    SyncService syncService,
  ) {
    final nameCtrl = TextEditingController(text: repo.workshopProfile['name'] ?? 'Apex Auto Workshop');
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '1234');
    final confirmPinCtrl = TextEditingController(text: '1234');

    bool passwordVisible = false;
    bool confirmPasswordVisible = false;
    bool isLoading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_business_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            locale.isBangla ? 'নতুন ওয়ার্কশপ নিবন্ধন' : 'Create New Workshop',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      locale.isBangla
                          ? 'ওয়ার্কশপের তথ্য ও ক্লাউড অ্যাকাউন্ট সেটআপ করুন যাতে অন্য যেকোনো ডিভাইসে রিস্টোর করা যায়:'
                          : 'Configure workshop profile & cloud account for seamless recovery across any device:',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    if (error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Workshop Name
                    Text(
                      locale.isBangla ? 'ওয়ার্কশপের নাম' : 'Workshop Name',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: locale.isBangla ? 'যেমন: এপেক্স অটো ওয়ার্কশপ' : 'e.g. Apex Auto Workshop',
                        prefixIcon: const Icon(Icons.store_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Owner Email
                    Text(
                      locale.isBangla ? 'মালিকের ইমেল (ক্লাউড রিকভারি)' : 'Owner Email (Cloud Recovery)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'owner@workshop.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cloud Password
                    Text(
                      locale.isBangla ? 'ক্লাউড পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)' : 'Cloud Account Password (min 6 chars)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setModalState(() => passwordVisible = !passwordVisible),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password
                    Text(
                      locale.isBangla ? 'পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm Password',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: !confirmPasswordVisible,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(confirmPasswordVisible ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setModalState(() => confirmPasswordVisible = !confirmPasswordVisible),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Owner PIN
                    Text(
                      locale.isBangla ? 'ডিভাইস পিন (৪-৬ সংখ্যা)' : 'Owner PIN (4-6 digits)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: '1234',
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Confirm PIN
                    Text(
                      locale.isBangla ? 'পিন নিশ্চিত করুন' : 'Confirm PIN',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmPinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: '1234',
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                final password = passwordCtrl.text.trim();
                                final confirmPassword = confirmPasswordCtrl.text.trim();
                                final pin = pinCtrl.text.trim();
                                final confirmPin = confirmPinCtrl.text.trim();

                                if (name.isEmpty) {
                                  setModalState(() {
                                    error = locale.isBangla
                                        ? 'ওয়ার্কশপের নাম দিন'
                                        : 'Please enter workshop name';
                                  });
                                  return;
                                }

                                if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
                                  setModalState(() {
                                    error = locale.isBangla
                                        ? 'সঠিক ইমেল ঠিকানা লিখুন'
                                        : 'Please enter a valid email address';
                                  });
                                  return;
                                }

                                if (password.isNotEmpty) {
                                  if (password.length < 6) {
                                    setModalState(() {
                                      error = locale.isBangla
                                          ? 'পাসওয়ার্ড অন্তত ৬ অক্ষরের হতে হবে'
                                          : 'Password must be at least 6 characters';
                                    });
                                    return;
                                  }
                                  if (password != confirmPassword) {
                                    setModalState(() {
                                      error = locale.isBangla
                                          ? 'পাসওয়ার্ড দুটি মিলছে না'
                                          : 'Passwords do not match';
                                    });
                                    return;
                                  }
                                }

                                if (pin.length < 4) {
                                  setModalState(() {
                                    error = locale.isBangla
                                        ? 'পিন অন্তত ৪ সংখ্যার হতে হবে'
                                        : 'PIN must be at least 4 digits';
                                  });
                                  return;
                                }

                                if (pin != confirmPin) {
                                  setModalState(() {
                                    error = locale.isBangla
                                        ? 'পিন দুটি মিলছে না'
                                        : 'PINs do not match';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isLoading = true;
                                  error = null;
                                });

                                // Bind Supabase Auth user if email & password provided
                                if (email.isNotEmpty && password.isNotEmpty) {
                                  try {
                                    if (syncService.client != null) {
                                      await syncService.signUp(
                                        email,
                                        password,
                                        data: {
                                          'workshop_name': name,
                                          'pin_code': pin,
                                        },
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Supabase signup notice: $e');
                                  }
                                }

                                if (modalCtx.mounted && Navigator.canPop(modalCtx)) {
                                  Navigator.pop(modalCtx);
                                }

                                await repo.completeFreshSetup(
                                  name: name,
                                  pin: pin,
                                  email: email.isNotEmpty ? email : null,
                                );
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textPrimary),
                              )
                            : Text(
                                locale.isBangla
                                    ? 'ওয়ার্কশপ তৈরি ও ড্যাশবোর্ডে প্রবেশ করুন'
                                    : 'Create Garage & Enter Dashboard',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSignInRestoreModal(
    BuildContext context,
    GarageRepository repo,
    AppLocaleManager locale,
    SyncService syncService,
  ) {
    int currentStep = 1; // 1: Credentials, 2: Set Device PIN
    final idCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final devicePinCtrl = TextEditingController(text: '1234');
    final confirmDevicePinCtrl = TextEditingController(text: '1234');

    bool passVisible = false;
    bool isLoading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_download_rounded, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentStep == 1
                                ? (locale.isBangla ? 'পূর্বের অ্যাকাউন্টে সাইন ইন' : 'Sign In to Existing Account')
                                : (locale.isBangla ? 'ডিভাইস অ্যাক্সেস পিন নির্ধারণ' : 'Set Local Device PIN'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentStep == 1
                          ? (locale.isBangla
                              ? 'আপনার ক্লাউড অ্যাকাউন্টের ক্রেডেনশিয়াল দিয়ে সাইন ইন করুন:'
                              : 'Enter your Supabase credentials to restore all garage data:')
                          : (locale.isBangla
                              ? 'ক্লাউড ডেটা সফলভাবে রিস্টোর হয়েছে! এই ডিভাইসে দ্রুত প্রবেশের জন্য ৪-৬ সংখ্যার একটি পিন দিন:'
                              : 'Cloud data restored successfully! Confirm a 4-6 digit local PIN for this device:'),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    if (error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (currentStep == 1) ...[
                      // Email or Phone
                      Text(
                        locale.isBangla ? 'ইমেল বা ফোন নম্বর' : 'Email or Phone',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: idCtrl,
                        decoration: InputDecoration(
                          hintText: locale.isBangla ? 'যেমন: owner@workshop.com বা +880...' : 'e.g. owner@workshop.com or +880...',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      Text(
                        locale.isBangla ? 'পাসওয়ার্ড' : 'Password',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: passCtrl,
                        obscureText: !passVisible,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(passVisible ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setModalState(() => passVisible = !passVisible),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Step 1 Submit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final id = idCtrl.text.trim();
                                  final pass = passCtrl.text.trim();

                                  if (id.isEmpty) {
                                    setModalState(() {
                                      error = locale.isBangla
                                          ? 'ইমেল বা ফোন নম্বর লিখুন'
                                          : 'Please enter your email or phone';
                                    });
                                    return;
                                  }

                                  if (pass.isEmpty) {
                                    setModalState(() {
                                      error = locale.isBangla
                                          ? 'পাসওয়ার্ড লিখুন'
                                          : 'Please enter your password';
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    isLoading = true;
                                    error = null;
                                  });

                                  try {
                                    if (syncService.client != null) {
                                      await syncService.signIn(id, pass);
                                    } else {
                                      await syncService.pullRemoteData();
                                    }
                                    setModalState(() {
                                      isLoading = false;
                                      currentStep = 2;
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isLoading = false;
                                      final raw = e.toString();
                                      if (raw.contains('invalid_credentials')) {
                                        error = locale.isBangla
                                            ? 'ভুল ইমেল বা পাসওয়ার্ড! আবার চেষ্টা করুন।'
                                            : 'Invalid email/phone or password. Please try again.';
                                      } else {
                                        error = raw.replaceFirst('Exception: ', '').replaceFirst('AuthException: ', '');
                                      }
                                    });
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  locale.isBangla ? 'সাইন ইন ও ডেটা রিস্টোর করুন' : 'Sign In & Restore Data',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                        ),
                      ),
                    ] else ...[
                      // Step 2: Set / Confirm Device PIN
                      Text(
                        locale.isBangla ? 'এই ডিভাইসের পিন (৪-৬ সংখ্যা)' : 'Local Device PIN (4-6 digits)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: devicePinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: '1234',
                          counterText: '',
                          prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        locale.isBangla ? 'পিন নিশ্চিত করুন' : 'Confirm Device PIN',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: confirmDevicePinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: '1234',
                          counterText: '',
                          prefixIcon: const Icon(Icons.pin_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final pin = devicePinCtrl.text.trim();
                                  final confirm = confirmDevicePinCtrl.text.trim();

                                  if (pin.length < 4) {
                                    setModalState(() {
                                      error = locale.isBangla
                                          ? 'পিন অন্তত ৪ সংখ্যার হতে হবে'
                                          : 'PIN must be at least 4 digits';
                                    });
                                    return;
                                  }

                                  if (pin != confirm) {
                                    setModalState(() {
                                      error = locale.isBangla
                                          ? 'পিন দুটি মিলছে না'
                                          : 'PINs do not match';
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    isLoading = true;
                                  });

                                  if (Navigator.canPop(modalCtx)) {
                                    Navigator.pop(modalCtx);
                                  }

                                  await repo.completeCloudRestoreSetup(devicePin: pin);
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textPrimary),
                                )
                              : Text(
                                  locale.isBangla
                                      ? 'পিন সংরক্ষণ ও ড্যাশবোর্ডে প্রবেশ করুন'
                                      : 'Confirm PIN & Open Dashboard',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final locale = Provider.of<AppLocaleManager>(context);
    final syncService = Provider.of<SyncService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            icon: const Icon(Icons.translate_rounded, size: 18),
            label: Text(
              locale.isBangla ? 'English' : 'বাংলা',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            onPressed: () => locale.toggleLanguage(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Icon & Badge
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC72C), Color(0xFFFF9E00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.garage_rounded,
                      size: 44,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Title
                  Text(
                    locale.isBangla
                        ? 'গ্যারেজ অ্যাকাউন্টিং প্রো'
                        : 'Garage Accounting Pro',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    locale.isBangla
                        ? 'আপনার ওয়ার্কশপ পরিচালনায় শুরু করতে নিচের যেকোনো একটি বিকল্প বেছে নিন'
                        : 'Select an option to get started with your workshop management',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Option A: Create New Workshop (Start Fresh Garage)
                  _buildOptionCard(
                    context: context,
                    icon: Icons.add_business_rounded,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primaryLight,
                    title: locale.isBangla ? 'নতুন ওয়ার্কশপ তৈরি করুন' : 'Create New Workshop',
                    subtitle: locale.isBangla
                        ? 'ক্লাউড অ্যাকাউন্টসহ নতুন ওয়ার্কশপ প্রোফাইল এবং মালিকের পিন তৈরি করুন।'
                        : 'Set up a brand new workshop profile bound to a cloud account and Owner PIN code.',
                    badge: locale.isBangla ? 'নতুন ওয়ার্কশপ' : 'NEW WORKSHOP',
                    badgeColor: AppColors.primaryLight,
                    badgeTextColor: const Color(0xFF8A6500),
                    buttonText: locale.isBangla ? 'নতুন ওয়ার্কশপ তৈরি করুন' : 'Create New Workshop',
                    isPrimaryButton: true,
                    onTap: () => _showCreateWorkshopModal(context, repo, locale, syncService),
                  ),
                  const SizedBox(height: 18),

                  // Option B: Sign In to Existing Account (Restore from Cloud)
                  _buildOptionCard(
                    context: context,
                    icon: Icons.cloud_download_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBgColor: const Color(0xFFDBEAFE),
                    title: locale.isBangla ? 'পূর্বের অ্যাকাউন্টে সাইন ইন করুন' : 'Sign In to Existing Account',
                    subtitle: locale.isBangla
                        ? 'অন্য ডিভাইস বা পূর্বের ক্লাউড ব্যাকআপ থেকে সমস্ত ডেটা এই ডিভাইসে সিঙ্ক করুন।'
                        : 'Log into your Supabase account to sync existing customers, jobs, and transactions to this device.',
                    badge: locale.isBangla ? 'মাল্টি-ডিভাইস' : 'MULTI-DEVICE',
                    badgeColor: const Color(0xFFDBEAFE),
                    badgeTextColor: const Color(0xFF1D4ED8),
                    buttonText: locale.isBangla ? 'অ্যাকাউন্টে সাইন ইন করুন' : 'Sign In to Existing Account',
                    isPrimaryButton: false,
                    onTap: () => _showSignInRestoreModal(context, repo, locale, syncService),
                  ),
                  const SizedBox(height: 28),

                  // Offline First Guarantee Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.offline_bolt_rounded, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          locale.isBangla
                              ? '১০০% অফলাইন কার্যকরী • রিয়েল-টাইম ক্লাউড সিঙ্ক'
                              : '100% Offline Capable • Real-Time Cloud Sync',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
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
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String buttonText,
    required bool isPrimaryButton,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPrimaryButton ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          width: isPrimaryButton ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: badgeTextColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isPrimaryButton
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: onTap,
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onTap,
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
}
