import 'package:flutter/material.dart';
import 'package:patenaire/core/constants/color_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final Color? titleColor;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.titleColor,
    this.automaticallyImplyLeading = true,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? ColorConstants.primaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Colors.white,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      iconTheme: IconThemeData(color: ColorConstants.primaryColor),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

// Extension qui permet de créer facilement un AppBar avec des options prédéfinies
extension AppBarExtensions on CustomAppBar {
  static CustomAppBar primary({
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    double elevation = 0,
    bool automaticallyImplyLeading = true,
    Widget? leading,
  }) {
    return CustomAppBar(
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: Colors.white,
      titleColor: ColorConstants.primaryTextColor,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
    );
  }

  static CustomAppBar transparent({
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    Color titleColor = Colors.white,
    bool automaticallyImplyLeading = true,
    Widget? leading,
  }) {
    return CustomAppBar(
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      elevation: 0,
      backgroundColor: Colors.transparent,
      titleColor: titleColor,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
    );
  }
}
