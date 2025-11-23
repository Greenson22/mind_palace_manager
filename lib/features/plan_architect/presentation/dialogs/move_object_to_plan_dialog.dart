import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/features/building/presentation/management/logic/district_building_logic.dart';

class MoveObjectToPlanDialog extends StatefulWidget {
  final Directory buildingDirectory;
  final String currentPlanFilename; // Agar tidak memindahkan ke diri sendiri
  final Map<String, List<Map<String, dynamic>>> itemsToMove; // Data mentah

  const MoveObjectToPlanDialog({
    super.key,
    required this.buildingDirectory,
    required this.currentPlanFilename,
    required this.itemsToMove,
  });

  @override
  State<MoveObjectToPlanDialog> createState() => _MoveObjectToPlanDialogState();
}

class _MoveObjectToPlanDialogState extends State<MoveObjectToPlanDialog> {
  List<Map<String, dynamic>> _availablePlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTargetPlans();
  }

  Future<void> _loadTargetPlans() async {
    try {
      // Gunakan logic yang sudah ada untuk ambil daftar plan
      final logic = DistrictBuildingLogic(widget.buildingDirectory.parent);
      final plans = await logic.getBuildingPlans(widget.buildingDirectory);

      setState(() {
        // Filter: Jangan tampilkan denah yang sedang dibuka saat ini
        _availablePlans = plans
            .where((plan) => plan['filename'] != widget.currentPlanFilename)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _transferItems(String targetFilename) async {
    final targetFile = File(
      p.join(widget.buildingDirectory.path, targetFilename),
    );

    if (!await targetFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("File denah tujuan tidak ditemukan/rusak."),
        ),
      );
      return;
    }

    try {
      // 1. Baca File Target
      final content = await targetFile.readAsString();
      final data = jsonDecode(content); // Map<String, dynamic>

      // 2. Ambil data lantai utama (index 0) di file target
      // Struktur: data['floors'] -> List -> Index 0
      List<dynamic> floors = data['floors'] ?? [];
      if (floors.isEmpty)
        throw Exception("Denah tujuan korup (tidak ada lantai).");

      Map<String, dynamic> targetFloor = floors[0];

      // 3. Suntikkan item ke list yang sesuai
      widget.itemsToMove.forEach((category, items) {
        // category: 'objects', 'walls', 'portals', dll
        if (targetFloor[category] == null) {
          targetFloor[category] = [];
        }

        // Tambahkan item ke list tujuan
        (targetFloor[category] as List).addAll(items);
      });

      // 4. Simpan kembali ke file
      floors[0] = targetFloor;
      data['floors'] = floors;
      await targetFile.writeAsString(jsonEncode(data));

      // 5. Sukses -> Tutup dialog dengan nilai true
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Gagal transfer: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memindahkan: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = 0;
    widget.itemsToMove.values.forEach((l) => totalItems += l.length);

    return AlertDialog(
      title: const Text("Pindah ke Denah Lain"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Memindahkan $totalItems item terpilih ke:"),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_availablePlans.isEmpty)
              const Center(
                child: Text(
                  "Tidak ada denah lain.\nBuat denah/lantai baru di menu utama.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availablePlans.length,
                  itemBuilder: (context, index) {
                    final plan = _availablePlans[index];
                    return ListTile(
                      leading: Icon(
                        IconData(
                          plan['icon'] ?? Icons.map.codePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Colors.indigo,
                      ),
                      title: Text(plan['name']),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _transferItems(plan['filename']),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Batal"),
        ),
      ],
    );
  }
}
