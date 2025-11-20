import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class MoveDistrictDialog extends StatefulWidget {
  final Directory currentRegionDir;

  const MoveDistrictDialog({super.key, required this.currentRegionDir});

  @override
  State<MoveDistrictDialog> createState() => _MoveDistrictDialogState();
}

class _MoveDistrictDialogState extends State<MoveDistrictDialog> {
  List<Directory> _availableRegions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    if (AppSettings.baseBuildingsPath == null) return;

    setState(() => _isLoading = true);
    try {
      final rootDir = Directory(AppSettings.baseBuildingsPath!);
      if (await rootDir.exists()) {
        final entities = await rootDir.list().toList();
        setState(() {
          _availableRegions = entities.whereType<Directory>().where((d) {
            final name = p.basename(d.path);
            // Filter:
            // 1. Bukan folder sistem (awalan _)
            // 2. Bukan wilayah asal saat ini
            return !name.startsWith('_') &&
                d.path != widget.currentRegionDir.path;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading regions: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pindahkan Distrik ke...'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Tinggi tetap agar list bisa di-scroll
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _availableRegions.isEmpty
            ? const Center(child: Text('Tidak ada wilayah lain.'))
            : ListView.separated(
                itemCount: _availableRegions.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final region = _availableRegions[index];
                  return ListTile(
                    leading: const Icon(Icons.public, color: Colors.blue),
                    title: Text(
                      p.basename(region.path),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.login),
                    onTap: () {
                      // Kembalikan Directory wilayah yang dipilih
                      Navigator.pop(context, region);
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
