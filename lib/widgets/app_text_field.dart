import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_validateOnLeave);
  }

  // Show the error as soon as the user leaves the field
  void _validateOnLeave() {
    if (!_focusNode.hasFocus && mounted) {
      _fieldKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_validateOnLeave);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMultiline = !widget.isPassword && widget.maxLines > 1;

    return TextFormField(
      key: _fieldKey,
      focusNode: _focusNode,
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      keyboardType: isMultiline ? TextInputType.multiline : widget.keyboardType,
      validator: widget.validator,
      // After the user starts typing, re-check on every change
      autovalidateMode: AutovalidateMode.onUserInteraction,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      textInputAction: widget.textInputAction ??
          (isMultiline ? TextInputAction.newline : TextInputAction.next),
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}