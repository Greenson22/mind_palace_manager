// lib/features/settings/sections/visualization_settings_section.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/settings/widgets/settings_helpers.dart';
import 'package:mind_palace_manager/features/settings/dialogs/color_picker_dialog.dart';
import 'package:mind_palace_manager/features/settings/about_page.dart';

class VisualizationSettingsSection extends StatefulWidget {
  final String currentMapPinShape;
  final String currentRegionPinShape;
  final bool currentShowRegionOutline;
  final double currentRegionOutlineWidth;
  final double currentRegionShapeStrokeWidth;
  final bool currentShowRegionDistrictNames;
  final Color currentRegionPinColor;
  final Color currentRegionOutlineColor;
  final Color currentRegionNameColor;
  final String currentListIconShape;

  final Function(VoidCallback fn) setStateCallback;

  const VisualizationSettingsSection({
    super.key,
    required this.currentMapPinShape,
    required this.currentRegionPinShape,
    required this.currentShowRegionOutline,
    required this.currentRegionOutlineWidth,
    required this.currentRegionShapeStrokeWidth,
    required this.currentShowRegionDistrictNames,
    required this.currentRegionPinColor,
    required this.currentRegionOutlineColor,
    required this.currentRegionNameColor,
    required this.currentListIconShape,
    required this.setStateCallback,
  });

  @override
  State<VisualizationSettingsSection> createState() =>
      _VisualizationSettingsSectionState();
}

