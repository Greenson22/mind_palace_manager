import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class BuildingManagementDialogs {
  // Return Map: {name, type, iconType, iconData, imagePath}
  static Future<Map<String, dynamic>?> showCreateDialog(
    BuildContext context,
  ) async {
    final nameController = TextEditingController();
    final iconTextController = TextEditingController();
    String selectedType = 'standard';
    String iconType = 'Default';
    String? iconImagePath;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Buat Bangunan Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama Bangunan',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Tipe Bangunan:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<String>(
                      title: const Text("Biasa (Ruangan)"),
                      value: 'standard',
                      groupValue: selectedType,
                      onChanged: (val) => setState(() => selectedType = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text("Denah (Arsitek)"),
                      value: 'plan',
                      groupValue: selectedType,
                      onChanged: (val) => setState(() => selectedType = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    const Text(
                      "Ikon Tampilan:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: iconType,
                      isExpanded: true,
                      items: ['Default', 'Teks', 'Gambar']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => iconType = v!),
                    ),
                    if (iconType == 'Teks')
                      TextField(
                        controller: iconTextController,
                        decoration: const InputDecoration(
                          hintText: 'Karakter (1-2 huruf)',
                        ),
                        maxLength: 2,
                      ),
                    if (iconType == 'Gambar')
                      Column(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Pilih Gambar'),
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker
                                  .platform
                                  .pickFiles(type: FileType.image);
                              if (result != null)
                                setState(
                                  () =>
                                      iconImagePath = result.files.single.path,
                                );
                            },
                          ),
                          if (iconImagePath != null)
                            Text(
                              'File: ${p.basename(iconImagePath!)}',
                              style: const TextStyle(fontSize: 12),
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
                  child: const Text('Buat'),
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      dynamic finalIconData;
                      if (iconType == 'Teks')
                        finalIconData = iconTextController.text;

                      Navigator.pop(context, {
                        'name': nameController.text.trim(),
                        'type': selectedType,
                        'iconType': iconType == 'Default'
                            ? null
                            : (iconType == 'Gambar' ? 'image' : 'text'),
                        'iconData': finalIconData,
                        'imagePath': iconImagePath,
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<Map<String, dynamic>?> showEditDialog(
    BuildContext context,
    String currentName,
    String currentIconType,
    dynamic currentIconData,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final iconTextController = TextEditingController();
    String iconType = 'Default';
    String? iconImagePath;

    if (currentIconType == 'text') {
      iconType = 'Teks';
      iconTextController.text = currentIconData ?? '';
    } else if (currentIconType == 'image') {
      iconType = 'Gambar';
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ubah Info Bangunan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Bangunan',
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
                      decoration: const InputDecoration(labelText: 'Karakter'),
                      maxLength: 2,
                    ),
                  if (iconType == 'Gambar')
                    Column(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih Gambar Baru'),
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(type: FileType.image);
                            if (result != null)
                              setState(
                                () => iconImagePath = result.files.single.path,
                              );
                          },
                        ),
                        Text(
                          iconImagePath != null
                              ? 'Baru: ${p.basename(iconImagePath!)}'
                              : (currentIconType == 'image'
                                    ? 'Gambar saat ini tersimpan'
                                    : ''),
                          style: const TextStyle(fontSize: 12),
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
                    dynamic finalIconData;
                    if (iconType == 'Teks')
                      finalIconData = iconTextController.text;

                    Navigator.pop(context, {
                      'name': nameController.text.trim(),
                      'iconType': iconType == 'Default'
                          ? null
                          : (iconType == 'Gambar' ? 'image' : 'text'),
                      'iconData': finalIconData,
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
