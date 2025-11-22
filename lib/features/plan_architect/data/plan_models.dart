// lib/features/plan_architect/data/plan_models.dart
import 'package:flutter/material.dart';

// --- ENUM BENTUK ---
enum PlanShapeType { rectangle, circle, star }

// --- MODEL TEMBOK ---
class Wall {
  final String id;
  final Offset start;
  final Offset end;
  final double thickness;
  final String description;

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

  Wall copyWith({
    String? id,
    String? description,
    double? thickness,
    Offset? start,
    Offset? end,
  }) {
    return Wall(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      thickness: thickness ?? this.thickness,
      description: description ?? this.description,
    );
  }

  Wall moveBy(Offset delta) {
    return copyWith(start: start + delta, end: end + delta);
  }
}

// --- MODEL INTERIOR (ICON) ---
class PlanObject {
  final String id;
  final Offset position;
  final String name;
  final String description;
  final int iconCodePoint;
  final double rotation; // BARU: Rotasi dalam radian

  PlanObject({
    required this.id,
    required this.position,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': position.dx,
    'y': position.dy,
    'name': name,
    'description': description,
    'icon': iconCodePoint,
    'rot': rotation,
  };

  factory PlanObject.fromJson(Map<String, dynamic> json) => PlanObject(
    id: json['id'],
    position: Offset(json['x'], json['y']),
    name: json['name'],
    description: json['description'],
    iconCodePoint: json['icon'],
    rotation: (json['rot'] as num?)?.toDouble() ?? 0.0,
  );

  PlanObject copyWith({
    String? id,
    String? name,
    String? description,
    Offset? position,
    double? rotation,
  }) {
    return PlanObject(
      id: id ?? this.id,
      position: position ?? this.position,
      iconCodePoint: iconCodePoint,
      name: name ?? this.name,
      description: description ?? this.description,
      rotation: rotation ?? this.rotation,
    );
  }

  PlanObject moveBy(Offset delta) {
    return copyWith(position: position + delta);
  }
}

// --- MODEL LABEL TEKS ---
class PlanLabel {
  final String id;
  final Offset position;
  final String text;
  final double fontSize;

  PlanLabel({
    required this.id,
    required this.position,
    required this.text,
    this.fontSize = 16.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': position.dx,
    'y': position.dy,
    'text': text,
    'size': fontSize,
  };

  factory PlanLabel.fromJson(Map<String, dynamic> json) => PlanLabel(
    id: json['id'],
    position: Offset(json['x'], json['y']),
    text: json['text'],
    fontSize: (json['size'] as num?)?.toDouble() ?? 16.0,
  );

  PlanLabel copyWith({
    String? id,
    String? text,
    double? fontSize,
    Offset? position,
  }) {
    return PlanLabel(
      id: id ?? this.id,
      position: position ?? this.position,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  PlanLabel moveBy(Offset delta) {
    return copyWith(position: position + delta);
  }
}

// --- MODEL GAMBAR BEBAS (PATH) ---
class PlanPath {
  final String id;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final String name;
  final String description;
  final bool isSavedAsset;

  PlanPath({
    required this.id,
    required this.points,
    this.color = Colors.brown,
    this.strokeWidth = 2.0,
    this.name = "Interior Custom",
    this.description = "Deskripsi belum diatur.",
    this.isSavedAsset = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    'color': color.value,
    'width': strokeWidth,
    'name': name,
    'desc': description,
    'isSaved': isSavedAsset,
  };

  factory PlanPath.fromJson(Map<String, dynamic> json) {
    return PlanPath(
      id: json['id'],
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'], p['dy']))
          .toList(),
      color: Color(json['color']),
      strokeWidth: (json['width'] as num).toDouble(),
      name: json['name'] ?? "Interior Custom",
      description: json['desc'] ?? "Deskripsi belum diatur.",
      isSavedAsset: json['isSaved'] ?? false,
    );
  }

  PlanPath copyWith({
    String? id,
    String? name,
    String? description,
    bool? isSavedAsset,
    List<Offset>? points,
  }) {
    return PlanPath(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color,
      strokeWidth: strokeWidth,
      name: name ?? this.name,
      description: description ?? this.description,
      isSavedAsset: isSavedAsset ?? this.isSavedAsset,
    );
  }

  PlanPath moveBy(Offset delta) {
    return copyWith(points: points.map((p) => p + delta).toList());
  }
}

// --- MODEL BENTUK GEOMETRIS (BARU) ---
class PlanShape {
  final String id;
  final Rect rect; // Posisi dan Ukuran
  final PlanShapeType type;
  final Color color;
  final bool isFilled;
  final double rotation; // Rotasi dalam radian
  final String name;
  final String description;

  PlanShape({
    required this.id,
    required this.rect,
    required this.type,
    this.color = Colors.blue,
    this.isFilled = true,
    this.rotation = 0.0,
    this.name = "Bentuk",
    this.description = "",
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'l': rect.left,
    't': rect.top,
    'w': rect.width,
    'h': rect.height,
    'type': type.index,
    'color': color.value,
    'filled': isFilled,
    'rot': rotation,
    'name': name,
    'desc': description,
  };

  factory PlanShape.fromJson(Map<String, dynamic> json) => PlanShape(
    id: json['id'],
    rect: Rect.fromLTWH(json['l'], json['t'], json['w'], json['h']),
    type: PlanShapeType.values[json['type']],
    color: Color(json['color']),
    isFilled: json['filled'] ?? true,
    rotation: (json['rot'] as num?)?.toDouble() ?? 0.0,
    name: json['name'] ?? 'Bentuk',
    description: json['desc'] ?? '',
  );

  PlanShape copyWith({
    String? id,
    Rect? rect,
    Color? color,
    bool? isFilled,
    double? rotation,
    String? name,
    String? description,
  }) {
    return PlanShape(
      id: id ?? this.id,
      rect: rect ?? this.rect,
      type: type,
      color: color ?? this.color,
      isFilled: isFilled ?? this.isFilled,
      rotation: rotation ?? this.rotation,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  PlanShape moveBy(Offset delta) {
    return copyWith(rect: rect.shift(delta));
  }
}
