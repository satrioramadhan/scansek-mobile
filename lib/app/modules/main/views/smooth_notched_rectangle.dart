import 'dart:math' as math;
import 'package:flutter/material.dart';

class SmoothNotchedRectangle extends NotchedShape {
  /// Controls the width and smoothness of the corners transitioning into the notch.
  /// Flutter's default CircularNotchedRectangle uses 15.0. 
  /// A higher value (e.g. 35.0 - 45.0) makes the corners much smoother and rounder.
  final double smoothness;
  final double cornerRadius;

  const SmoothNotchedRectangle({
    this.smoothness = 35.0, 
    this.cornerRadius = 24.0,
  });

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) {
      return Path()..addRRect(RRect.fromRectAndRadius(host, Radius.circular(cornerRadius)));
    }

    final double r = guest.width / 2.0;
    final Radius notchRadius = Radius.circular(r);

    const double s2 = 1.0;
    final double a = -r - s2;
    final double b = host.top - guest.center.dy;

    final double discriminant = b * b * r * r * (a * a + b * b - r * r);
    if (discriminant < 0) {
      return Path()..addRRect(RRect.fromRectAndRadius(host, Radius.circular(cornerRadius)));
    }

    final double n2 = math.sqrt(discriminant);
    final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
    
    double valA = r * r - p2xA * p2xA;
    double valB = r * r - p2xB * p2xB;
    valA = valA < 0 ? 0 : valA;
    valB = valB < 0 ? 0 : valB;

    final double p2yA = math.sqrt(valA);
    final double p2yB = math.sqrt(valB);

    final List<Offset> p = List<Offset>.filled(6, Offset.zero);

    p[0] = Offset(a - smoothness, b);
    p[1] = Offset(a, b);
    final double cmp = b < 0 ? -1.0 : 1.0;
    p[2] = cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);

    p[3] = Offset(-1.0 * p[2].dx, p[2].dy);
    p[4] = Offset(-1.0 * p[1].dx, p[1].dy);
    p[5] = Offset(-1.0 * p[0].dx, p[0].dy);

    for (int i = 0; i < p.length; i += 1) {
      p[i] += guest.center;
    }

    final Path path = Path()..moveTo(host.left + cornerRadius, host.top);
    path
      ..lineTo(p[0].dx, p[0].dy)
      ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
      ..arcToPoint(p[3], radius: notchRadius, clockwise: false)
      ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
      ..lineTo(host.right - cornerRadius, host.top)
      ..quadraticBezierTo(host.right, host.top, host.right, host.top + cornerRadius)
      ..lineTo(host.right, host.bottom - cornerRadius)
      ..quadraticBezierTo(host.right, host.bottom, host.right - cornerRadius, host.bottom)
      ..lineTo(host.left + cornerRadius, host.bottom)
      ..quadraticBezierTo(host.left, host.bottom, host.left, host.bottom - cornerRadius)
      ..lineTo(host.left, host.top + cornerRadius)
      ..quadraticBezierTo(host.left, host.top, host.left + cornerRadius, host.top);

    return path..close();
  }
}
