// lib/features/pixel_studio/presentation/pixel_studio_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../logic/drawing_controller.dart';
import 'canvas_painter.dart';

class PixelStudioPage extends StatefulWidget {
  const PixelStudioPage({super.key});

  @override
  State<PixelStudioPage> createState() => _PixelStudioPageState();
}

class _PixelStudioPageState extends State<PixelStudioPage> {
  final DrawingController _controller = DrawingController();
  final TransformationController _transformController =
      TransformationController();

  // Nilai zoom saat ini untuk grid dinamis
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(() {
      setState(() {
        _currentScale = _transformController.value.getMaxScaleOnAxis();
      });
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Warna tema Void Black
    const Color voidBlack = Color(0xFF0C0C0C);

    return Scaffold(
      backgroundColor: voidBlack,
      body: Stack(
        children: [
          // --- LAYER 1: WORKSPACE (CANVAS) ---
          Center(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 20.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              // Jika tool adalah Hand, aktifkan pan. Jika Pencil/Eraser, matikan pan (1 jari draw).
              panEnabled: _controller.activeTool == DrawingTool.hand,
              scaleEnabled: true,
              child: Container(
                width: 300, // Ukuran fisik kanvas di layar (base size)
                height: 300,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                // GestureDetector untuk menangkap input gambar
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, child) {
                    return GestureDetector(
                      onPanStart: (details) => _controller.drawPixel(
                        details.localPosition,
                        const Size(300, 300),
                      ),
                      onPanUpdate: (details) => _controller.drawPixel(
                        details.localPosition,
                        const Size(300, 300),
                      ),
                      onTapDown: (details) => _controller.drawPixel(
                        details.localPosition,
                        const Size(300, 300),
                      ),
                      child: CustomPaint(
                        painter: PixelCanvasPainter(
                          controller: _controller,
                          zoomScale: _currentScale,
                        ),
                        size: const Size(300, 300),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // --- LAYER 2: UTILITY CORNERS (ATAS) ---
          Positioned(
            top: 40,
            left: 16,
            child: _buildGlassButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Row(
              children: [
                _buildGlassButton(
                  icon: Icons.save_alt,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur simpan akan segera hadir!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // --- LAYER 3: CONTROL HUB (BAWAH) ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Center(child: _buildControlCapsule()),
          ),
        ],
      ),
    );
  }

  // Widget: Tombol Kaca (Glass Button) Kecil
  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            color: Colors.white.withOpacity(0.1),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // Widget: The Dynamic Capsule (Pusat Kontrol)
  Widget _buildControlCapsule() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.grey.shade900.withOpacity(0.6),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Hand Tool (Pan/Zoom Mode)
                  _buildToolIcon(
                    icon: Icons.pan_tool,
                    isActive: _controller.activeTool == DrawingTool.hand,
                    onTap: () => _controller.setTool(DrawingTool.hand),
                  ),
                  const SizedBox(width: 20),

                  // 2. Pencil Tool
                  _buildToolIcon(
                    icon: Icons.edit,
                    isActive: _controller.activeTool == DrawingTool.pencil,
                    onTap: () => _controller.setTool(DrawingTool.pencil),
                  ),
                  const SizedBox(width: 20),

                  // 3. Eraser Tool
                  _buildToolIcon(
                    icon: Icons
                        .backspace_outlined, // Ikon penghapus yang lebih umum
                    isActive: _controller.activeTool == DrawingTool.eraser,
                    onTap: () => _controller.setTool(DrawingTool.eraser),
                  ),

                  // Divider Vertikal Kecil
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    width: 1,
                    height: 30,
                    color: Colors.white24,
                  ),

                  // 4. Color Dot (Indikator Warna)
                  GestureDetector(
                    onTap: () => _showColorPicker(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _controller.activeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper untuk Ikon Tool
  Widget _buildToolIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // Dialog Pemilih Warna Sederhana
  void _showColorPicker() {
    final List<Color> palette = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.brown,
      Colors.grey,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          spacing: 15,
          runSpacing: 15,
          alignment: WrapAlignment.center,
          children: palette.map((color) {
            return GestureDetector(
              onTap: () {
                _controller.setColor(color);
                Navigator.pop(c);
              },
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
