import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class MoveBuildingDialog extends StatefulWidget {
  final Directory currentRegionDir;
  final Directory currentDistrictDir;

  const MoveBuildingDialog({
    super.key,
    required this.currentRegionDir,
    required this.currentDistrictDir,
  });

  @override
  State<MoveBuildingDialog> createState() => _MoveBuildingDialogState();
}

class _MoveBuildingDialogState extends State<MoveBuildingDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State untuk Tab Lokal
  List<Directory> _localDistricts = [];
  bool _isLoadingLocal = true;

  // State untuk Tab Dunia
  List<Directory> _regions = [];
  Directory? _selectedRegionInWorldTab;
  List<Directory> _districtsInSelectedRegion = [];
  bool _isLoadingWorld = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLocalDistricts();
    _loadRegions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOAD DATA ---

  Future<void> _loadLocalDistricts() async {
    // Memuat distrik lain dalam wilayah yang SAMA (Tab 1)
    try {
      final entities = await widget.currentRegionDir.list().toList();
      final dirs = entities.whereType<Directory>().toList();

      setState(() {
        // Filter: Jangan tampilkan distrik asal (current)
        _localDistricts = dirs
            .where((d) => d.path != widget.currentDistrictDir.path)
            .toList();
        _isLoadingLocal = false;
      });
    } catch (e) {
      debugPrint("Error loading local districts: $e");
      setState(() => _isLoadingLocal = false);
    }
  }

  Future<void> _loadRegions() async {
    // Memuat semua wilayah dari root (Tab 2)
    if (AppSettings.baseBuildingsPath == null) return;

    setState(() => _isLoadingWorld = true);
    try {
      final rootDir = Directory(AppSettings.baseBuildingsPath!);
      if (await rootDir.exists()) {
        final entities = await rootDir.list().toList();
        setState(() {
          _regions = entities.whereType<Directory>().toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading regions: $e");
    }
    setState(() => _isLoadingWorld = false);
  }

  Future<void> _loadDistrictsForRegion(Directory regionDir) async {
    // Drill-down: Memuat distrik ketika wilayah dipilih di Tab 2
    setState(() => _isLoadingWorld = true);
    try {
      final entities = await regionDir.list().toList();
      setState(() {
        _districtsInSelectedRegion = entities.whereType<Directory>().toList();
        // Jika kebetulan user memilih wilayah yang sama dengan wilayah saat ini di Tab Dunia,
        // kita filter juga distrik asalnya agar konsisten.
        if (regionDir.path == widget.currentRegionDir.path) {
          _districtsInSelectedRegion.removeWhere(
            (d) => d.path == widget.currentDistrictDir.path,
          );
        }
      });
    } catch (e) {
      debugPrint("Error loading districts for region: $e");
    }
    setState(() => _isLoadingWorld = false);
  }

  // --- ACTION ---

  void _selectDestination(Directory targetDistrict) {
    Navigator.pop(context, targetDistrict);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pindahkan Bangunan'),
      contentPadding: const EdgeInsets.only(top: 20), // Kurangi padding default
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Distrik Sekitar'),
                Tab(text: 'Jelajahi Dunia'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildLocalTab(), _buildWorldTab()],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  Widget _buildLocalTab() {
    if (_isLoadingLocal) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_localDistricts.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada distrik lain di wilayah ini.\nCoba tab "Jelajahi Dunia".',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _localDistricts.length,
      separatorBuilder: (c, i) => const Divider(),
      itemBuilder: (context, index) {
        final dir = _localDistricts[index];
        return ListTile(
          leading: const Icon(Icons.holiday_village, color: Colors.green),
          title: Text(p.basename(dir.path)),
          subtitle: const Text('Di wilayah ini'),
          onTap: () => _selectDestination(dir),
        );
      },
    );
  }

  Widget _buildWorldTab() {
    // Tampilan Level 1: Daftar Wilayah
    if (_selectedRegionInWorldTab == null) {
      if (_isLoadingWorld) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_regions.isEmpty) {
        return const Center(child: Text('Belum ada wilayah lain.'));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Pilih Wilayah Tujuan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _regions.length,
              itemBuilder: (context, index) {
                final region = _regions[index];
                return ListTile(
                  leading: const Icon(Icons.public, color: Colors.blue),
                  title: Text(p.basename(region.path)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _selectedRegionInWorldTab = region;
                    });
                    _loadDistrictsForRegion(region);
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    // Tampilan Level 2: Daftar Distrik dalam Wilayah Terpilih
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(p.basename(_selectedRegionInWorldTab!.path)),
          subtitle: const Text('Ketuk untuk kembali ganti wilayah'),
          tileColor: Colors.grey.shade100,
          onTap: () {
            setState(() {
              _selectedRegionInWorldTab = null;
              _districtsInSelectedRegion.clear();
            });
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoadingWorld
              ? const Center(child: CircularProgressIndicator())
              : _districtsInSelectedRegion.isEmpty
              ? const Center(child: Text('Wilayah ini belum memiliki distrik.'))
              : ListView.separated(
                  itemCount: _districtsInSelectedRegion.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final dist = _districtsInSelectedRegion[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.holiday_village,
                        color: Colors.green,
                      ),
                      title: Text(p.basename(dist.path)),
                      subtitle: Text(
                        'Wilayah: ${p.basename(_selectedRegionInWorldTab!.path)}',
                      ),
                      onTap: () => _selectDestination(dist),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
