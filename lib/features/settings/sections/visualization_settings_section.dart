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

  // --- Parameter Visibilitas Objek ---
  final bool defaultShowObjectIcons;
  final double objectIconOpacity;
  final bool interactableWhenHidden;

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
    required this.defaultShowObjectIcons,
    required this.objectIconOpacity,
    required this.interactableWhenHidden,
    required this.setStateCallback,
  });

  @override
  State<VisualizationSettingsSection> createState() =>
      _VisualizationSettingsSectionState();
}

class _VisualizationSettingsSectionState
    extends State<VisualizationSettingsSection> {
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

  late bool _defaultShowObjectIcons;
  late double _objectIconOpacity;
  late bool _interactableWhenHidden;

  // --- State Navigasi (BARU) ---
  late bool _showNavigationArrows;
  late double _navigationArrowOpacity;
  late double _navigationArrowScale;
  late Color _navigationArrowColor;

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

    _defaultShowObjectIcons = widget.defaultShowObjectIcons;
    _objectIconOpacity = widget.objectIconOpacity;
    _interactableWhenHidden = widget.interactableWhenHidden;

    // Init Navigasi
    _showNavigationArrows = AppSettings.showNavigationArrows;
    _navigationArrowOpacity = AppSettings.navigationArrowOpacity;
    _navigationArrowScale = AppSettings.navigationArrowScale;
    _navigationArrowColor = Color(AppSettings.navigationArrowColor);
  }

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
    if (oldWidget.defaultShowObjectIcons != widget.defaultShowObjectIcons)
      _defaultShowObjectIcons = widget.defaultShowObjectIcons;
    if (oldWidget.objectIconOpacity != widget.objectIconOpacity)
      _objectIconOpacity = widget.objectIconOpacity;
    if (oldWidget.interactableWhenHidden != widget.interactableWhenHidden)
      _interactableWhenHidden = widget.interactableWhenHidden;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Visualisasi Peta ---
        buildSectionHeader(context, 'Visualisasi Peta'),
        buildSettingsCard([
          ListTile(
            leading: const Icon(Icons.location_city, color: Colors.orange),
            title: const Text('Pin Bangunan (Peta Distrik)'),
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
            leading: const Icon(Icons.map, color: Colors.green),
            title: const Text('Pin Wilayah (Peta Dunia)'),
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

        // --- Visualisasi Objek Dalam Ruangan ---
        buildSectionHeader(context, 'Visualisasi Objek (Ruangan)'),
        buildSettingsCard([
          SwitchListTile(
            secondary: const Icon(Icons.visibility, color: Colors.teal),
            title: const Text('Tampilkan Ikon Secara Default'),
            subtitle: const Text('Status awal saat membuka ruangan'),
            value: _defaultShowObjectIcons,
            onChanged: (bool value) async {
              await AppSettings.saveDefaultShowObjectIcons(value);
              widget.setStateCallback(() => _defaultShowObjectIcons = value);
            },
          ),
          const Divider(indent: 56),
          buildSliderTile(
            icon: Icons.opacity,
            color: Colors.teal,
            title: 'Transparansi Ikon',
            value: _objectIconOpacity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (val) async {
              widget.setStateCallback(() => _objectIconOpacity = val);
              await AppSettings.saveObjectIconOpacity(val);
            },
          ),
          const Divider(indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.touch_app, color: Colors.teal),
            title: const Text('Interaksi Saat Tersembunyi'),
            subtitle: const Text(
              'Izinkan klik objek meski ikon disembunyikan/transparan',
            ),
            value: _interactableWhenHidden,
            onChanged: (bool value) async {
              await AppSettings.saveInteractableWhenHidden(value);
              widget.setStateCallback(() => _interactableWhenHidden = value);
            },
          ),
        ]),

        // --- VISUALISASI NAVIGASI (BARU) ---
        const SizedBox(height: 24),
        buildSectionHeader(context, 'Visualisasi Navigasi (Panah/Pintu)'),
        buildSettingsCard([
          SwitchListTile(
            secondary: const Icon(Icons.navigation, color: Colors.lightBlue),
            title: const Text('Tampilkan Panah Navigasi'),
            value: _showNavigationArrows,
            onChanged: (bool value) async {
              await AppSettings.saveShowNavigationArrows(value);
              widget.setStateCallback(() => _showNavigationArrows = value);
            },
          ),
          if (_showNavigationArrows) ...[
            const Divider(indent: 56),
            buildSliderTile(
              icon: Icons.opacity,
              color: Colors.lightBlue,
              title: 'Transparansi Panah',
              value: _navigationArrowOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (val) async {
                widget.setStateCallback(() => _navigationArrowOpacity = val);
                await AppSettings.saveNavigationArrowOpacity(val);
              },
            ),
            const Divider(indent: 56),
            buildSliderTile(
              icon: Icons.zoom_out_map,
              color: Colors.lightBlue,
              title: 'Ukuran Panah',
              value: _navigationArrowScale,
              min: 0.5,
              max: 3.0,
              divisions: 25,
              onChanged: (val) async {
                widget.setStateCallback(() => _navigationArrowScale = val);
                await AppSettings.saveNavigationArrowScale(val);
              },
            ),
            const Divider(indent: 56),
            ListTile(
              leading: const Icon(Icons.color_lens, color: Colors.lightBlue),
              title: const Text('Warna Panah'),
              trailing: buildColorCircle(
                _navigationArrowColor,
                () => showColorPickerDialog(
                  context,
                  'Pilih Warna Panah',
                  _navigationArrowColor,
                  (c) async {
                    widget.setStateCallback(() => _navigationArrowColor = c);
                    await AppSettings.saveNavigationArrowColor(c.value);
                  },
                ),
              ),
            ),
          ],
        ]),

        const SizedBox(height: 24),

        // --- Detail & Outline ---
        buildSectionHeader(context, 'Detail Tampilan'),
        buildSettingsCard([
          SwitchListTile(
            secondary: const Icon(
              Icons.check_circle_outline,
              color: Colors.blueGrey,
            ),
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
            secondary: const Icon(Icons.text_fields, color: Colors.blueGrey),
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

        // --- Lainnya ---
        buildSectionHeader(context, 'Lainnya'),
        buildSettingsCard([
          ListTile(
            leading: const Icon(
              Icons.format_list_bulleted,
              color: Colors.purple,
            ),
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
