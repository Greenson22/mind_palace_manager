// lib/features/world/presentation/dialogs/ai_world_map_prompt_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AiWorldMapPromptDialog extends StatefulWidget {
  const AiWorldMapPromptDialog({super.key});

  @override
  State<AiWorldMapPromptDialog> createState() => _AiWorldMapPromptDialogState();
}

class _AiWorldMapPromptDialogState extends State<AiWorldMapPromptDialog> {
  // --- State Variables ---
  // Nilai awal dropdown
  String _selectedType = 'Low-poly Ocean';
  String _selectedTexture = 'Fine mesh of blue polygons';
  String _selectedFeature = 'Circular icons representing islands';

  // Controllers untuk input manual (Custom)
  final TextEditingController _customTypeCtrl = TextEditingController();
  final TextEditingController _customTextureCtrl = TextEditingController();
  final TextEditingController _customFeatureCtrl = TextEditingController();

  String _generatedPrompt = "";

  // --- DATA OPTIONS (DAFTAR PILIHAN) ---

  // 1. Tipe Dunia
  final List<String> _worldTypes = [
    'AI yang Tentukan',
    'Isi Sendiri (Custom)',
    'Low-poly Ocean',
    'Realistic Earth-like',
    'Vast Desert (Dune)',
    'Frozen Wasteland',
    'Volcanic Magma',
    'Dense Jungle Planet',
    'Cyberpunk City (Ecumenopolis)',
    'Floating Islands (Skyland)',
    'Gas Giant Swirls',
    'Crimson Mars-like',
    'Alien Purple Flora',
    'Crystal Crystalline',
    'Dark Gothic',
    'Golden Steampunk',
    'Papercraft Style',
    'Voxel / Minecraft Style',
    'Watercolor Painted',
    'Ink Map Style',
    'Retro 8-bit Pixel Art',
    'Post-Apocalyptic Ruined',
  ];

  // 2. Tekstur Permukaan
  final List<String> _textures = [
    'AI yang Tentukan',
    'Isi Sendiri (Custom)',
    'Fine mesh of blue polygons',
    'Realistic deep blue water',
    'Shifting golden sand dunes',
    'Cracked white ice sheet',
    'Glowing lava veins on rock',
    'Dense green canopy',
    'Metallic circuit board',
    'Swirling clouds and storms',
    'Hexagonal strategy grid',
    'Old parchment paper',
    'Rough oil paint strokes',
    'Matte flat digital colors',
    'Glowing neon grid',
    'Rustic hand-drawn lines',
    'Smooth marble surface',
    'Rusty metal plates',
    'Organic biological tissue',
    'Starry space reflection',
    'Mosaic tile pattern',
    'Blueprint schematic lines',
  ];

  // 3. Objek Kecil Tersebar
  final List<String> _features = [
    'AI yang Tentukan',
    'Isi Sendiri (Custom)',
    'Circular icons representing islands',
    'Tiny sailboats',
    'Miniature cities',
    'Smoking volcanoes',
    'Floating clouds',
    'Jagged mountain peaks',
    'Ancient pyramids',
    'Sci-fi domed cities',
    'Giant trees',
    'Fantasy castles',
    'Crashed spaceships',
    'Roaming sea monsters',
    'Glowing crystal spires',
    'Industrial factories',
    'Stone monoliths',
    'Oasis patches',
    'Flying dragons',
    'Satellite stations',
    'Whirlpools',
    'Simple geometric shapes',
  ];

  @override
  void initState() {
    super.initState();
    _generatePrompt(); // Generate awal
  }

  @override
  void dispose() {
    _customTypeCtrl.dispose();
    _customTextureCtrl.dispose();
    _customFeatureCtrl.dispose();
    super.dispose();
  }

  // --- LOGIKA PENYUSUNAN PROMPT ---
  void _generatePrompt() {
    setState(() {
      // 1. TYPE
      String typeVal = _selectedType;
      if (_selectedType == 'Isi Sendiri (Custom)') {
        typeVal = _customTypeCtrl.text.trim().isEmpty
            ? "unique"
            : _customTypeCtrl.text.trim();
      } else if (_selectedType == 'AI yang Tentukan') {
        typeVal = "imaginative and distinct";
      }

      // 2. TEXTURE
      String texVal = _selectedTexture;
      if (_selectedTexture == 'Isi Sendiri (Custom)') {
        texVal = _customTextureCtrl.text.trim().isEmpty
            ? "detailed texture"
            : _customTextureCtrl.text.trim();
      } else if (_selectedTexture == 'AI yang Tentukan') {
        texVal = "rich and complex surface texture";
      }

      // 3. FEATURES
      String featVal = _selectedFeature;
      if (_selectedFeature == 'Isi Sendiri (Custom)') {
        featVal = _customFeatureCtrl.text.trim().isEmpty
            ? "small details"
            : _customFeatureCtrl.text.trim();
      } else if (_selectedFeature == 'AI yang Tentukan') {
        featVal = "scattered points of interest";
      }

      // Template Prompt
      _generatedPrompt =
          "Extreme high-altitude aerial shot of a $typeVal world. "
          "The viewpoint is so high that the water/surface texture looks like a $texVal. "
          "The ocean/landscape feels massive and overwhelming in scale. "
          "Tiny, insignificant $featVal are scattered far apart on the vast surface. "
          "No text labels. The horizon is very distant and slightly curved, emphasizing the planet's scale. "
          "Clouds appear as small wisps floating high above the surface.";
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPrompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Prompt Dunia disalin! Paste ke Midjourney/Dall-E."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Penyesuaian Tema (Dark/Light)
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

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.public, color: Colors.blue),
          SizedBox(width: 8),
          Text("AI World Prompt"),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Text(
                  "Generator ini dirancang untuk membuat peta skala PLANET/SAMUDRA luas (High Altitude).",
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),

              // --- INPUT SECTION ---
              _buildSection(
                label: "Tipe Dunia (World Style)",
                value: _selectedType,
                items: _worldTypes,
                onChanged: (val) {
                  setState(() => _selectedType = val!);
                  _generatePrompt();
                },
                customController: _customTypeCtrl,
                customHint: "Cth: Cyberpunk Ocean / Candy World",
              ),

              _buildSection(
                label: "Tekstur Permukaan",
                value: _selectedTexture,
                items: _textures,
                onChanged: (val) {
                  setState(() => _selectedTexture = val!);
                  _generatePrompt();
                },
                customController: _customTextureCtrl,
                customHint: "Cth: Digital grid / Swirling magma",
              ),

              _buildSection(
                label: "Objek Kecil Tersebar",
                value: _selectedFeature,
                items: _features,
                onChanged: (val) {
                  setState(() => _selectedFeature = val!);
                  _generatePrompt();
                },
                customController: _customFeatureCtrl,
                customHint: "Cth: Neon Cities / Floating Rocks",
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
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: _copyToClipboard,
        ),
      ],
    );
  }

  // Helper Widget untuk membuat bagian input dropdown + custom textfield
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
          // Menu item dengan styling agar rapi
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
        // Tampilkan TextField HANYA jika opsi "Custom" dipilih
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
