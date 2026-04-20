import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/pin_service.dart';
import '../../theme/app_theme.dart';

enum PinScreenMode { verify, setup, change }

class PinLockScreen extends StatefulWidget {
  final PinScreenMode mode;
  const PinLockScreen({super.key, this.mode = PinScreenMode.verify});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _firstPin; // For setup: stores first entry before confirm
  String _title = 'Enter PIN';
  String? _error;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    if (widget.mode == PinScreenMode.setup) {
      _title = 'Create a 4-Digit PIN';
    } else if (widget.mode == PinScreenMode.change) {
      _title = 'Enter New PIN';
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberTap(String num) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += num;
      _error = null;
    });

    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _handleComplete);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _handleComplete() async {
    if (widget.mode == PinScreenMode.verify) {
      final valid = await PinService.verifyPin(_pin);
      if (valid) {
        if (mounted) Navigator.pop(context, true);
      } else {
        _triggerError('Incorrect PIN. Try again.');
      }
    } else {
      // Setup or Change mode
      if (_firstPin == null) {
        _firstPin = _pin;
        setState(() {
          _pin = '';
          _title = 'Confirm PIN';
        });
      } else {
        if (_pin == _firstPin) {
          await PinService.setPin(_pin);
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          _firstPin = null;
          _triggerError('PINs don\'t match. Start over.');
          setState(() {
            _title = widget.mode == PinScreenMode.setup ? 'Create a 4-Digit PIN' : 'Enter New PIN';
          });
        }
      }
    }
  }

  void _triggerError(String message) {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    setState(() {
      _pin = '';
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVerify = widget.mode == PinScreenMode.verify;

    return Scaffold(
      backgroundColor: AppTheme.cardBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Lock icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
            ),

            const SizedBox(height: 24),

            Text(
              _title,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: AppTheme.danger.withOpacity(0.9), fontSize: 13),
              )
            else
              Text(
                isVerify ? 'Enter your 4-digit PIN to unlock' : 'Choose a PIN to secure your app',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),

            const SizedBox(height: 32),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final dx = _shakeAnimation.value * 
                    (_shakeController.status == AnimationStatus.reverse ? -1 : 1);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: filled ? 20 : 16,
                    height: filled ? 20 : 16,
                    decoration: BoxDecoration(
                      color: filled ? AppTheme.primary : Colors.transparent,
                      border: Border.all(
                        color: filled ? AppTheme.primary : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),

            const Spacer(flex: 1),

            // Number pad
            _buildNumberPad(),

            const SizedBox(height: 24),

            if (isVerify)
              TextButton(
                onPressed: () {
                  // Allow skip / exit — in verify mode this is intentionally not available
                  // But you could add biometric fallback here later
                },
                child: const Text(''),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildNumRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildNumRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildNumRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildNumRow(['', '0', 'del']),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> nums) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: nums.map((n) {
        if (n.isEmpty) return const SizedBox(width: 64, height: 64);

        if (n == 'del') {
          return GestureDetector(
            onTap: _onDelete,
            child: const SizedBox(
              width: 64, height: 64,
              child: Center(
                child: Icon(Icons.backspace_outlined, color: Colors.white70, size: 24),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _onNumberTap(n),
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                n,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
