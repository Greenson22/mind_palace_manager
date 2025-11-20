// lib/features/settings/helpers/cloud_transition.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_settings.dart';

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

    // 1. Awan Kiri (Bergerak dari Kiri -> Tengah)
    for (int i = 0; i < 15; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: -0.6 - random.nextDouble() * 0.5, // Start: Luar Kiri
          initialY: random.nextDouble(), // Y: Acak
          targetX: 0.3 + random.nextDouble() * 0.2, // End: Tengah Kiri
          targetY: random.nextDouble(),
          baseRadius: 0.18 + random.nextDouble() * 0.2,
        ),
      );
    }

    // 2. Awan Kanan (Bergerak dari Kanan -> Tengah)
    for (int i = 0; i < 15; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: 1.6 + random.nextDouble() * 0.5, // Start: Luar Kanan
          initialY: random.nextDouble(), // Y: Acak
          targetX: 0.7 - random.nextDouble() * 0.2, // End: Tengah Kanan
          targetY: random.nextDouble(),
          baseRadius: 0.18 + random.nextDouble() * 0.2,
        ),
      );
    }

    // 3. Awan Atas (Bergerak dari Atas -> Tengah) -- BARU
    for (int i = 0; i < 15; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: random.nextDouble(), // X: Acak
          initialY: -0.6 - random.nextDouble() * 0.5, // Start: Luar Atas
          targetX: random.nextDouble(),
          targetY: 0.3 + random.nextDouble() * 0.2, // End: Tengah Atas
          baseRadius: 0.18 + random.nextDouble() * 0.2,
        ),
      );
    }

    // 4. Awan Bawah (Bergerak dari Bawah -> Tengah) -- BARU
    for (int i = 0; i < 15; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: random.nextDouble(), // X: Acak
          initialY: 1.6 + random.nextDouble() * 0.5, // Start: Luar Bawah
          targetX: random.nextDouble(),
          targetY: 0.7 - random.nextDouble() * 0.2, // End: Tengah Bawah
          baseRadius: 0.18 + random.nextDouble() * 0.2,
        ),
      );
    }

    // 5. Filler / Penutup Celah (Datang acak dari jauh untuk menutup lubang di tengah)
    for (int i = 0; i < 10; i++) {
      // Tentukan secara acak datang dari arah mana (Horizontal atau Vertikal)
      bool vertical = random.nextBool();
      double startX, startY;

      if (vertical) {
        startX = random.nextDouble();
        startY = random.nextBool() ? -0.8 : 1.8; // Jauh di atas/bawah
      } else {
        startX = random.nextBool() ? -0.8 : 1.8; // Jauh di kiri/kanan
        startY = random.nextDouble();
      }

      bubbles.add(
        _CloudBubble(
          initialX: startX,
          initialY: startY,
          targetX: 0.5 + (random.nextDouble() - 0.5) * 0.3, // Tepat di tengah
          targetY: 0.5 + (random.nextDouble() - 0.5) * 0.3,
          baseRadius: 0.25 + random.nextDouble() * 0.25, // Ukuran besar
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
        // Durasi diambil dari AppSettings
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
                // 0.0 -> 0.5 : Awan Masuk (Menutup)
                cloudProgress = animation.value * 2;
              } else {
                // 0.5 -> 1.0 : Awan Keluar (Membuka)
                cloudProgress = 2.0 - (animation.value * 2);
              }

              // Ganti halaman saat tertutup penuh (progress > 0.5)
              final bool showNewPage = animation.value > 0.5;

              // IGNORE POINTER LOGIC:
              // Saat animasi hampir selesai (value >= 0.99), matikan hit-test pada awan
              // agar pengguna bisa menekan tombol di halaman baru.
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

  // Ambil setting warna & bentuk
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
      // Interpolasi Linear (Lerp) posisi saat ini
      double currentX = lerpDouble(bubble.initialX, bubble.targetX, progress)!;
      double currentY = lerpDouble(bubble.initialY, bubble.targetY, progress)!;

      // Efek membesar sedikit saat mendekati tengah
      double radiusFactor = 1.0 + (0.2 * progress);
      double currentRadius = (bubble.baseRadius * size.width) * radiusFactor;

      final Offset center = Offset(
        currentX * size.width,
        currentY * size.height,
      );

      // Logika Menggambar Bentuk
      switch (shapeType) {
        case 'Kotak':
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
          final path = Path();
          path.moveTo(center.dx, center.dy - currentRadius);
          path.lineTo(center.dx + currentRadius, center.dy);
          path.lineTo(center.dx, center.dy + currentRadius);
          path.lineTo(center.dx - currentRadius, center.dy);
          path.close();
          canvas.drawPath(path, paint);
          break;

        case 'Bulat':
        default:
          canvas.drawCircle(center, currentRadius, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.cloudColor != cloudColor ||
        oldDelegate.shapeType != shapeType;
  }
}

/// Data model posisi bubble
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
