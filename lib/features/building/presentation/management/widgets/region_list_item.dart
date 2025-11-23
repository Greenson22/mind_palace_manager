import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class RegionListItem extends StatelessWidget {
  final Directory regionDir;
  final Future<Map<String, dynamic>> iconDataFuture;
  final Function(String) onAction;
  final VoidCallback onTap;

  const RegionListItem({
    super.key,
    required this.regionDir,
    required this.iconDataFuture,
    required this.onAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<Map<String, dynamic>>(
        future: iconDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildContainer(
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final type = snapshot.data?['type'];
          final data = snapshot.data?['data'];
          final file = snapshot.data?['file'] as File?;

          if (type == 'text' && data != null) {
            return _buildContainer(
              Text(
                data.toString(),
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (type == 'image' && file != null) {
            return _buildContainer(null, image: file);
          }
          return _buildContainer(const Icon(Icons.public));
        },
      ),
      title: Text(
        p.basename(regionDir.path),
        style: const TextStyle(fontSize: 18),
      ),
      subtitle: Text(regionDir.path, style: const TextStyle(fontSize: 10)),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: onAction,
        itemBuilder: (c) => [
          const PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility),
                SizedBox(width: 8),
                Text('Masuk'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.orange),
                SizedBox(width: 8),
                Text('Ubah Info'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Hapus', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildContainer(Widget? child, {File? image}) {
    double size = 40.0;
    final shape = AppSettings.listIconShape;

    if (shape == 'Kotak') {
      return Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: image == null ? Colors.grey.shade200 : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: image != null
            ? Image.file(image, fit: BoxFit.cover)
            : Center(child: child),
      );
    } else if (shape == 'Tidak Ada (Tanpa Latar)') {
      return SizedBox(
        width: size,
        height: size,
        child: image != null
            ? Image.file(image, fit: BoxFit.contain)
            : Center(child: child),
      );
    }
    // Default Bulat
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: image != null ? FileImage(image) : null,
      child: image == null ? child : null,
    );
  }
}
