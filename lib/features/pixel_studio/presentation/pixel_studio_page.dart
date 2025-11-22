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
          // LAYER 1: WORKSPACE (CANVAS)
          Center(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.1,
              maxScale: 30.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              // Pan enabled jika mode Hand, atau jika zoom sangat jauh (opsional)
              panEnabled: _controller.activeTool == DrawingTool.hand,
              scaleEnabled: true,
              child: Container(
                width: 320, // Ukuran Render Box
                height: 320,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, child) {
                    return GestureDetector(
                      onPanStart: (d) => _controller.startStroke(
                        d.localPosition,
                        const Size(320, 320),
                      ),
                      onPanUpdate: (d) => _controller.updateStroke(
                        d.localPosition,
                        const Size(320, 320),
                      ),
                      onPanEnd: (d) => _controller.endStroke(),
                      onTapDown: (d) {
                        _controller.startStroke(
                          d.localPosition,
                          const Size(320, 320),
                        );
                        _controller.endStroke(); // Tap dianggap stroke instan
                      },
                      child: CustomPaint(
                        painter: PixelCanvasPainter(
                          controller: _controller,
                          zoomScale: _currentScale,
                        ),
                        size: const Size(320, 320),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // LAYER 2: TOP BAR
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
                        content: Text('Fitur simpan sedang dikembangkan.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // LAYER 3: CONTROL HUB (CAPSULE)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16, // Lebar penuh dengan padding
            child: Center(child: _buildControlCapsule()),
          ),
        ],
      ),
    );
  }

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

  Widget _buildControlCapsule() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.grey.shade900.withOpacity(0.85),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CLUSTER 1: UNDO / REDO
                  IconButton(
                    icon: Icon(
                      Icons.undo,
                      color: _controller.canUndo
                          ? Colors.white
                          : Colors.white24,
                    ),
                    onPressed: _controller.undo,
                    tooltip: "Undo",
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.redo,
                      color: _controller.canRedo
                          ? Colors.white
                          : Colors.white24,
                    ),
                    onPressed: _controller.redo,
                    tooltip: "Redo",
                  ),

                  _buildVerticalDivider(),

                  // CLUSTER 2: TOOLS
                  _buildToolIcon(
                    icon: Icons.pan_tool,
                    isActive: _controller.activeTool == DrawingTool.hand,
                    onTap: () => _controller.setTool(DrawingTool.hand),
                  ),
                  const SizedBox(width: 8),
                  _buildToolIcon(
                    icon: Icons.edit,
                    isActive: _controller.activeTool == DrawingTool.pencil,
                    onTap: () => _controller.setTool(DrawingTool.pencil),
                  ),
                  const SizedBox(width: 8),
                  _buildToolIcon(
                    icon: Icons.backspace_outlined,
                    isActive: _controller.activeTool == DrawingTool.eraser,
                    onTap: () => _controller.setTool(DrawingTool.eraser),
                  ),
                  const SizedBox(width: 8),

                  // Shape Tools (Menu)
                  PopupMenuButton<DrawingTool>(
                    tooltip: "Bentuk (Garis, Kotak, Lingkaran)",
                    offset: const Offset(0, -120),
                    color: Colors.grey.shade800,
                    icon: Icon(
                      _getShapeIcon(_controller.activeTool),
                      color: _isShape(_controller.activeTool)
                          ? Colors.blueAccent
                          : Colors.white,
                    ),
                    onSelected: (DrawingTool tool) {
                      _controller.setTool(tool);
                    },
                    itemBuilder: (context) => [
                      _buildMenuItem(
                        DrawingTool.line,
                        Icons.show_chart,
                        "Garis",
                      ),
                      _buildMenuItem(
                        DrawingTool.rectangle,
                        Icons.crop_square,
                        "Kotak",
                      ),
                      _buildMenuItem(
                        DrawingTool.circle,
                        Icons.circle_outlined,
                        "Lingkaran",
                      ),
                    ],
                  ),

                  _buildVerticalDivider(),

                  // CLUSTER 3: COLOR
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _controller.activeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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

  Widget _buildVerticalDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 1,
      height: 30,
      color: Colors.white24,
    );
  }

  Widget _buildToolIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  bool _isShape(DrawingTool tool) {
    return tool == DrawingTool.line ||
        tool == DrawingTool.rectangle ||
        tool == DrawingTool.circle;
  }

  IconData _getShapeIcon(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.line:
        return Icons.show_chart;
      case DrawingTool.rectangle:
        return Icons.crop_square;
      case DrawingTool.circle:
        return Icons.circle_outlined;
      // PERBAIKAN: Mengganti Icons.shapes dengan Icons.category
      default:
        return Icons.category;
    }
  }

  PopupMenuItem<DrawingTool> _buildMenuItem(
    DrawingTool tool,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: tool,
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  void _showColorPicker() {
    final List<Color> palette = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.pink,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.teal,
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
