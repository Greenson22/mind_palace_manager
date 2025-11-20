import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class MoveBuildingDialog extends StatefulWidget {
  final Directory currentRegionDir;
  final Directory currentDistrictDir;

  // --- BARU: Flag untuk menandakan ini dibuka dari Pabrik/Gudang ---
  final bool isFactoryMode;

  const MoveBuildingDialog({
    super.key,
    required this.currentRegionDir,
    required this.currentDistrictDir,
    this.isFactoryMode = false, // Default false
  });

  @override
  State<MoveBuildingDialog> createState() => _MoveBuildingDialogState();
}

class _MoveBuildingDialogState extends State<MoveBuildingDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Directory> _localDistricts = [];
  bool _isLoadingLocal = true;

  List<Directory> _regions = [];
  Directory? _selectedRegionInWorldTab;
  List<Directory> _districtsInSelectedRegion = [];
  bool _isLoadingWorld = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Jika dari Pabrik, langsung lompat ke Tab Dunia (index 1) karena Tab Lokal tidak relevan
    if (widget.isFactoryMode) {
      _tabController.index = 1;
      _isLoadingLocal = false; // Tidak perlu load lokal
    } else {
      _loadLocalDistricts();
    }

    _loadRegions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalDistricts() async {
    // Jika mode pabrik, jangan muat apa-apa di tab lokal
    if (widget.isFactoryMode) return;

    try {
      final entities = await widget.currentRegionDir.list().toList();
      final dirs = entities.whereType<Directory>().toList();

      setState(() {
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
    if (AppSettings.baseBuildingsPath == null) return;

    setState(() => _isLoadingWorld = true);
    try {
      final rootDir = Directory(AppSettings.baseBuildingsPath!);
      if (await rootDir.exists()) {
        final entities = await rootDir.list().toList();
        setState(() {
          _regions = entities.whereType<Directory>().where((d) {
            final name = p.basename(d.path);
            // --- FILTER BARU: Jangan tampilkan folder sistem (berawalan _) ---
            return !name.startsWith('_');
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading regions: $e");
    }
    setState(() => _isLoadingWorld = false);
  }

  Future<void> _loadDistrictsForRegion(Directory regionDir) async {
    setState(() => _isLoadingWorld = true);
    try {
      final entities = await regionDir.list().toList();
      setState(() {
        _districtsInSelectedRegion = entities.whereType<Directory>().toList();

        // Filter distrik asal hanya jika BUKAN mode pabrik
        if (!widget.isFactoryMode &&
            regionDir.path == widget.currentRegionDir.path) {
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

  void _selectDestination(Directory targetDistrict) {
    Navigator.pop(context, targetDistrict);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isFactoryMode ? 'Deploy Bangunan' : 'Pindahkan Bangunan',
      ),
      contentPadding: const EdgeInsets.only(top: 20),
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
    // --- TAMPILAN KHUSUS MODE PABRIK ---
    if (widget.isFactoryMode) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.public_off, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'Mode Deploy Aktif.\nSilakan pilih Wilayah tujuan di tab "Jelajahi Dunia".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    // -----------------------------------

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
