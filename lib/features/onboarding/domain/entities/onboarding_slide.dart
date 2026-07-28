import 'package:flutter/material.dart';

/// Entitas satu halaman (slide) pada onboarding.
///
/// Berada di layer domain: murni data, tanpa ketergantungan ke framework
/// selain tipe warna/ikon dasar yang dipakai untuk presentasi.
@immutable
class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
