import 'package:flutter/material.dart';
import '../constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final double height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.height = 50,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(25));
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: shape,
          ),
          onPressed: onPressed,
          child: _label(AppColors.primary),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: shape,
          elevation: 2,
        ),
        onPressed: onPressed,
        child: _label(Colors.white),
      ),
    );
  }

  Widget _label(Color color) {
    final textWidget = Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
    );
    if (icon == null) return textWidget;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        textWidget,
      ],
    );
  }
}
