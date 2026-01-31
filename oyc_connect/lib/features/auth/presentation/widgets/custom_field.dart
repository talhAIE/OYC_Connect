import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallete.dart';

class CustomField extends StatefulWidget {
  final String hintText;
  final IconData? icon;
  final bool isObscure;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomField({
    super.key,
    required this.hintText,
    this.icon,
    this.isObscure = false,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<CustomField> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isObscure;
  }

  @override
  Widget build(BuildContext context) {
    const double borderRadiusValue = 12.0;

    return Container(
      decoration: BoxDecoration(
        color: AppPallete.white,
        borderRadius: BorderRadius.circular(borderRadiusValue),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.05,
            ), // Subtle, professional shadow
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(8, 0), // Positioned slightly downwards
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _isObscure,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.black.withAlpha(110)),
          prefixIcon: widget.icon != null
              ? Icon(widget.icon, color: Colors.black.withAlpha(125))
              : null,
          suffixIcon: widget.isObscure
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black.withAlpha(95),
                  ),
                )
              : null,
          filled: true,
          fillColor: AppPallete.white,
          contentPadding: const EdgeInsets.all(18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPallete.primary, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPallete.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPallete.error, width: 2),
          ),
        ),
      ),
    );
  }
}
