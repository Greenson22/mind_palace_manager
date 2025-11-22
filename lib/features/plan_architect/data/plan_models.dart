// lib/features/plan_architect/data/plan_models.dart
import 'package:flutter/material.dart';

// --- MODEL TEMBOK (WALL) ---
class Wall {
  final String id;
  final Offset start;
  final Offset end;
  final double thickness;
  final String description; // Deskripsi tembok (misal: Beton, Bata)

  Wall({
    required this.id,
    required this.start,
    required this.end,
    this.thickness = 10.0,
    this.description = 'Tembok standar',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sx': start.dx,
    'sy': start.dy,
    'ex': end.dx,
    'ey': end.dy,
    'thickness': thickness,
    'description': description,
  };

  factory Wall.fromJson(Map<String, dynamic> json) => Wall(
    id: json['id'],
    start: Offset(json['sx'], json['sy']),
    end: Offset(json['ex'], json['ey']),
    thickness: (json['thickness'] as num?)?.toDouble() ?? 10.0,
    description: json['description'] ?? 'Tembok standar',
  );

  // Helper: Copy with untuk update data parsial
  Wall copyWith({String? description, double? thickness}) {
    return Wall(
      id: id,
      start: start,
      end: end,
      thickness: thickness ?? this.thickness,
      description: description ?? this.description,
    );
  }
}

// --- MODEL INTERIOR (OBJECT) ---
class PlanObject {
  final String id;
  final Offset position;
  final String name;
  final String description; // Deskripsi interior (misal: Meja Makan Kayu Jati)
  final int iconCodePoint; // Simpan kode icon agar bisa di-save ke JSON

  PlanObject({
    required this.id,
    required this.position,
    required this.name,
    required this.description,
    required this.iconCodePoint,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': position.dx,
    'y': position.dy,
    'name': name,
    'description': description,
    'icon': iconCodePoint,
  };

  factory PlanObject.fromJson(Map<String, dynamic> json) => PlanObject(
    id: json['id'],
    position: Offset(json['x'], json['y']),
    name: json['name'],
    description: json['description'],
    iconCodePoint: json['icon'],
  );

  PlanObject copyWith({String? name, String? description}) {
    return PlanObject(
      id: id,
      position: position,
      iconCodePoint: iconCodePoint,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}

// --- MODEL GAMBAR BEBAS (FREEHAND PATH) ---
// Digunakan untuk menggambar interior custom secara manual
class PlanPath {
  final String id;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  PlanPath({
    required this.id,
    required this.points,
    this.color = Colors.brown,
    this.strokeWidth = 2.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    'color': color.value,
    'width': strokeWidth,
  };

  factory PlanPath.fromJson(Map<String, dynamic> json) {
    return PlanPath(
      id: json['id'],
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'], p['dy']))
          .toList(),
      color: Color(json['color']),
      strokeWidth: (json['width'] as num).toDouble(),
    );
  }
}
