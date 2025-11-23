import 'package:flutter/material.dart';

class WorldFabMenu extends StatefulWidget {
  final VoidCallback onEditMap;
  final VoidCallback onCreateRegion;

  const WorldFabMenu({
    super.key,
    required this.onEditMap,
    required this.onCreateRegion,
  });

  @override
  State<WorldFabMenu> createState() => _WorldFabMenuState();
}

class _WorldFabMenuState extends State<WorldFabMenu> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          _buildFabItem(Icons.map, "Edit Peta Dunia", Colors.blue.shade100, () {
            widget.onEditMap();
            setState(() => _isOpen = false);
          }),
          const SizedBox(height: 16),
          _buildFabItem(Icons.public, "Buat Wilayah", null, () {
            widget.onCreateRegion();
            setState(() => _isOpen = false);
          }),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          heroTag: 'world_menu_toggle',
          onPressed: () => setState(() => _isOpen = !_isOpen),
          child: Icon(_isOpen ? Icons.close : Icons.apps),
        ),
      ],
    );
  }

  Widget _buildFabItem(
    IconData icon,
    String label,
    Color? color,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label, // Unique tag
          onPressed: onTap,
          backgroundColor: color,
          child: Icon(icon, color: Colors.black87),
        ),
      ],
    );
  }
}