class _VisualizationSettingsSectionState
    extends State<VisualizationSettingsSection> {
  // State lokal untuk diubah oleh UI (akan disinkronkan ke parent di onChanged)
  late String _mapPinShape;
  late String _regionPinShape;
  late bool _showRegionOutline;
  late double _regionOutlineWidth;
  late double _regionShapeStrokeWidth;
  late bool _showRegionDistrictNames;
  late Color _regionPinColor;
  late Color _regionOutlineColor;
  late Color _regionNameColor;
  late String _listIconShape;

  @override
  void initState() {
    super.initState();
    _mapPinShape = widget.currentMapPinShape;
    _regionPinShape = widget.currentRegionPinShape;
    _showRegionOutline = widget.currentShowRegionOutline;
    _regionOutlineWidth = widget.currentRegionOutlineWidth;
    _regionShapeStrokeWidth = widget.currentRegionShapeStrokeWidth;
    _showRegionDistrictNames = widget.currentShowRegionDistrictNames;
    _regionPinColor = widget.currentRegionPinColor;
    _regionOutlineColor = widget.currentRegionOutlineColor;
    _regionNameColor = widget.currentRegionNameColor;
    _listIconShape = widget.currentListIconShape;
  }

  // Sinkronisasi state lokal dengan widget.currentXyz ketika parent berubah
  @override
  void didUpdateWidget(covariant VisualizationSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMapPinShape != widget.currentMapPinShape)
      _mapPinShape = widget.currentMapPinShape;
    if (oldWidget.currentRegionPinShape != widget.currentRegionPinShape)
      _regionPinShape = widget.currentRegionPinShape;
    if (oldWidget.currentShowRegionOutline != widget.currentShowRegionOutline)
      _showRegionOutline = widget.currentShowRegionOutline;
    if (oldWidget.currentRegionOutlineWidth != widget.currentRegionOutlineWidth)
      _regionOutlineWidth = widget.currentRegionOutlineWidth;
    if (oldWidget.currentRegionShapeStrokeWidth !=
        widget.currentRegionShapeStrokeWidth)
      _regionShapeStrokeWidth = widget.currentRegionShapeStrokeWidth;
    if (oldWidget.currentShowRegionDistrictNames !=
        widget.currentShowRegionDistrictNames)
      _showRegionDistrictNames = widget.currentShowRegionDistrictNames;
    if (oldWidget.currentRegionPinColor != widget.currentRegionPinColor)
      _regionPinColor = widget.currentRegionPinColor;
    if (oldWidget.currentRegionOutlineColor != widget.currentRegionOutlineColor)
      _regionOutlineColor = widget.currentRegionOutlineColor;
    if (oldWidget.currentRegionNameColor != widget.currentRegionNameColor)
      _regionNameColor = widget.currentRegionNameColor;
    if (oldWidget.currentListIconShape != widget.currentListIconShape)
      _listIconShape = widget.currentListIconShape;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 2. Visualisasi Peta (Distrik & Bangunan) ---
        buildSectionHeader(context, 'Visualisasi Peta'),
        buildSettingsCard([
          ListTile(
            leading: Icon(Icons.location_city, color: Colors.orange),
            title: const Text('Pin Bangunan'),
            trailing: buildDropdown(
              context: context,
              value: _mapPinShape,
              onChanged: (val) async {
                if (val != null) {
                  await AppSettings.saveMapPinShape(val);
                  widget.setStateCallback(() => _mapPinShape = val);
                }
              },
            ),
          ),
          const Divider(indent: 56),
          ListTile(
            leading: Icon(Icons.map, color: Colors.green),
            title: const Text('Pin Wilayah (Distrik)'),
            trailing: buildDropdown(
              context: context,
              value: _regionPinShape,
              onChanged: (val) async {
                if (val != null) {
                  await AppSettings.saveRegionPinShape(val);
                  widget.setStateCallback(() => _regionPinShape = val);
                }
              },
            ),
          ),

          if (_regionPinShape != 'Tidak Ada (Tanpa Latar)') ...[
            const Divider(indent: 56),
            buildSliderTile(
              icon: Icons.line_weight,
              color: Colors.green,
              title: 'Ketebalan Pin',
              value: _regionShapeStrokeWidth,
              min: 0.0,
              max: 10.0,
              divisions: 20,
              onChanged: (val) async {
                widget.setStateCallback(() => _regionShapeStrokeWidth = val);
                await AppSettings.saveRegionPinShapeStrokeWidth(val);
              },
            ),
            const Divider(indent: 56),
            ListTile(
              leading: const Icon(Icons.color_lens, color: Colors.green),
              title: const Text('Warna Pin'),
              trailing: buildColorCircle(
                _regionPinColor,
                () => showColorPickerDialog(
                  context,
                  'Pilih Warna Pin',
                  _regionPinColor,
                  (c) async {
                    widget.setStateCallback(() => _regionPinColor = c);
                    await AppSettings.saveRegionPinColor(c.value);
                  },
                ),
              ),
            ),
          ],
        ]),

        const SizedBox(height: 24),

        // --- 3. Detail & Outline ---
        buildSectionHeader(context, 'Detail Tampilan'),
        buildSettingsCard([
          SwitchListTile(
            secondary: Icon(Icons.check_circle_outline, color: Colors.blueGrey),
            title: const Text('Outline Pin Wilayah'),
            value: _showRegionOutline,
            onChanged: (bool value) async {
              await AppSettings.saveShowRegionPinOutline(value);
              widget.setStateCallback(() => _showRegionOutline = value);
            },
          ),
          if (_showRegionOutline) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ketebalan Garis',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Slider(
                          value: _regionOutlineWidth,
                          min: 1.0,
                          max: 6.0,
                          divisions: 10,
                          label: _regionOutlineWidth.toStringAsFixed(1),
                          onChanged: (val) async {
                            widget.setStateCallback(
                              () => _regionOutlineWidth = val,
                            );
                            await AppSettings.saveRegionPinOutlineWidth(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  buildColorCircle(
                    _regionOutlineColor,
                    () => showColorPickerDialog(
                      context,
                      'Warna Outline',
                      _regionOutlineColor,
                      (c) async {
                        widget.setStateCallback(() => _regionOutlineColor = c);
                        await AppSettings.saveRegionOutlineColor(c.value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(indent: 56),
          SwitchListTile(
            secondary: Icon(Icons.text_fields, color: Colors.blueGrey),
            title: const Text('Label Nama Distrik'),
            value: _showRegionDistrictNames,
            onChanged: (bool value) async {
              await AppSettings.saveShowRegionDistrictNames(value);
              widget.setStateCallback(() => _showRegionDistrictNames = value);
            },
          ),
          if (_showRegionDistrictNames)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: const Text('Warna Teks Label'),
              trailing: buildColorCircle(
                _regionNameColor,
                () => showColorPickerDialog(
                  context,
                  'Pilih Warna Teks',
                  _regionNameColor,
                  (c) async {
                    widget.setStateCallback(() => _regionNameColor = c);
                    await AppSettings.saveRegionNameColor(c.value);
                  },
                ),
              ),
            ),
        ]),

        const SizedBox(height: 24),

        // --- 4. Lainnya (Lanjutan) ---
        buildSectionHeader(context, 'Lainnya'),
        buildSettingsCard([
          ListTile(
            leading: Icon(Icons.format_list_bulleted, color: Colors.purple),
            title: const Text('Bentuk Ikon Daftar'),
            trailing: buildDropdown(
              context: context,
              value: _listIconShape,
              onChanged: (val) async {
                if (val != null) {
                  await AppSettings.saveListIconShape(val);
                  widget.setStateCallback(() => _listIconShape = val);
                }
              },
            ),
          ),
          const Divider(indent: 56),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.teal),
            title: const Text('Tentang Aplikasi'),
            subtitle: const Text('Versi & Pengembang'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }
}
