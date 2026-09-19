import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/repositories/garage_repository.dart';

class SetNewPinScreen extends StatefulWidget {
  const SetNewPinScreen({super.key});

  @override
  State<SetNewPinScreen> createState() => _SetNewPinScreenState();
}

class _SetNewPinScreenState extends State<SetNewPinScreen> {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;
  bool _isSaving = false;

  void _onKeypadTap(String val) {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_firstPin.length < 6) {
          _firstPin += val;
        }
      } else {
        if (_confirmPin.length < 6) {
          _confirmPin += val;
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  void _onClear() {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        _firstPin = '';
      } else {
        _confirmPin = '';
      }
    });
  }

  Future<void> _handleNextOrSave(GarageRepository repo, AppLocaleManager locale) async {
    if (!_isConfirming) {
      if (_firstPin.length < 4) {
        setState(() {
          _errorMessage = locale.isBangla
              ? 'পিন কোড অন্তত ৪ ডিজিটের হতে হবে'
              : 'PIN must be at least 4 digits';
        });
        return;
      }
      setState(() {
        _isConfirming = true;
        _confirmPin = '';
        _errorMessage = null;
      });
    } else {
      if (_confirmPin != _firstPin) {
        setState(() {
          _errorMessage = locale.isBangla
              ? 'পিন কোড দুটি মিলছে না! আবার চেষ্টা করুন।'
              : 'PIN codes do not match! Please try again.';
          _confirmPin = '';
        });
        return;
      }

      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      try {
        await repo.setOwnerPin(_firstPin);
        await repo.loginOwner(_firstPin);
        repo.unlockApp();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale.isBangla
                  ? 'নতুন মালিক পিন সফলভাবে সংরক্ষিত হয়েছে!'
                  : 'New Owner PIN saved successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final currentPin = _isConfirming ? _confirmPin : _firstPin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (_isConfirming) {
              setState(() {
                _isConfirming = false;
                _confirmPin = '';
                _errorMessage = null;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          locale.isBangla ? 'নতুন পিন সেট করুন' : 'Set New PIN',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    !_isConfirming
                        ? (locale.isBangla ? 'নতুন মালিক পিন লিখুন' : 'Enter New Owner PIN')
                        : (locale.isBangla ? 'নতুন পিনটি নিশ্চিত করুন' : 'Confirm New Owner PIN'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    !_isConfirming
                        ? (locale.isBangla
                            ? 'ওয়ার্কশপ সুরক্ষার জন্য ৪ থেকে ৬ ডিজিটের পিন লিখুন'
                            : 'Enter 4 to 6 digits to secure your workshop')
                        : (locale.isBangla
                            ? 'যাচাই করার জন্য একই পিন কোড পুনরায় লিখুন'
                            : 'Re-enter the same PIN code to confirm'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < currentPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppColors.primary : AppColors.surface,
                          border: Border.all(
                            color: isFilled ? AppColors.primary : AppColors.border,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

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
                    const SizedBox(height: 14),
                  ],

                  // Numeric Keypad
                  _buildKeypad(),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : () => _handleNextOrSave(repo, locale),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              !_isConfirming
                                  ? (locale.isBangla ? 'পরবর্তী' : 'Continue')
                                  : (locale.isBangla ? 'পিন সংরক্ষণ ও আনলক করুন' : 'Save PIN & Unlock'),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
