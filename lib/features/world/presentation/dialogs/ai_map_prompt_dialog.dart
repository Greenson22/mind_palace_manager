// lib/features/world/presentation/dialogs/ai_map_prompt_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AiMapPromptDialog extends StatefulWidget {
  const AiMapPromptDialog({super.key});

  @override
  State<AiMapPromptDialog> createState() => _AiMapPromptDialogState();
}

class _AiMapPromptDialogState extends State<AiMapPromptDialog> {
  // --- State Variables ---
  String _selectedShape = 'Massive Continent';
  String _selectedTheme = 'Huge and Complex';
  String _selectedDetail = 'Extensive mountain ranges';

  // Controllers untuk input manual (Custom)
  final TextEditingController _customShapeCtrl = TextEditingController();
  final TextEditingController _customThemeCtrl = TextEditingController();
  final TextEditingController _customDetailCtrl = TextEditingController();

  String _generatedPrompt = "";

  // --- DATA OPTIONS (DAFTAR PILIHAN WILAYAH) ---

  // 1. Bentuk Wilayah (Shapes)
  final List<String> _shapes = [
    'AI yang Tentukan',
    'Isi Sendiri (Custom)',
    'Massive Continent',
    'Archipelago (Kepulauan)',
    'Ring-shaped Island (Atoll)',
    'Crescent Moon Shape',
    'Dragon-shaped Landmass',
    'Skull-shaped Island',
    'Heart-shaped Island',
    'Spiral Landmass',
    'Star-shaped Island',
    'Twin Islands (Gemini)',
    'Fractured/Broken Lands',
    'Long Serpent Shape',
    'Giant Turtle Shell',
    'Floating Sky Island',
    'Perfect Circle',
    'Triangle Delta',
    'Yin-Yang Shape',
    'Labyrinth/Maze Shape',
    'Hand/Palm Shape',
    'Sword Shape',
  ];

  // 2. Tema / Medan (Themes)
  final List<String> _themes = [
    'AI yang Tentukan',
    'Isi Sendiri (Custom)',
    'Huge and Complex',
    'Volcanic and Jagged',
    'Frozen and Icy',
    'Lush Green Jungle',
    'Golden Desert Sands',
    'Crystal Crystalline',
    'Dark Corrupted Land',
    'Autumn/Orange Forest',
    'Mystical Purple Fog',
    'Steampunk Industrial',
    'Cyberpunk Neon',
    'Prehistoric/Primal',
    'Candy/Sweet Land',
    'Underwater Coral',
    'Mechanical/Metal',
    'Papercraft/Origami',
    'Ink Map Style',
    'Retro Pixel Art',
    'Floating Rocks',
    'Hollow Earth',
  ];

  // 3. Detail Fitur (Features)
  final List<String> _details = [
    'AI yang Tentukan',
    'Isi Sendiri (Custom)',
    'Extensive mountain ranges',
    'Giant central crater',
    'Glowing blue rivers',
    'Golden flowing lava',
    'Massive World Tree',
    'Ancient stone ruins',
    'Futuristic dome cities',
    'Deep canyons and rifts',
    'Floating crystal spires',
    'Dense cloud forest',
    'Giant animal skeletons',
    'Railroad networks',
    'Wall/Fortress perimeter',
    'Giant statues',
    'Whirlpools on coast',
    'Crater lakes',
    'Magic rune patterns',
    'Industrial factories',
    'Bioluminescent plants',
    'Scattered obelisks',
  ];

  @override
  void initState() {
    super.initState();
    _generatePrompt();
  }

  @override
  void dispose() {
    _customShapeCtrl.dispose();
    _customThemeCtrl.dispose();
    _customDetailCtrl.dispose();
    super.dispose();
  }

