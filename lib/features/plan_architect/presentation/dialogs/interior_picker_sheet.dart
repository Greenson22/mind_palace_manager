import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/data/interior_data.dart';

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

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchQuery.isNotEmpty;
    final int totalCount = InteriorData.list.length;
    final int filteredCount = isSearching
        ? _getFilteredItems().length
        : totalCount;

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

          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari interior (cth: Kursi, TV)...",
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
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),

          // INDIKATOR JUMLAH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: widget.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  isSearching
                      ? "Ditemukan $filteredCount dari $totalCount interior"
                      : "Total $totalCount interior tersedia",
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: isSearching
                ? _buildSearchResults()
                : DefaultTabController(
                    length: 9,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          labelColor: widget.colorScheme.primary,
                          unselectedLabelColor:
                              widget.colorScheme.onSurfaceVariant,
                          indicatorColor: widget.colorScheme.primary,
                          tabs: const [
                            Tab(text: "Furnitur"),
                            Tab(text: "Elektronik"),
                            Tab(text: "Sanitasi"),
                            Tab(text: "Dapur"),
                            Tab(text: "Kantor"),
                            Tab(text: "Struktur"),
                            Tab(text: "Dekorasi"),
                            Tab(text: "Outdoor"),
                            Tab(text: "Simbol/Lain"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
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

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            widget.controller.selectObjectIcon(item['icon'], item['name']);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
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
        );
      },
    );
  }
}
