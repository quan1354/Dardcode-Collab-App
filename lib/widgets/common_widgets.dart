import 'package:flutter/material.dart';
import 'package:darkord/consts/app_constants.dart';

/// Reusable app logo widget
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        border: Border.all(
          color: AppConstants.borderColorYellow,
          width: 5.0,
        ),
      ),
      child: Image.asset(
        AppConstants.logoPath,
        width: AppConstants.logoWidth,
        height: AppConstants.logoHeight,
      ),
    );
  }
}

/// Reusable app title widget
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppConstants.appName,
      style: AppConstants.appTitleStyle,
    );
  }
}

/// Reusable custom text field with consistent styling
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool readOnly;
  final int? maxLength;
  final void Function(String)? onChanged;
  final String? initialValue;

  const CustomTextField({
    super.key,
    this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.readOnly = false,
    this.maxLength,
    this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      style: AppConstants.labelStyle,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.borderColorNormal),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.borderColorNormal),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppConstants.borderColorFocused),
        ),
        labelText: labelText,
        labelStyle: AppConstants.labelStyle,
        hintText: hintText,
        hintStyle: AppConstants.hintStyle,
        prefixIcon: Icon(prefixIcon, color: AppConstants.whiteColor),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

/// Reusable password text field with visibility toggle
class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String? Function(String?)? validator;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.labelText = 'Password',
    this.hintText = 'Password',
    this.validator,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: Icons.lock,
      obscureText: _obscurePassword,
      validator: widget.validator,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off,
          color: AppConstants.whiteColor,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }
}

/// Reusable link button
class LinkButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const LinkButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppConstants.errorColor),
            const SizedBox(width: 5),
          ],
          Text(text, style: AppConstants.linkStyle),
        ],
      ),
    );
  }
}

/// Reusable primary button
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? AppConstants.buttonWidth,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text),
      ),
    );
  }
}

/// Reusable loading indicator
class LoadingIndicator extends StatelessWidget {
  final String message;

  const LoadingIndicator({
    super.key,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Reusable empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}