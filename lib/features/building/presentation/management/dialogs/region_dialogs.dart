import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class RegionDialogs {
  static Future<String?> showCreateDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Buat Wilayah Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama Wilayah'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(c, controller.text.trim());
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  // Return Map: {name, iconType, iconData, imagePath}
  static Future<Map<String, dynamic>?> showEditDialog(
    BuildContext context,
    String currentName,
    String currentType,
    dynamic currentData,
    String? currentMapImageName, // Untuk opsi pakai peta
  ) async {
    final nameController = TextEditingController(text: currentName);
    final iconTextController = TextEditingController();

    String iconType = 'Default';
    String? iconImagePath;

    if (currentType == 'text') {
      iconType = 'Teks';
      iconTextController.text = currentData ?? '';
    } else if (currentType == 'image') {
      iconType = 'Gambar';
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String imageStatus = '...';
          if (iconType == 'Gambar') {
            if (iconImagePath != null) {
              if (iconImagePath!.startsWith('MAP_IMAGE_REF:')) {
                imageStatus = 'Pakai Peta Wilayah';
              } else {
                imageStatus = 'File Baru Dipilih';
              }
            } else if (currentType == 'image') {
              imageStatus = 'Gambar Saat Ini';
            } else {
              imageStatus = 'Belum ada gambar';
            }
          }

          return AlertDialog(
            title: const Text('Ubah Info Wilayah'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Wilayah',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: iconType,
                    isExpanded: true,
                    items: ['Default', 'Teks', 'Gambar']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => iconType = v!),
                  ),
                  if (iconType == 'Teks')
                    TextField(
                      controller: iconTextController,
                      decoration: const InputDecoration(
                        labelText: 'Karakter (cth: 🏠)',
                      ),
                      maxLength: 2,
                    ),
                  if (iconType == 'Gambar')
                    Column(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih File Gambar'),
                          onPressed: () async {
                            var res = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (res != null) {
                              setState(
                                () => iconImagePath = res.files.single.path,
                              );
                            }
                          },
                        ),
                        if (currentMapImageName != null)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.map),
                            label: const Text('Gunakan Peta Wilayah'),
                            onPressed: () {
                              setState(
                                () => iconImagePath =
                                    'MAP_IMAGE_REF:$currentMapImageName',
                              );
                            },
                          ),
                        Text(
                          imageStatus,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Simpan'),
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    dynamic finalData;
                    String? finalType;

                    if (iconType == 'Teks') {
                      finalType = 'text';
                      finalData = iconTextController.text;
                    } else if (iconType == 'Gambar') {
                      finalType = 'image';
                      // Data gambar dihandle di logic, kita kirim pathnya saja
                      finalData =
                          currentData; // Kirim data lama sebagai fallback
                    }

                    Navigator.pop(context, {
                      'name': nameController.text.trim(),
                      'iconType': finalType,
                      'iconData': finalData,
                      'imagePath': iconImagePath,
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
