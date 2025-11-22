// lib/features/plan_architect/data/plan_models.dart
import 'package:flutter/material.dart';

class Wall {
  final String id;
  final Offset start;
  final Offset end;
  final double thickness;
  final String description; // Deskripsi tembok

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
    thickness: json['thickness'] ?? 10.0,
    description: json['description'] ?? '',
  );

  // Helper: Copy with
  Wall copyWith({String? description}) {
    return Wall(
      id: id,
      start: start,
      end: end,
      thickness: thickness,
      description: description ?? this.description,
    );
  }
}

class PlanObject {
  final String id;
  final Offset position;
  final String name;
  final String description; // Deskripsi interior
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