  // --- LOGIKA PENYUSUNAN PROMPT ---
  void _generatePrompt() {
    setState(() {
      // 1. SHAPE
      String shapeVal = _selectedShape;
      if (_selectedShape == 'Isi Sendiri (Custom)') {
        shapeVal = _customShapeCtrl.text.trim().isEmpty
            ? "unique landmass"
            : _customShapeCtrl.text.trim();
      } else if (_selectedShape == 'AI yang Tentukan') {
        shapeVal = "imaginative and distinct landmass shape";
      }

      // 2. THEME
      String themeVal = _selectedTheme;
      if (_selectedTheme == 'Isi Sendiri (Custom)') {
        themeVal = _customThemeCtrl.text.trim().isEmpty
            ? "diverse terrain"
            : _customThemeCtrl.text.trim();
      } else if (_selectedTheme == 'AI yang Tentukan') {
        themeVal = "rich and atmospheric terrain";
      }

      // 3. DETAILS
      String detailVal = _selectedDetail;
      if (_selectedDetail == 'Isi Sendiri (Custom)') {
        detailVal = _customDetailCtrl.text.trim().isEmpty
            ? "geographical landmarks"
            : _customDetailCtrl.text.trim();
      } else if (_selectedDetail == 'AI yang Tentukan') {
        detailVal = "distinctive landmarks and features";
      }

      // Template Prompt (Khusus Wilayah/Region)
      _generatedPrompt =
          "Direct top-down aerial map view of a $shapeVal dominating the entire frame. "
          "The landmass is $themeVal, featuring $detailVal cutting across vast dense green forests and wide plains. "
          "The entire coastline is bordered by a continuous sandy beige beach with a thick, prominent white wave foam border against the deep blue ocean background. "
          "The style is a 2D hand-painted game asset, with smooth digital textures, soft even lighting, vibrant earthy colors, and miniature-scale trees scattered across the vast landscape to emphasize the immense scale. "
          "No clouds, clean edges, high resolution. --no isometric view, tilted angle, 3d render, low poly, realism, photorealistic, perspective distortion, blurry, grainy, simple geography, small island, dark shadows";
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPrompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Prompt Wilayah disalin! Paste ke Midjourney/Dall-E."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Penyesuaian Tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color containerBg = isDark
        ? Colors.grey.shade900
        : Colors.grey.shade100;
    final Color containerBorder = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final Color previewTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade800;

    // Warna Aksen Ungu (Khas Region/AI)
    final Color accentBg = isDark
        ? Colors.purple.shade900.withOpacity(0.3)
        : Colors.purple.shade50;
    final Color accentBorder = isDark
        ? Colors.purple.shade700
        : Colors.purple.shade100;
    final Color accentText = isDark ? Colors.purple.shade200 : Colors.purple;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.psychology, color: Colors.purple),
          SizedBox(width: 8),
          Text("AI Region Prompt"),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentBorder),
                ),
                child: Text(
                  "Generator ini dirancang untuk membuat peta skala WILAYAH/BENUA (Region).",
                  style: TextStyle(fontSize: 12, color: accentText),
                ),
              ),
              const SizedBox(height: 16),

              // --- INPUT SECTIONS ---
              _buildSection(
                label: "Bentuk Wilayah (Shape)",
                value: _selectedShape,
                items: _shapes,
                onChanged: (val) {
                  setState(() => _selectedShape = val!);
                  _generatePrompt();
                },
                customController: _customShapeCtrl,
                customHint: "Cth: Giant Bird Shape",
              ),

              _buildSection(
                label: "Tema / Medan (Terrain)",
                value: _selectedTheme,
                items: _themes,
                onChanged: (val) {
                  setState(() => _selectedTheme = val!);
                  _generatePrompt();
                },
                customController: _customThemeCtrl,
                customHint: "Cth: Toxic Wasteland",
              ),

              _buildSection(
                label: "Detail Fitur Geografis",
                value: _selectedDetail,
                items: _details,
                onChanged: (val) {
                  setState(() => _selectedDetail = val!);
                  _generatePrompt();
                },
                customController: _customDetailCtrl,
                customHint: "Cth: Massive crater lake",
              ),

              const Divider(height: 32),

              // --- PREVIEW SECTION ---
              const Row(
                children: [
                  Icon(
                    Icons.text_snippet_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Preview Prompt Final:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: containerBorder),
                ),
                child: SelectableText(
                  _generatedPrompt,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                    color: previewTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Tutup"),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text("Salin Prompt"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          onPressed: _copyToClipboard,
        ),
      ],
    );
  }

  // Helper Widget
  Widget _buildSection({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required TextEditingController customController,
    required String customHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
        if (value == 'Isi Sendiri (Custom)')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextField(
              controller: customController,
              decoration: InputDecoration(
                hintText: customHint,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => _generatePrompt(),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
