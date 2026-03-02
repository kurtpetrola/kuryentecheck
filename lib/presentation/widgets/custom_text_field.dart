import 'package:flutter/material.dart';

/// A reusable, styled text input field with validation support
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    super.key,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}
