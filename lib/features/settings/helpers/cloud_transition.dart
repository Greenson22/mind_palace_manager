// lib/features/settings/helpers/cloud_transition.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_settings.dart'; // Import AppSettings

/// Helper class untuk memanggil navigasi dengan efek awan
class CloudNavigation {
  // Cache posisi bubble agar konsisten
  static final List<_CloudBubble> _cachedBubbles = _generateBubbles();

  /// Fungsi utama untuk pindah halaman
  static void push(BuildContext context, Widget newPage) {
    // CEK PENGATURAN: Jika dimatikan, gunakan navigasi standar
    if (!AppSettings.enableCloudTransition) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => newPage));
      return;
    }

    Navigator.of(context).push(_CloudPageRoute(newPage, _cachedBubbles));
  }

  /// Generate sekumpulan posisi dan ukuran lingkaran secara acak
  static List<_CloudBubble> _generateBubbles() {
    final random = Random();
    final List<_CloudBubble> bubbles = [];

    // 1. Awan Kiri
    for (int i = 0; i < 20; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: -0.6 - random.nextDouble() * 0.6,
          initialY: random.nextDouble(),
          targetX: 0.3 + random.nextDouble() * 0.2,
          targetY: random.nextDouble(),
          baseRadius: 0.18 + random.nextDouble() * 0.2,
        ),
      );
    }

    // 2. Awan Kanan
    for (int i = 0; i < 20; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: 1.6 + random.nextDouble() * 0.6,
          initialY: random.nextDouble(),
          targetX: 0.7 - random.nextDouble() * 0.2,
          targetY: random.nextDouble(),
          baseRadius: 0.18 + random.nextDouble() * 0.2,
        ),
      );
    }

    // 3. Awan Tengah/Filler
    for (int i = 0; i < 15; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: random.nextBool() ? -0.8 : 1.8,
          initialY: random.nextDouble(),
          targetX: 0.5 + (random.nextDouble() - 0.5) * 0.4,
          targetY: random.nextDouble(),
          baseRadius: 0.25 + random.nextDouble() * 0.25,
        ),
      );
    }

    return bubbles;
  }
}

/// Custom PageRouteBuilder
class _CloudPageRoute extends PageRouteBuilder {
  final Widget newPage;
  final List<_CloudBubble> bubbles;

  _CloudPageRoute(this.newPage, this.bubbles)
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => newPage,
        // DURASI DINAMIS DARI SETTINGS
        transitionDuration: Duration(
          milliseconds: (AppSettings.cloudTransitionDuration * 1000).toInt(),
        ),
        reverseTransitionDuration: Duration(
          milliseconds: (AppSettings.cloudTransitionDuration * 0.8 * 1000)
              .toInt(),
        ),
        opaque: false,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              double cloudProgress = 0.0;

              if (animation.value <= 0.5) {
                cloudProgress = animation.value * 2;
              } else {
                cloudProgress = 2.0 - (animation.value * 2);
              }

              final bool showNewPage = animation.value > 0.5;

              // Ignore pointer saat animasi selesai agar tidak memblokir sentuhan
              final bool ignoreTouchesOnCloud = animation.value >= 0.99;

              return Stack(
                children: [
                  showNewPage ? child! : const SizedBox(),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: ignoreTouchesOnCloud,
                      child: CustomPaint(
                        painter: _CloudPainter(cloudProgress, bubbles),
                      ),
                    ),
                  ),
                ],
              );
            },
            child: child,
          );
        },
      );
}

/// Painter yang menggambar partikel awan
class _CloudPainter extends CustomPainter {
  final double progress;
  final List<_CloudBubble> bubbles;

  // Ambil warna dan bentuk dari AppSettings
  final Color cloudColor = Color(AppSettings.cloudColor);
  final String shapeType = AppSettings.cloudShape;

  _CloudPainter(this.progress, this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;

    final paint = Paint()
      ..color = cloudColor
      ..style = PaintingStyle.fill;

    for (final bubble in bubbles) {
      double currentX = lerpDouble(bubble.initialX, bubble.targetX, progress)!;
      double currentY = lerpDouble(bubble.initialY, bubble.targetY, progress)!;

      double radiusFactor = 1.0 + (0.2 * progress);
      double currentRadius = (bubble.baseRadius * size.width) * radiusFactor;

      final Offset center = Offset(
        currentX * size.width,
        currentY * size.height,
      );

      // LOGIKA BENTUK DINAMIS
      switch (shapeType) {
        case 'Kotak':
          // Gambar Persegi
          canvas.drawRect(
            Rect.fromCenter(
              center: center,
              width: currentRadius * 2,
              height: currentRadius * 2,
            ),
            paint,
          );
          break;

        case 'Wajik':
          // Gambar Wajik (Diamond)
          final path = Path();
          path.moveTo(center.dx, center.dy - currentRadius); // Top
          path.lineTo(center.dx + currentRadius, center.dy); // Right
          path.lineTo(center.dx, center.dy + currentRadius); // Bottom
          path.lineTo(center.dx - currentRadius, center.dy); // Left
          path.close();
          canvas.drawPath(path, paint);
          break;

        case 'Bulat':
        default:
          // Gambar Lingkaran Default
          canvas.drawCircle(center, currentRadius, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CloudBubble {
  final double initialX;
  final double initialY;
  final double targetX;
  final double targetY;
  final double baseRadius;

  _CloudBubble({
    required this.initialX,
    required this.initialY,
    required this.targetX,
    required this.targetY,
    required this.baseRadius,
  });
}
