// lib/presentation/common_widgets/loading_indicator.dart
import 'package:flutter/material.dart';
import 'package:patenaire/core/constants/color_constants.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size / 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorConstants.primaryColor,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: ColorConstants.primaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}