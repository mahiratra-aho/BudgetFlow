import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'security_service.dart';

/// Dialogue de saisie du PIN (4 chiffres)
class PinDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool confirmMode; // true = saisir 2 fois pour créer le PIN

  const PinDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.confirmMode = false,
  });

  /// Ouvre le dialogue et retourne true si l'auth réussit
  static Future<bool> show(
    BuildContext context, {
    String title = 'Code PIN',
    String? subtitle,
    bool confirmMode = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinDialog(
        title: title,
        subtitle: subtitle,
        confirmMode: confirmMode,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final List<String> _digits = [];
  String? _firstPin;
  bool _isConfirming = false;
  String? _errorMessage;
  bool _isLoading = false;

  static const int _pinLength = 4;

  void _onDigitTap(String digit) {
    if (_digits.length >= _pinLength) return;
    setState(() {
      _digits.add(digit);
      _errorMessage = null;
    });
    if (_digits.length == _pinLength) {
      _onPinComplete();
    }
  }

  void _onDelete() {
    if (_digits.isEmpty) return;
    setState(() {
      _digits.removeLast();
      _errorMessage = null;
    });
  }

  Future<void> _onPinComplete() async {
    final entered = _digits.join();

    if (widget.confirmMode) {
      if (!_isConfirming) {
        setState(() {
          _firstPin = entered;
          _isConfirming = true;
          _digits.clear();
        });
        return;
      }
      // Confirmation
      if (entered == _firstPin) {
        setState(() => _isLoading = true);
        await SecurityService.instance.setPin(entered);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() {
          _digits.clear();
          _isConfirming = false;
          _firstPin = null;
          _errorMessage = 'Les PIN ne correspondent pas. Réessayez.';
        });
      }
      return;
    }

    // Mode vérification
    setState(() => _isLoading = true);
    final ok = await SecurityService.instance.verifyPin(entered);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isLoading = false;
        _digits.clear();
        _errorMessage = 'PIN incorrect. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isConfirming ? 'Confirmer le PIN' : widget.title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null || _isConfirming) ...[
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Saisissez à nouveau votre PIN'
                    : widget.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            // Indicateurs de points
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _digits.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : AppColors.surface,
                    border: Border.all(
                      color: filled ? AppColors.primary : AppColors.disabled,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            // Clavier numérique
            if (_isLoading)
              const CircularProgressIndicator()
            else
              _buildKeypad(theme),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 72, height: 56);
              if (key == 'del') {
                return _PinKey(
                  onTap: _onDelete,
                  child: const Icon(Icons.backspace_outlined, size: 20),
                );
              }
              return _PinKey(
                onTap: () => _onDigitTap(key),
                child: Text(
                  key,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PinKey({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(36),
      child: SizedBox(
        width: 72,
        height: 56,
        child: Center(child: child),
      ),
    );
  }
}
