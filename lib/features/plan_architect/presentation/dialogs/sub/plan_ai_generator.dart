import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Clipboard
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';

class PlanAiGeneratorDialog extends StatefulWidget {
  final PlanController controller;
  const PlanAiGeneratorDialog({super.key, required this.controller});

  @override
  State<PlanAiGeneratorDialog> createState() => _PlanAiGeneratorDialogState();
}

class _PlanAiGeneratorDialogState extends State<PlanAiGeneratorDialog> {
  final jsonCtrl = TextEditingController();

  // Controller untuk input manual
  final customTypeCtrl = TextEditingController();
  final customShapeCtrl = TextEditingController();

  String roomType = 'Kamar Tidur';
  String roomShape = 'Kotak (Persegi)';
  double lociCount = 5;
  String additionalContext = '';

  // --- OPSI BARU ---
  bool includeLabels = true;

  @override
  void dispose() {
    jsonCtrl.dispose();
    customTypeCtrl.dispose();
    customShapeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark
        ? Colors.purple.shade900.withOpacity(0.3)
        : Colors.purple.shade50;
    final borderColor = isDark
        ? Colors.purple.shade700
        : Colors.purple.shade100;
    final titleColor = isDark ? Colors.purple.shade200 : Colors.purple;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.psychology, color: Colors.purple),
          SizedBox(width: 8),
          Text("AI Arsitek Denah"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "1. Tentukan Spesifikasi:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- TIPE RUANGAN ---
                  DropdownButtonFormField<String>(
                    value: roomType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Tipe Ruangan",
                      isDense: true,
                    ),
                    items:
                        [
                              'AI yang Tentukan',
                              'Isi Sendiri (Custom)',
                              'Kamar Tidur',
                              'Ruang Tamu',
                              'Dapur',
                              'Kamar Mandi',
                              'Kantor',
                              'Kelas',
                              'Istana Fantasi',
                              'Museum',
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => roomType = v!),
                  ),
                  if (roomType == 'Isi Sendiri (Custom)')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: customTypeCtrl,
                        decoration: const InputDecoration(
                          labelText: "Ketik Tipe Ruangan",
                          hintText: "Misal: Penjara Bawah Tanah",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // --- BENTUK RUANGAN ---
                  DropdownButtonFormField<String>(
                    value: roomShape,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Bentuk Ruangan",
                      isDense: true,
                    ),
                    items:
                        [
                              'AI yang Tentukan',
                              'Isi Sendiri (Custom)',
                              'Kotak (Persegi)',
                              'Persegi Panjang',
                              'Bentuk L',
                              'Bentuk U',
                              'Koridor Panjang',
                              'Lingkaran/Oval',
                              'Heksagonal',
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => roomShape = v!),
                  ),
                  if (roomShape == 'Isi Sendiri (Custom)')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: customShapeCtrl,
                        decoration: const InputDecoration(
                          labelText: "Ketik Bentuk Ruangan",
                          hintText: "Misal: Segitiga",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Jumlah Loci (Titik):"),
                      Text(
                        "${lociCount.toInt()}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: lociCount,
                    min: 3,
                    max: 30,
                    divisions: 27,
                    activeColor: Colors.purple,
                    onChanged: (v) => setState(() => lociCount = v),
                  ),

                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Info Tambahan (Opsional)",
                      hintText: "Cth: Ada piano di pojok",
                      isDense: true,
                    ),
                    onChanged: (v) => additionalContext = v,
                  ),

                  // --- CHECKBOX LABEL ---
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text(
                      "Tampilkan Label Teks (Canvas)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      "Jika mati, nama hanya tersimpan dalam info objek.",
                      style: TextStyle(fontSize: 11),
                    ),
                    value: includeLabels,
                    onChanged: (v) => setState(() => includeLabels = v ?? true),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: Colors.purple,
                  ),

                  // ---------------------
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text("Salin Prompt"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.purple.shade800
                          : Colors.white,
                      foregroundColor: isDark ? Colors.white : Colors.purple,
                      elevation: 0,
                      side: BorderSide(color: borderColor),
                      minimumSize: const Size(double.infinity, 36),
                    ),
                    onPressed: _copyPrompt,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "2. Paste Hasil JSON di Sini:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: jsonCtrl,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: const InputDecoration(
                hintText: '{"walls": [...], "portals": [...], "loci": [...]}',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        FilledButton(
          onPressed: _generatePlan,
          child: const Text("Generate Denah"),
        ),
      ],
    );
  }

  void _copyPrompt() {
    String finalType = roomType;
    if (roomType == 'Isi Sendiri (Custom)') {
      finalType = customTypeCtrl.text.isNotEmpty
          ? customTypeCtrl.text
          : 'Bebas';
    } else if (roomType == 'AI yang Tentukan') {
      finalType = 'Tentukan sendiri tipe ruangan yang logis';
    }

    String finalShape = roomShape;
    if (roomShape == 'Isi Sendiri (Custom)') {
      finalShape = customShapeCtrl.text.isNotEmpty
          ? customShapeCtrl.text
          : 'Bebas';
    } else if (roomShape == 'AI yang Tentukan') {
      finalShape = 'Tentukan sendiri bentuk yang optimal';
    }

    final prompt =
        """
Saya membuat Memory Palace. Buatkan JSON denah lantai.
Spesifikasi: $finalType.
Bentuk Ruangan: $finalShape.
Jumlah Loci (Interior): ${lociCount.toInt()}.
Detail Tambahan: $additionalContext.
Canvas: 0-500 (Pusat ~250,250).

Format JSON WAJIB (Hanya JSON murni):
{
  "walls": [
    {"sx": 100, "sy": 100, "ex": 400, "ey": 100},
    ... (lanjutkan tembok menutup ruangan)
  ],
  "portals": [
    {"type": "door", "x": 120, "y": 100, "rot": 0},
    {"type": "window", "x": 400, "y": 250, "rot": 90}
  ],
  "loci": [
    {
      "name": "1. [Nama]", 
      "x": 120, 
      "y": 120, 
      "icon": "[tipe: bed/chair/tv/etc]", 
      "desc": "...",
      "size": 20.0
    },
    ...
  ]
}
PENTING: 
1. Pisahkan Pintu/Jendela ke array "portals". 
2. Gunakan "loci" hanya untuk furniture/objek memori.
3. Properti "size" adalah estimasi ukuran objek dalam pixel (double).
""";
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prompt disalin! Tempel ke AI.")),
    );
  }

  void _generatePlan() {
    if (jsonCtrl.text.isNotEmpty) {
      try {
        // --- PASSING NILAI ADD LABELS ---
        widget.controller.importFullPlanFromJson(
          jsonCtrl.text,
          addLabels: includeLabels,
        );

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Denah AI berhasil dibuat!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal: ${e.toString().split('\n').first}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
