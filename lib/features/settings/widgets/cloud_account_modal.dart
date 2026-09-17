import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/services/sync_service.dart';

class CloudAccountModal {
  static void show(
    BuildContext context, {
    bool isRestoreFlow = false,
    VoidCallback? onLoginSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CloudAccountSheet(
        isRestoreFlow: isRestoreFlow,
        onLoginSuccess: onLoginSuccess,
      ),
    );
  }
}

class _CloudAccountSheet extends StatefulWidget {
  final bool isRestoreFlow;
  final VoidCallback? onLoginSuccess;

  const _CloudAccountSheet({
    this.isRestoreFlow = false,
    this.onLoginSuccess,
  });

  @override
  State<_CloudAccountSheet> createState() => _CloudAccountSheetState();
}

class _CloudAccountSheetState extends State<_CloudAccountSheet> {
  bool _isSignUpMode = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(SyncService syncService, AppLocaleManager locale) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = locale.isBangla
            ? 'সঠিক ইমেল ঠিকানা লিখুন'
            : 'Please enter a valid email address';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = locale.isBangla
            ? 'পাসওয়ার্ড অন্তত ৬ অক্ষরের হতে হবে'
            : 'Password must be at least 6 characters';
      });
      return;
    }

    if (_isSignUpMode) {
      final confirm = _confirmPasswordController.text.trim();
      if (password != confirm) {
        setState(() {
          _errorMessage = locale.isBangla
              ? 'পাসওয়ার্ড দুটি মিলছে না'
              : 'Passwords do not match';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      if (_isSignUpMode) {
        final res = await syncService.signUp(email, password);
        if (!mounted) return;
        if (res?.session == null) {
          setState(() {
            _isLoading = false;
            _infoMessage = locale.isBangla
                ? 'অ্যাকাউন্ট তৈরি সফল! অনুগ্রহ করে আপনার ইমেল চেক করে ভেরিফাই করুন, তারপর লগইন করুন।'
                : 'Account created! Please check your email inbox to verify your account, then log in.';
            _isSignUpMode = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _infoMessage = locale.isBangla
                ? 'অ্যাকাউন্ট তৈরি ও সফলভাবে কানেক্ট হয়েছে!'
                : 'Account created and connected to cloud!';
          });
          if (widget.isRestoreFlow) {
            await syncService.pullRemoteData();
            widget.onLoginSuccess?.call();
            if (mounted) Navigator.of(context).pop();
            return;
          }
        }
      } else {
        await syncService.signIn(email, password);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        if (widget.isRestoreFlow) {
          await syncService.pullRemoteData();
          widget.onLoginSuccess?.call();
          if (mounted) Navigator.of(context).pop();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.isBangla
                ? 'ক্লাউডে সফলভাবে লগইন হয়েছে! ক্লাউড ডেটা সিঙ্ক করা হচ্ছে...'
                : 'Logged into Supabase Cloud! Syncing garage data...'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e.toString(), locale);
      });
    }
  }

  String _cleanErrorMessage(String raw, AppLocaleManager locale) {
    if (raw.contains('invalid_credentials')) {
      return locale.isBangla
          ? 'ভুল ইমেল বা পাসওয়ার্ড! আবার চেষ্টা করুন।'
          : 'Invalid email or password. Please try again.';
    }
    if (raw.contains('email_not_confirmed')) {
      return locale.isBangla
          ? 'ইমেল এখনো ভেরিফাই করা হয়নি। আপনার ইনবক্স চেক করুন।'
          : 'Email is not confirmed yet. Please verify your email inbox before logging in.';
    }
    if (raw.contains('user_already_exists')) {
      return locale.isBangla
          ? 'এই ইমেলে ইতিমধ্যে একটি অ্যাকাউন্ট আছে। অনুগ্রহ করে লগইন করুন।'
          : 'An account with this email already exists. Please log in.';
    }
    return raw.replaceFirst('Exception: ', '').replaceFirst('AuthException: ', '');
  }

  Future<void> _handleManualSync(SyncService syncService, AppLocaleManager locale) async {
    setState(() => _errorMessage = null);
    try {
      await syncService.syncAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale.isBangla
              ? 'ক্লাউড সিঙ্ক সম্পন্ন! সমস্ত রেকর্ড আপডেট করা হয়েছে।'
              : 'Cloud sync complete! All records are up to date.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    }
  }

  void _confirmSignOut(SyncService syncService, AppLocaleManager locale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text(
              locale.isBangla ? 'ক্লাউড লগআউট' : 'Disconnect Cloud',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          locale.isBangla
              ? 'আপনি কি নিশ্চিত যে আপনি ক্লাউড অ্যাকাউন্ট থেকে বের হতে চান? আপনার অফলাইন ডেটা ডিভাইসে সংরক্ষিত থাকবে।'
              : 'Are you sure you want to disconnect? Your offline Hive data remains safe on this device.',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.isBangla ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await syncService.signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(locale.isBangla
                      ? 'ক্লাউড অ্যাকাউন্ট ডিসকানেক্ট করা হয়েছে।'
                      : 'Cloud account disconnected.'),
                  backgroundColor: AppColors.textSecondary,
                ),
              );
            },
            child: Text(locale.isBangla ? 'লগআউট' : 'Disconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncService = Provider.of<SyncService>(context);
    final locale = Provider.of<AppLocaleManager>(context);
    final isAuthenticated = syncService.isCloudAuthenticated;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Header
              _buildHeader(locale, isAuthenticated),
              const SizedBox(height: 16),

              // 3. Status Alerts
              if (_errorMessage != null) ...[
                _buildMessageBanner(_errorMessage!, isError: true),
                const SizedBox(height: 14),
              ],
              if (_infoMessage != null) ...[
                _buildMessageBanner(_infoMessage!, isError: false),
                const SizedBox(height: 14),
              ],

              // 4. Body (Authenticated vs Unauthenticated)
              if (isAuthenticated)
                _buildAuthenticatedView(syncService, locale)
              else
                _buildUnauthenticatedView(syncService, locale),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocaleManager locale, bool isAuthenticated) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isAuthenticated ? AppColors.successLight : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isAuthenticated ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
            color: isAuthenticated ? AppColors.success : AppColors.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.isBangla
                    ? 'ক্লাউড অ্যাকাউন্ট ও মাল্টি-ডিভাইস সিঙ্ক'
                    : 'Cloud Account & Multi-Device Sync',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                locale.isBangla
                    ? 'Supabase ব্যাকএন্ড • রিয়েল-টাইম অফলাইন ব্যাকআপ'
                    : 'Supabase Cloud • Real-Time Offline Sync',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildMessageBanner(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppColors.dangerLight : AppColors.successLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isError ? AppColors.danger : AppColors.success).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? AppColors.danger : AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isError ? AppColors.danger : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedView(SyncService syncService, AppLocaleManager locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explanatory Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.devices_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locale.isBangla
                      ? 'লগইন করে আপনার সমস্ত ডেটা স্বয়ংক্রিয়ভাবে ক্লাউডে ব্যাকআপ রাখুন এবং একাধিক ডিভাইসে রিয়েল-টাইমে ব্যবহার করুন।'
                      : 'Sign in to back up your workshop data and sync across multiple devices (phones, tablets, PCs) in real time.',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Sign In vs Sign Up Segmented Control
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _isSignUpMode = false;
                    _errorMessage = null;
                    _infoMessage = null;
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: !_isSignUpMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      locale.isBangla ? 'লগইন (Sign In)' : 'Log In',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: !_isSignUpMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _isSignUpMode = true;
                    _errorMessage = null;
                    _infoMessage = null;
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _isSignUpMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      locale.isBangla ? 'নতুন অ্যাকাউন্ট (Sign Up)' : 'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _isSignUpMode ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: locale.isBangla ? 'ইমেল ঠিকানা' : 'Email Address',
            hintText: 'e.g. owner@workshop.com',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 14),

        // Password field
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: locale.isBangla ? 'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)' : 'Password (min 6 characters)',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Confirm password field (if sign up)
        if (_isSignUpMode) ...[
          TextField(
            controller: _confirmPasswordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: locale.isBangla ? 'পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_reset),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : () => _handleAuth(syncService, locale),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    _isSignUpMode
                        ? (locale.isBangla ? 'অ্যাকাউন্ট তৈরি করুন' : 'Sign Up for Cloud')
                        : (locale.isBangla ? 'লগইন করুন ও সিঙ্ক করুন' : 'Log In & Sync Device'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedView(SyncService syncService, AppLocaleManager locale) {
    final user = syncService.currentCloudUser;
    final unsynced = syncService.unsyncedCount;
    final lastSync = syncService.lastSyncTime != null
        ? DateFormat('dd MMM yyyy • hh:mm a').format(syncService.lastSyncTime!)
        : (locale.isBangla ? 'এখনো সিঙ্ক হয়নি' : 'Not synced yet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cloud User Profile Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_done_rounded, color: AppColors.success, size: 26),
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
                            user?.email ?? 'Cloud Account',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            locale.isBangla ? 'কানেক্টেড' : 'CONNECTED',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UID: ${user?.id.substring(0, 8)}... (Multi-Device Active)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sync Status Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pending_actions_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        locale.isBangla ? 'পেন্ডিং আপলোড:' : 'Pending Uploads:',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: unsynced > 0 ? AppColors.warningLight : AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unsynced > 0
                          ? '$unsynced ${locale.isBangla ? 'টি পরিবর্তন' : 'records'}'
                          : (locale.isBangla ? 'সব সিঙ্কড' : 'All Synced'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: unsynced > 0 ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        locale.isBangla ? 'সর্বশেষ সিঙ্ক:' : 'Last Synced:',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  Text(
                    lastSync,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Sync Action Buttons
        if (widget.isRestoreFlow) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                locale.isBangla
                    ? 'ক্লাউড ডেটা রিস্টোর ও ড্যাশবোর্ডে প্রবেশ করুন'
                    : 'Restore Data & Open Dashboard',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              onPressed: () async {
                await syncService.pullRemoteData();
                widget.onLoginSuccess?.call();
                if (!mounted) return;
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: syncService.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync_rounded, size: 20),
            label: Text(
              syncService.isSyncing
                  ? (locale.isBangla ? 'সিঙ্ক করা হচ্ছে...' : 'Syncing Now...')
                  : (locale.isBangla ? 'এখনই সিঙ্ক করুন (Sync Now)' : 'Sync Now'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            onPressed: syncService.isSyncing ? null : () => _handleManualSync(syncService, locale),
          ),
        ),
        const SizedBox(height: 10),

        // Restore / Pull Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.cloud_download_rounded, size: 20, color: AppColors.primary),
            label: Text(
              locale.isBangla ? 'ক্লাউড থেকে ডেটা রিস্টোর করুন' : 'Pull & Restore Cloud Data',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            onPressed: syncService.isSyncing
                ? null
                : () async {
                    await syncService.pullRemoteData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(locale.isBangla
                            ? 'ক্লাউড থেকে সফলভাবে ডেটা রিস্টোর করা হয়েছে!'
                            : 'Successfully pulled latest data from cloud!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
          ),
        ),
        const SizedBox(height: 16),

        // Log out button
        Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.cloud_off_rounded, size: 18),
            label: Text(
              locale.isBangla ? 'ক্লাউড অ্যাকাউন্ট ডিসকানেক্ট করুন' : 'Disconnect Cloud Account',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            onPressed: () => _confirmSignOut(syncService, locale),
          ),
        ),
      ],
    );
  }
}
