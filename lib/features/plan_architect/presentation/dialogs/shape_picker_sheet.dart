import 'package:flutter/material.dart';
import '../../logic/plan_enums.dart';
import '../../logic/plan_controller.dart';
import '../utils/plan_shapes_helper.dart';

class ShapePickerSheet extends StatelessWidget {
  final PlanController controller;

  const ShapePickerSheet({super.key, required this.controller});

  // Mengelompokkan bentuk berdasarkan kategori untuk tab
  Map<String, List<PlanShapeType>> get _categories => {
    'Dasar': [
      PlanShapeType.rectangle,
      PlanShapeType.roundedRect,
      PlanShapeType.circle,
      PlanShapeType.triangle,
      PlanShapeType.rightTriangle,
      PlanShapeType.diamond,
      PlanShapeType.parallelogram,
      PlanShapeType.trapezoid,
    ],
    'Poligon & Bintang': [
      PlanShapeType.pentagon,
      PlanShapeType.hexagon,
      PlanShapeType.heptagon,
      PlanShapeType.octagon,
      PlanShapeType.decagon,
      PlanShapeType.star,
      PlanShapeType.star4,
      PlanShapeType.star6,
      PlanShapeType.star8,
      PlanShapeType.moon,
      PlanShapeType.sun,
      PlanShapeType.cloud,
    ],
    'Panah': [
      PlanShapeType.arrowUp,
      PlanShapeType.arrowRight,
      PlanShapeType.arrowDown,
      PlanShapeType.arrowLeft,
      PlanShapeType.doubleArrowH,
      PlanShapeType.doubleArrowV,
      PlanShapeType.chevronUp,
      PlanShapeType.chevronRight,
      PlanShapeType.blockArrowRight,
      PlanShapeType.curvedArrowRight,
    ],
    'Arsitek & Simbol': [
      PlanShapeType.lShape,
      PlanShapeType.uShape,
      PlanShapeType.tShape,
      PlanShapeType.plusShape,
      PlanShapeType.stairs,
      PlanShapeType.columnRound,
      PlanShapeType.columnSquare,
      PlanShapeType.iBeam,
      PlanShapeType.arc,
      PlanShapeType.heart,
      PlanShapeType.cross,
      PlanShapeType.check,
      PlanShapeType.xMark,
    ],
    'Diagram': [
      PlanShapeType.process,
      PlanShapeType.decision,
      PlanShapeType.document,
      PlanShapeType.database,
      PlanShapeType.bubbleRound,
      PlanShapeType.bubbleSquare,
      PlanShapeType.thoughtBubble,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Opsi Toggle Fill
          StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pilih Bentuk",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilterChip(
                      label: const Text("Isi Warna (Solid)"),
                      selected: controller.shapeFilled,
                      onSelected: (val) {
                        controller.setShapeFilled(val);
                        setState(() {}); // Rebuild local toggle UI
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: DefaultTabController(
              length: _categories.keys.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    tabs: _categories.keys.map((k) => Tab(text: k)).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: _categories.values.map((shapes) {
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: shapes.length,
                          itemBuilder: (context, index) {
                            final shapeType = shapes[index];
                            return _buildShapeItem(context, shapeType);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeItem(BuildContext context, PlanShapeType type) {
    return InkWell(
      onTap: () {
        controller.selectShape(type);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: CustomPaint(
          painter: _ShapePreviewPainter(
            type: type,
            color: Theme.of(context).colorScheme.primary,
            filled: controller.shapeFilled,
          ),
        ),
      ),
    );
  }
}

class _ShapePreviewPainter extends CustomPainter {
  final PlanShapeType type;
  final Color color;
  final bool filled;

  _ShapePreviewPainter({
    required this.type,
    required this.color,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = color.withOpacity(filled ? 1.0 : 0.0)
      ..style = PaintingStyle.fill;

    PlanShapesHelper.drawShape(canvas, type, rect, fillPaint, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
