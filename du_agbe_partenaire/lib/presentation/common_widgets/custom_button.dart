import 'package:flutter/material.dart';
import 'package:patenaire/core/constants/color_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading; // Ajout du paramètre pour le chargement

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false, // Définition de la valeur par défaut
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child:
          isOutlined
              ? OutlinedButton(
                onPressed:
                    isLoading
                        ? null
                        : onPressed, // Désactivation pendant le chargement
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: backgroundColor ?? ColorConstants.primaryColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _buildButtonContent(),
              )
              : ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : onPressed, // Désactivation pendant le chargement
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      backgroundColor ?? ColorConstants.primaryColor,
                  foregroundColor: textColor ?? Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _buildButtonContent(),
              ),
    );
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
        ] else ...[
          if (icon != null) ...[Icon(icon), SizedBox(width: 8)],
          Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}
