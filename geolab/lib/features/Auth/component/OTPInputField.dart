import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolab/utils/theme.dart';

class OTPInputField extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final String? errorText;
  final bool enabled;

  const OTPInputField({
    Key? key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<OTPInputField> createState() => OTPInputFieldState();
}

class OTPInputFieldState extends State<OTPInputField>
    with TickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );

    // Animation for error shake
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    // Focus on first field initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty && widget.enabled) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _onFieldChanged(String value, int index) {
    if (value.isNotEmpty && index < widget.length - 1) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    }

    // Check if all fields are filled
    String otp = _controllers.map((controller) => controller.text).join();
    widget.onChanged?.call(otp);

    if (otp.length == widget.length) {
      widget.onCompleted(otp);
      // Remove focus from all fields
      for (var focusNode in _focusNodes) {
        focusNode.unfocus();
      }
    }
  }

  void _onFieldKeyPressed(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // Move to previous field and clear it
          _controllers[index - 1].clear();
          _focusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  void _triggerErrorAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  void clearOTP() {
    for (var controller in _controllers) {
      controller.clear();
    }
    if (widget.enabled && _focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger shake animation when there's an error
    if (widget.errorText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerErrorAnimation();
      });
    }

    return Column(
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  widget.length,
                  (index) => _buildOTPField(index),
                ),
              ),
            );
          },
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOTPField(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.errorText != null
              ? Theme.of(context).colorScheme.error
              : _focusNodes[index].hasFocus
                  ? AppTheme.primary
                  : Colors.grey.shade300,
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: widget.enabled 
            ? Colors.white 
            : Colors.grey.shade50,
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onFieldKeyPressed(event, index),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: widget.enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.enabled 
                ? AppTheme.primary 
                : Colors.grey.shade400,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.length > 1) {
              // Handle paste operation
              _handlePaste(value, index);
            } else {
              _onFieldChanged(value, index);
            }
          },
          onTap: () {
            // Clear field when tapped
            _controllers[index].selection = TextSelection.fromPosition(
              TextPosition(offset: _controllers[index].text.length),
            );
          },
        ),
      ),
    );
  }

  void _handlePaste(String pastedText, int startIndex) {
    // Handle paste operation by distributing digits across fields
    final digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    
    for (int i = 0; i < digits.length && (startIndex + i) < widget.length; i++) {
      _controllers[startIndex + i].text = digits[i];
    }

    // Focus on the next empty field or last field
    int focusIndex = (startIndex + digits.length).clamp(0, widget.length - 1);
    _focusNodes[focusIndex].requestFocus();

    // Check if OTP is complete
    String otp = _controllers.map((controller) => controller.text).join();
    widget.onChanged?.call(otp);
    
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }
}

// Extension to easily get OTP value
extension OTPInputFieldController on GlobalKey<OTPInputFieldState> {
  String get otpValue {
    final state = currentState;
    if (state == null) return '';
    return state._controllers.map((controller) => controller.text).join();
  }

  void clearOTP() {
    currentState?.clearOTP();
  }

  bool get isComplete {
    final state = currentState;
    if (state == null) return false;
    return otpValue.length == state.widget.length;
  }
}