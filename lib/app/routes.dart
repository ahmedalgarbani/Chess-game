import 'package:flutter/material.dart';

/// Page transitions with a gentle fade and rise.
abstract final class AppRoutes {
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Future<T?> push<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push<T>(fade(page));

  static Future<T?> replace<T>(BuildContext context, Widget page) =>
      Navigator.of(context).pushReplacement<T, void>(fade(page));
}
