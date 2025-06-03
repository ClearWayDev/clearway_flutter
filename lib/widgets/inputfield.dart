import 'package:flutter/material.dart';

Widget styledInputField({
  required String label,
  required TextEditingController controller,
  bool obscure = false,
  Widget? suffixIcon,
  String? Function(String?)? validator,
}) {
  return Container(
    height: 56,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Center(
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: const TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 14,
            color: Color(0xFF9CA3AF),
          ),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    ),
  );
}
