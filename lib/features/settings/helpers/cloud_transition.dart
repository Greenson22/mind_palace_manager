// lib/features/settings/helpers/cloud_transition.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Helper class untuk memanggil navigasi dengan efek awan
class CloudNavigation {
  // Cache posisi bubble agar konsisten (tidak berubah setiap kali animasi jalan)
  static final List<_CloudBubble> _cachedBubbles = _generateBubbles();

  /// Fungsi utama untuk pindah halaman
  static void push(BuildContext context, Widget newPage) {
    Navigator.of(context).push(_CloudPageRoute(newPage, _cachedBubbles));
  }

  /// Generate sekumpulan posisi dan ukuran lingkaran secara acak
  static List<_CloudBubble> _generateBubbles() {
    final random = Random();
    final List<_CloudBubble> bubbles = [];

    // 1. Awan Kiri (Bergerak dari kiri luar ke tengah)
    for (int i = 0; i < 20; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: -0.6 - random.nextDouble() * 0.6, // Start: Luar Kiri
          initialY: random.nextDouble(), // Y: Acak atas-bawah
          targetX: 0.3 + random.nextDouble() * 0.2, // End: Agak ke tengah
          targetY: random.nextDouble(),
          baseRadius: 0.18 + random.nextDouble() * 0.2, // Ukuran acak
        ),
      );
    }

    // 2. Awan Kanan (Bergerak dari kanan luar ke tengah)
    for (int i = 0; i < 20; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: 1.6 + random.nextDouble() * 0.6, // Start: Luar Kanan
          initialY: random.nextDouble(),
          targetX: 0.7 - random.nextDouble() * 0.2, // End: Agak ke tengah
          targetY: random.nextDouble(),
          baseRadius: 0.18 + random.nextDouble() * 0.2,
        ),
      );
    }

    // 3. Awan Tengah/Filler (Untuk menutup celah di tengah)
    for (int i = 0; i < 15; i++) {
      bubbles.add(
        _CloudBubble(
          initialX: random.nextBool() ? -0.8 : 1.8, // Start: Jauh Kiri/Kanan
          initialY: random.nextDouble(),
          targetX: 0.5 + (random.nextDouble() - 0.5) * 0.4, // End: Area tengah
          targetY: random.nextDouble(),
          baseRadius: 0.25 + random.nextDouble() * 0.25, // Lebih besar
        ),
      );
    }

    return bubbles;
  }
}

/// Custom PageRouteBuilder untuk mengatur durasi dan animasi
class _CloudPageRoute extends PageRouteBuilder {
  final Widget newPage;
  final List<_CloudBubble> bubbles;

  _CloudPageRoute(this.newPage, this.bubbles)
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => newPage,
        transitionDuration: const Duration(milliseconds: 1800),
        reverseTransitionDuration: const Duration(milliseconds: 1500),
        opaque: false,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              // Hitung progress:
              // 0.0 -> 0.5 : Fase Menutup
              // 0.5 -> 1.0 : Fase Membuka (di halaman baru)

              double cloudProgress = 0.0;

              if (animation.value <= 0.5) {
                // Fase Menutup: 0.0 -> 1.0
                cloudProgress = animation.value * 2;
              } else {
                // Fase Membuka: 1.0 -> 0.0
                cloudProgress = 2.0 - (animation.value * 2);
              }

              // Tampilkan halaman baru hanya jika animasi sudah lewat setengah
              final bool showNewPage = animation.value > 0.5;

              // PERBAIKAN:
              // Jika animasi selesai (value >= 1.0), kita harus mengabaikan sentuhan
              // pada layer awan agar tembus ke halaman di bawahnya.
              // Saat animasi berjalan (< 1.0), kita blokir sentuhan agar user
              // tidak tidak sengaja menekan tombol saat transisi.
              final bool ignoreTouchesOnCloud = animation.value >= 0.99;

              return Stack(
                children: [
                  // Layer 1: Halaman (Lama atau Baru)
                  showNewPage ? child! : const SizedBox(),

                  // Layer 2: Kanvas Awan (Dengan IgnorePointer)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: ignoreTouchesOnCloud, // KUNCI PERBAIKAN
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

/// Painter yang menggambar lingkaran-lingkaran putih
class _CloudPainter extends CustomPainter {
  final double progress;
  final List<_CloudBubble> bubbles;

  _CloudPainter(this.progress, this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    // Jika progress 0, tidak perlu gambar apa-apa
    if (progress <= 0.01) return;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final bubble in bubbles) {
      double currentX = lerpDouble(bubble.initialX, bubble.targetX, progress)!;
      double currentY = lerpDouble(bubble.initialY, bubble.targetY, progress)!;

      double radiusFactor = 1.0 + (0.2 * progress);
      double currentRadius = (bubble.baseRadius * size.width) * radiusFactor;

      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        currentRadius,
        paint,
      );
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
