// lib/features/settings/widgets/settings_helpers.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_settings.dart'; // Digunakan untuk AppSettings.listIconShape

// --- CATATAN: Class ImageSourceInfo dan BuildingInfo telah dipindahkan
// ke wallpaper_image_loader.dart untuk menghindari konflik/duplikasi. ---

Widget buildSectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 8),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    ),
  );
}

Widget buildSettingsCard(List<Widget> children) {
  return Card(
    elevation: 2,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );
}

Widget buildDropdown({
  required BuildContext context,
  required String value,
  required Function(String?) onChanged,
}) {
  return DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: value,
      isDense: true,
      icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20),
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w500,
      ),
      onChanged: onChanged,
      items: ['Bulat', 'Kotak', 'Tidak Ada (Tanpa Latar)']
          .map(
            (val) => DropdownMenuItem(
              value: val,
              child: Text(
                val == 'Tidak Ada (Tanpa Latar)' ? 'Tanpa Latar' : val,
              ),
            ),
          )
          .toList(),
    ),
  );
}

Widget buildBoxFitDropdown({
  required BuildContext context,
  required String value,
  required Function(String?) onChanged,
}) {
  final List<Map<String, String>> fitOptions = [
    {'value': 'cover', 'label': 'Full Screen (Cover)'},
    {'value': 'contain', 'label': 'Show All (Contain)'},
    {'value': 'fill', 'label': 'Stretch (Fill)'},
    {'value': 'none', 'label': 'Original Size'},
  ];

  return DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: value,
      isDense: true,
      icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20),
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w500,
      ),
      onChanged: onChanged,
      items: fitOptions.map((opt) {
        return DropdownMenuItem(
          value: opt['value'],
          child: Text(opt['label']!),
        );
      }).toList(),
    ),
  );
}

Widget buildSliderTile({
  required IconData icon,
  required Color color,
  required String title,
  required double value,
  required double min,
  required double max,
  required int divisions,
  required Function(double) onChanged,
}) {
  return Column(
    children: [
      ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ),
    ],
  );
}

Widget buildColorCircle(Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    ),
  );
}

String getThemeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 'Mengikuti Sistem';
    case ThemeMode.light:
      return 'Mode Terang';
    case ThemeMode.dark:
      return 'Mode Gelap';
  }
}

String getWallpaperModeLabel(String mode, String slideshowName) {
  switch (mode) {
    case 'static':
      return 'Wallpaper Statis diatur';
    case 'slideshow':
      return 'Slideshow Aktif: $slideshowName';
    case 'solid':
      return 'Warna Solid Aktif';
    case 'gradient':
      return 'Gradient Aktif';
    case 'default':
    default:
      return 'Menggunakan latar default';
  }
}
