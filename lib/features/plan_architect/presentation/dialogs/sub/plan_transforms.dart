import 'package:flutter/material.dart';
import 'dart:math' as math;

class PlanColorPickerDialog extends StatelessWidget {
  final Function(Color) onColorSelected;
  const PlanColorPickerDialog({super.key, required this.onColorSelected});

  static const List<Color> _colors = [
    Colors.black,
    Colors.grey,
    Colors.blueGrey,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pilih Warna"),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors
              .map(
                (color) => InkWell(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class PlanRotationDialog extends StatefulWidget {
  final double currentRotationRadians;
  final Function(double) onRotationChanged;

  const PlanRotationDialog({
    super.key,
    required this.currentRotationRadians,
    required this.onRotationChanged,
  });

  @override
  State<PlanRotationDialog> createState() => _PlanRotationDialogState();
}

class _PlanRotationDialogState extends State<PlanRotationDialog> {
  late double currentDegrees;

  @override
  void initState() {
    super.initState();
    currentDegrees = (widget.currentRotationRadians * 180 / math.pi) % 360;
    if (currentDegrees < 0) currentDegrees += 360;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Atur Rotasi"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey),
            ),
            child: Transform.rotate(
              angle: currentDegrees * math.pi / 180,
              child: const Icon(
                Icons.arrow_upward,
                size: 40,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "${currentDegrees.round()}°",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Slider(
            value: currentDegrees,
            min: 0.0,
            max: 360.0,
            divisions: 360,
            label: "${currentDegrees.round()}°",
            onChanged: (val) {
              setState(() => currentDegrees = val);
              widget.onRotationChanged(val * math.pi / 180);
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _quickRotateBtn("-45°", -45),
              _quickRotateBtn("0°", 0),
              _quickRotateBtn("+45°", 45),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Selesai"),
        ),
      ],
    );
  }

  Widget _quickRotateBtn(String label, double delta) {
    return OutlinedButton(
      onPressed: () {
        if (delta == 0) {
          setState(() => currentDegrees = 0);
          widget.onRotationChanged(0);
        } else {
          double newVal = (currentDegrees + delta) % 360;
          if (newVal < 0) newVal += 360;
          setState(() => currentDegrees = newVal);
          widget.onRotationChanged(newVal * math.pi / 180);
        }
      },
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
