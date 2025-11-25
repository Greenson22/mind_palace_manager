import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';

class PlanLayerSettingsDialog extends StatefulWidget {
  final PlanController controller;
  const PlanLayerSettingsDialog({super.key, required this.controller});

  @override
  State<PlanLayerSettingsDialog> createState() => _PlanLayerSettingsDialogState();
}

class _PlanLayerSettingsDialogState extends State<PlanLayerSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = widget.controller;

    return AlertDialog(
      title: const Text("Atur Layer & Tampilan"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text("Tampilkan Grid"),
              value: controller.showGrid,
              onChanged: (v) {
                controller.toggleGridVisibility();
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text("Tombol Zoom (+/-)"),
              subtitle: const Text("Sembunyikan jika mengganggu"),
              value: controller.showZoomButtons,
              onChanged: (v) {
                controller.toggleZoomButtonsVisibility();
                setState(() {});
              },
            ),
            if (controller.showGrid) ...[
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Ukuran Kotak Grid"),
                ),
              ),
              Slider(
                value: controller.gridSize,
                min: 10.0,
                max: 100.0,
                divisions: 18,
                label: "${controller.gridSize.toInt()}px",
                onChanged: (val) {
                  controller.setGridSize(val);
                  setState(() {});
                },
              ),
            ],
            const Divider(),
            CheckboxListTile(
              title: const Text("Layer Tembok"),
              value: controller.layerWalls,
              onChanged: (v) {
                controller.toggleLayer('walls');
                setState(() {});
              },
            ),
            CheckboxListTile(
              title: const Text("Layer Interior/Objek"),
              value: controller.layerObjects,
              onChanged: (v) {
                controller.toggleLayer('objects');
                setState(() {});
              },
            ),
            CheckboxListTile(
              title: const Text("Layer Label Teks"),
              value: controller.layerLabels,
              onChanged: (v) {
                controller.toggleLayer('labels');
                setState(() {});
              },
            ),
            CheckboxListTile(
              title: const Text("Ukuran Tembok"),
              value: controller.layerDims,
              onChanged: (v) {
                controller.toggleLayer('dims');
                setState(() {});
              },
            ),
            const Divider(),
            const Text(
              "Warna Latar Kanvas",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Colors.white,
                Colors.blue.shade50,
                Colors.grey.shade200,
                const Color(0xFFFFF3E0),
                Colors.black,
                const Color(0xFF121212),
              ].map((c) => InkWell(
                onTap: () {
                  controller.setCanvasColor(c);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    border: Border.all(color: colorScheme.outlineVariant),
                    shape: BoxShape.circle,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Tutup"),
        ),
      ],
    );
  }
}