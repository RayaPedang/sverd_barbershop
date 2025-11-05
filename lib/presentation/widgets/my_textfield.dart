import 'package:flutter/material.dart';
import 'package:sverd_barbershop/core/theme/colors.dart'; // <-- DIMODIFIKASI

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final Widget? suffixIcon;
  final Color? labelColor;
  final Color? fillColor;

  const MyTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.suffixIcon,
    this.labelColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color inputColor =
        (fillColor == kDarkComponentColor) ? kLightTextColor : kTextColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: labelColor ?? kTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: inputColor),
          keyboardAppearance: (fillColor == kDarkComponentColor)
              ? Brightness.dark
              : Brightness.light,
          cursorColor: kPrimaryColor,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 20.0,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor ?? kBackgroundColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: kSecondaryTextColor.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
