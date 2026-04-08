import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  // Screen sizes
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 850;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 850 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    // If width is >= 1100, return desktop
    if (size.width >= 1100) {
      return desktop;
    }
    // If width >= 850 and < 1100, return tablet (or desktop if tablet not provided)
    else if (size.width >= 850) {
      return tablet ?? desktop;
    }
    // Return mobile
    else {
      return mobile;
    }
  }
}
