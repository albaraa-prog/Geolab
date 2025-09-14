import 'package:flutter/material.dart';
import 'package:geolab/features/Auth/component/OTPInputField.dart';


class OTPTestPage extends StatefulWidget {
  const OTPTestPage({Key? key}) : super(key: key);

  @override
  State<OTPTestPage> createState() => _OTPTestPageState();
}

class _OTPTestPageState extends State<OTPTestPage> {
  final GlobalKey<OTPInputFieldState> _otpKey = GlobalKey<OTPInputFieldState>();
  String? _errorText;
  String _otpValue = "";

  void _verifyOTP() {
    final otp = _otpKey.otpValue;
    if (otp == "123456") {
      setState(() {
        _errorText = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified Successfully!")),
      );
    } else {
      setState(() {
        _errorText = "Invalid OTP. Try 123456";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OTP Test Page"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OTPInputField(
              key: _otpKey,
              length: 6,
              onCompleted: (otp) {
                setState(() {
                  _otpValue = otp;
                });
              },
              onChanged: (otp) {
                setState(() {
                  _otpValue = otp;
                  _errorText = null; // clear error while typing
                });
              },
              errorText: _errorText,
            ),
            const SizedBox(height: 20),
            Text(
              "Entered OTP: $_otpValue",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _verifyOTP,
              child: const Text("Verify OTP"),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _otpKey.clearOTP(),
              child: const Text("Clear OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
