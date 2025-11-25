// lib/features/plan_architect/presentation/dialogs/interior_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/data/interior_data.dart';
import 'package:mind_palace_manager/features/plan_architect/data/plan_models.dart';

class InteriorPickerSheet extends StatefulWidget {
  final PlanController controller;
  final ScrollController scrollController;
  final ColorScheme colorScheme;

  const InteriorPickerSheet({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.colorScheme,
  });

  @override
  State<InteriorPickerSheet> createState() => _InteriorPickerSheetState();
}

class _InteriorPickerSheetState extends State<InteriorPickerSheet> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    return InteriorData.list
        .where((item) => item['name'].toLowerCase().contains(query))
        .toList();
  }

  List<Map<String, dynamic>> _getItemsByCategory(String category) {
    return InteriorData.list.where((item) => item['cat'] == category).toList();
  }

  List<Map<String, dynamic>> _getFavorites() {
    return InteriorData.list
        .where((item) => AppSettings.favoriteInteriors.contains(item['name']))
        .toList();
  }

  List<Map<String, dynamic>> _getRecents() {
    List<Map<String, dynamic>> results = [];
    for (String name in AppSettings.recentInteriors) {
      try {
        final item = InteriorData.list.firstWhere((e) => e['name'] == name);
        results.add(item);
      } catch (_) {}
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchQuery.isNotEmpty;
    final List<String> categories = [
      'Baru / Custom',
      'Favorit',
      'Furnitur',
      'Elektronik',
      'Sanitasi',
      'Dapur',
      'Kantor',
      'Struktur',
      'Dekorasi',
      'Outdoor',
      'Simbol/Lain',
    ];

    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari interior...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: widget.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: isSearching
                ? _buildSearchResults()
                : DefaultTabController(
                    length: categories.length,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: widget.colorScheme.primary,
                          unselectedLabelColor:
                              widget.colorScheme.onSurfaceVariant,
                          indicatorColor: widget.colorScheme.primary,
                          tabs: categories.map((c) => Tab(text: c)).toList(),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildRecentAndCustomTab(),
                              _buildFavoritesTab(),
                              _buildGrid(_getItemsByCategory('Furnitur')),
                              _buildGrid(_getItemsByCategory('Elektronik')),
                              _buildGrid(_getItemsByCategory('Sanitasi')),
                              _buildGrid(_getItemsByCategory('Dapur')),
                              _buildGrid(_getItemsByCategory('Kantor')),
                              _buildGrid(_getItemsByCategory('Struktur')),
                              _buildGrid(_getItemsByCategory('Dekorasi')),
                              _buildGrid(_getItemsByCategory('Outdoor')),
                              _buildGrid([
                                ..._getItemsByCategory('Simbol'),
                                ..._getItemsByCategory('Lainnya'),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _getFilteredItems();
    if (results.isEmpty) {
      return Center(
        child: Text(
          "Tidak ditemukan interior '$_searchQuery'",
          style: TextStyle(color: widget.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return _buildGrid(results);
  }

  Widget _buildRecentAndCustomTab() {
    final recents = _getRecents();
    final savedCustoms = widget.controller.savedCustomInteriors;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        InkWell(
          onTap: () => _showAiPromptGenerator(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 28,
                  color: Colors.purple.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Buat Interior Baru via AI",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                      Text(
                        "1. Buat Prompt -> 2. Paste ke Gemini -> 3. Import JSON",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.pop(context);
            widget.controller.addCustomImageObject();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 28,
                  color: widget.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Buat Interior dari Gambar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      "Pilih foto dari galeri",
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.colorScheme.onPrimaryContainer
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (savedCustoms.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            "Interior Buatan Saya (Custom & AI)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              "Tekan lama untuk menghapus.",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: savedCustoms.length,
            itemBuilder: (c, i) {
              final customItem = savedCustoms[i];
              return InkWell(
                onTap: () {
                  final center = Offset(
                    widget.controller.canvasWidth / 2,
                    widget.controller.canvasHeight / 2,
                  );
                  widget.controller.placeSavedItem(customItem, center);
                  Navigator.pop(context);
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Hapus Interior?"),
                      content: Text(
                        "Hapus '${customItem.name}' dari daftar global?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            await AppSettings.removeCustomAsset(i);
                            setState(() {
                              widget.controller.savedCustomInteriors.removeAt(
                                i,
                              );
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Interior dihapus dari library global.",
                                ),
                                duration: Duration(milliseconds: 800),
                              ),
                            );
                          },
                          child: const Text("Hapus Permanen"),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        customItem is PlanGroup ? Icons.group : Icons.draw,
                        size: 24,
                        color: widget.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          (customItem.name != null &&
                                  customItem.name.isNotEmpty)
                              ? customItem.name
                              : "Tanpa Nama",
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          "Baru Digunakan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (recents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Belum ada item yang digunakan.",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
            ),
            itemCount: recents.length,
            itemBuilder: (c, i) => _buildGridItem(recents[i]),
          ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    final favs = _getFavorites();
    if (favs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Belum ada favorit.",
              style: TextStyle(color: Colors.grey),
            ),
            const Text(
              "Tekan lama item untuk memfavoritkan.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return _buildGrid(favs);
  }

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildGridItem(items[index]),
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
    final bool isFav = AppSettings.favoriteInteriors.contains(item['name']);
    return InkWell(
      onTap: () {
        widget.controller.selectObjectIcon(item['icon'], item['name']);
        Navigator.pop(context);
      },
      onLongPress: () async {
        await AppSettings.toggleFavoriteInterior(item['name']);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFav ? 'Dihapus dari favorit' : 'Ditambahkan ke favorit',
              ),
              duration: const Duration(milliseconds: 800),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'], size: 28, color: widget.colorScheme.onSurface),
              const SizedBox(height: 4),
              Text(
                item['name'],
                style: TextStyle(
                  fontSize: 11,
                  color: widget.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (isFav)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.favorite,
                size: 14,
                color: Colors.red.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  void _showAiPromptGenerator(BuildContext context) {
    final textCtrl = TextEditingController();
    String detailLevel = 'medium';

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("AI Interior Generator"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Apa yang ingin Anda buat?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Contoh: Grand Piano Hitam, Meja Billiard, Kasur Tingkat",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(
                      hintText: "Deskripsi detail...",
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Tingkat Kedetailan:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: detailLevel,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text("Sederhana (Low)"),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text("Menengah (Standard)"),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text("Sangat Detail (Complex)"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() => detailLevel = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    "Langkah Selanjutnya:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text("1. Salin Prompt & Buka AI"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade50,
                      foregroundColor: Colors.purple,
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () {
                      if (textCtrl.text.isEmpty) return;

                      String detailInstruction = "";
                      if (detailLevel == 'low') {
                        detailInstruction =
                            "Tingkat Detail: RENDAH. Gunakan sedikit shape (3-8 shape). Gunakan bentuk geometris dasar saja. Fokus pada siluet utama.";
                      } else if (detailLevel == 'medium') {
                        detailInstruction =
                            "Tingkat Detail: MENENGAH. Gunakan detail standar (10-20 shape). Tambahkan aksen seperti sandaran tangan atau kaki meja.";
                      } else {
                        detailInstruction =
                            "Tingkat Detail: SANGAT TINGGI (COMPLEX). Gunakan BANYAK shape kecil (20-50+ shape) untuk menciptakan tekstur, tombol, bayangan, dan detail realistis. Pecah objek besar menjadi komponen kecil. Tumpuk shape untuk efek gradasi/detail.";
                      }

                      final prompt =
                          """
Saya membutuhkan struktur data JSON untuk aplikasi desain denah. 
Tolong buatkan objek: "${textCtrl.text}".
$detailInstruction

Hasilkan HANYA kode JSON mentah (tanpa markdown ```json).
Format JSON harus seperti ini:
{
  "name": "Nama Objek",
  "elements": [
    {
      "type": "shape", 
      "shapeType": "rectangle" (pilihan: rectangle, roundedRect, circle, triangle),
      "x": 0.0 (koordinat relatif X dari tengah),
      "y": 0.0 (koordinat relatif Y dari tengah),
      "w": 50.0 (lebar),
      "h": 50.0 (tinggi),
      "color": "#RRGGBB",
      "filled": true
    },
    {
      "type": "path",
      "points": [[0,0], [10,10]], 
      "color": "#RRGGBB",
      "width": 2.0
    }
  ]
}
Gunakan kombinasi shape sederhana (rectangle, circle, roundedRect) untuk membentuk visualisasi "${textCtrl.text}" dari pandangan atas (top-down view/denah).
""";
                      Clipboard.setData(ClipboardData(text: prompt));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Prompt disalin! Tempel ke Gemini/ChatGPT sekarang.",
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade800,
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    label: const Text("2. Import JSON Hasil AI"),
                    onPressed: () {
                      Navigator.pop(c);
                      _showImportJsonDialog(context);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("Tutup"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImportJsonDialog(BuildContext context) {
    final jsonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Paste JSON dari AI"),
        content: TextField(
          controller: jsonCtrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText:
                'Paste kode JSON di sini...\nContoh: {"name": "Sofa", ...}',
            border: OutlineInputBorder(),
            filled: true,
          ),
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (jsonCtrl.text.trim().isNotEmpty) {
                try {
                  widget.controller.importInteriorFromJson(jsonCtrl.text);
                  Navigator.pop(c);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Objek AI berhasil dibuat!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal import JSON: $e")),
                  );
                }
              }
            },
            child: const Text("Buat Objek"),
          ),
        ],
      ),
    );
  }
}
