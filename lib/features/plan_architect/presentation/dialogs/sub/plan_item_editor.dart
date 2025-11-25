import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/building/presentation/management/logic/district_building_logic.dart';

class PlanItemEditorDialog extends StatefulWidget {
  final PlanController controller;
  final Directory? buildingDirectory;

  const PlanItemEditorDialog({
    super.key,
    required this.controller,
    this.buildingDirectory,
  });

  @override
  State<PlanItemEditorDialog> createState() => _PlanItemEditorDialogState();
}

class _PlanItemEditorDialogState extends State<PlanItemEditorDialog> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  TextEditingController? lengthCtrl;

  String? newRefImage;
  String? selectedNavFloorId;
  late Map<String, dynamic> data;

  bool isPath = false;
  bool isLabel = false;
  bool isWall = false;
  bool canNavigate = false;

  @override
  void initState() {
    super.initState();
    final itemData = widget.controller.getSelectedItemData();
    if (itemData == null) {
      // Tutup dialog jika data tidak ditemukan (seharusnya tidak terjadi)
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.pop(context),
      );
      return;
    }
    data = itemData;

    titleCtrl = TextEditingController(text: data['title']);
    descCtrl = TextEditingController(text: data['desc']);
    newRefImage = data['refImage'];
    selectedNavFloorId = data['nav'];

    isPath = data['isPath'] ?? false;
    isLabel = data['type'] == 'Label';
    isWall = data['title'] == 'Tembok';
    canNavigate = data['type'] == 'Interior' || data['type'] == 'Struktur';

    if (isWall) {
      try {
        final wall = widget.controller.walls.firstWhere(
          (w) => w.id == data['id'],
        );
        final lenPx = (wall.end - wall.start).distance;
        final lenM = (lenPx / 40.0).toStringAsFixed(2);
        lengthCtrl = TextEditingController(text: lenM);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    lengthCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${data['type']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLabel && !isPath) _buildImagePicker(context),

            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: isLabel ? 'Isi Teks' : 'Nama',
              ),
              enabled: isPath || isLabel || !isWall,
            ),
            const SizedBox(height: 8),
            if (!isLabel)
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            if (isWall && lengthCtrl != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: lengthCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Panjang (Meter)',
                  suffixText: 'm',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            _buildNavDropdown(),

            if (isPath) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.bookmark_add),
                label: const Text("Simpan ke Pustaka Saya"),
                onPressed: () {
                  widget.controller.updateSelectedAttribute(
                    desc: descCtrl.text,
                    name: titleCtrl.text,
                  );
                  widget.controller.saveCurrentSelectionToLibrary();
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.controller.deleteSelected();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Hapus'),
        ),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Simpan')),
      ],
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    ImageProvider? imageProvider;
    if (newRefImage != null) {
      String displayPath = newRefImage!;
      if (widget.buildingDirectory != null && !p.isAbsolute(displayPath)) {
        displayPath = p.join(widget.buildingDirectory!.path, displayPath);
      }
      final file = File(displayPath);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Wujud Asli / Referensi:",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.image,
            );
            if (result != null && result.files.single.path != null) {
              setState(() {
                newRefImage = result.files.single.path;
              });
            }
          },
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
              image: imageProvider != null
                  ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                  : null,
            ),
            child: imageProvider == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey),
                      Text("Tambah Foto", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                : null,
          ),
        ),
        if (newRefImage != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              label: const Text(
                "Hapus Foto",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              onPressed: () => setState(() => newRefImage = null),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNavDropdown() {
    if (!canNavigate || widget.buildingDirectory == null)
      return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DistrictBuildingLogic(
        widget.buildingDirectory!.parent,
      ).getBuildingPlans(widget.buildingDirectory!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              "Memuat daftar denah...",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        final plans = snapshot.data!;
        final List<DropdownMenuItem<String?>> items = [
          const DropdownMenuItem(value: null, child: Text("Tidak Ada (Diam)")),
        ];

        items.addAll(
          plans.map(
            (p) => DropdownMenuItem(
              value: p['id'],
              child: Text("Pindah ke: ${p['name']}"),
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Aksi Saat Ditekan (View Mode):",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              DropdownButton<String?>(
                value: selectedNavFloorId,
                isExpanded: true,
                items: items,
                onChanged: (val) => setState(() => selectedNavFloorId = val),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    // Logic copy gambar
    String? finalRefImage = newRefImage;
    if (newRefImage != null && widget.buildingDirectory != null) {
      if (p.isAbsolute(newRefImage!)) {
        try {
          final ext = p.extension(newRefImage!);
          final fileName =
              'ref_img_${DateTime.now().millisecondsSinceEpoch}$ext';
          final destPath = p.join(widget.buildingDirectory!.path, fileName);
          await File(newRefImage!).copy(destPath);
          finalRefImage = fileName;
        } catch (e) {
          debugPrint("Gagal copy ref image: $e");
        }
      }
    }

    widget.controller.updateSelectedAttribute(
      desc: descCtrl.text,
      name: titleCtrl.text,
      navTarget: selectedNavFloorId,
      referenceImage: finalRefImage,
    );

    if (isWall && lengthCtrl != null) {
      final newLen = double.tryParse(lengthCtrl!.text.replaceAll(',', '.'));
      if (newLen != null && newLen > 0) {
        widget.controller.updateSelectedWallLength(newLen);
      }
    }
    Navigator.pop(context);
  }
}
