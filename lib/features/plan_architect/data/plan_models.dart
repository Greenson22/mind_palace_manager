import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// --- UPDATE ENUM ---
enum PlanShapeType { rectangle, circle, triangle, hexagon, star }

class PlanGroup {
  // ... (Isi class PlanGroup sama seperti sebelumnya)
  final String id;
  final Offset position;
  final double rotation;
  final List<PlanObject> objects;
  final List<PlanShape> shapes;
  final List<PlanPath> paths;
  final List<PlanLabel> labels;
  final String name;
  final bool isSavedAsset;

  PlanGroup({
    required this.id,
    required this.position,
    this.rotation = 0.0,
    this.objects = const [],
    this.shapes = const [],
    this.paths = const [],
    this.labels = const [],
    this.name = "Grup",
    this.isSavedAsset = false,
  });

  Rect getBounds() {
    if (objects.isEmpty && shapes.isEmpty && paths.isEmpty && labels.isEmpty) {
      return Rect.fromCenter(center: Offset.zero, width: 40, height: 40);
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    void check(double x, double y) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    for (var o in objects) {
      double r = o.size / 2 + 2;
      check(o.position.dx - r, o.position.dy - r);
      check(o.position.dx + r, o.position.dy + r);
    }
    for (var s in shapes) {
      check(s.rect.left, s.rect.top);
      check(s.rect.right, s.rect.bottom);
    }
    for (var p in paths) {
      for (var pt in p.points) {
        check(pt.dx, pt.dy);
      }
    }
    for (var l in labels) {
      check(l.position.dx, l.position.dy);
      check(
        l.position.dx + (l.text.length * l.fontSize * 0.6),
        l.position.dy + l.fontSize,
      );
    }

    if (minX == double.infinity)
      return Rect.fromCenter(center: Offset.zero, width: 40, height: 40);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': position.dx,
    'y': position.dy,
    'rot': rotation,
    'name': name,
    'isSaved': isSavedAsset,
    'objects': objects.map((e) => e.toJson()).toList(),
    'shapes': shapes.map((e) => e.toJson()).toList(),
    'paths': paths.map((e) => e.toJson()).toList(),
    'labels': labels.map((e) => e.toJson()).toList(),
  };

  factory PlanGroup.fromJson(Map<String, dynamic> json) => PlanGroup(
    id: json['id'],
    position: Offset(json['x'], json['y']),
    rotation: (json['rot'] as num?)?.toDouble() ?? 0.0,
    name: json['name'] ?? "Grup",
    isSavedAsset: json['isSaved'] ?? false,
    objects:
        (json['objects'] as List?)
            ?.map((e) => PlanObject.fromJson(e))
            .toList() ??
        [],
    shapes:
        (json['shapes'] as List?)?.map((e) => PlanShape.fromJson(e)).toList() ??
        [],
    paths:
        (json['paths'] as List?)?.map((e) => PlanPath.fromJson(e)).toList() ??
        [],
    labels:
        (json['labels'] as List?)?.map((e) => PlanLabel.fromJson(e)).toList() ??
        [],
  );

  PlanGroup copyWith({
    String? id,
    Offset? position,
    double? rotation,
    List<PlanObject>? objects,
    List<PlanShape>? shapes,
    List<PlanPath>? paths,
    List<PlanLabel>? labels,
    String? name,
    bool? isSavedAsset,
  }) {
    return PlanGroup(
      id: id ?? this.id,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      objects: objects ?? this.objects,
      shapes: shapes ?? this.shapes,
      paths: paths ?? this.paths,
      labels: labels ?? this.labels,
      name: name ?? this.name,
      isSavedAsset: isSavedAsset ?? this.isSavedAsset,
    );
  }

  PlanGroup moveBy(Offset delta) => copyWith(position: position + delta);
}

// ... (PlanFloor, Wall, PlanObject, PlanLabel, PlanPath tetap sama seperti sebelumnya) ...
class PlanFloor {
  final String id;
  final String name;
  final List<Wall> walls;
  final List<PlanObject> objects;
  final List<PlanLabel> labels;
  final List<PlanPath> paths;
  final List<PlanShape> shapes;
  final List<PlanGroup> groups;

  PlanFloor({
    required this.id,
    required this.name,
    this.walls = const [],
    this.objects = const [],
    this.labels = const [],
    this.paths = const [],
    this.shapes = const [],
    this.groups = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'walls': walls.map((e) => e.toJson()).toList(),
    'objects': objects.map((e) => e.toJson()).toList(),
    'labels': labels.map((e) => e.toJson()).toList(),
    'paths': paths.map((e) => e.toJson()).toList(),
    'shapes': shapes.map((e) => e.toJson()).toList(),
    'groups': groups.map((e) => e.toJson()).toList(),
  };

  factory PlanFloor.fromJson(Map<String, dynamic> json) => PlanFloor(
    id: json['id'],
    name: json['name'],
    walls:
        (json['walls'] as List?)?.map((e) => Wall.fromJson(e)).toList() ?? [],
    objects:
        (json['objects'] as List?)
            ?.map((e) => PlanObject.fromJson(e))
            .toList() ??
        [],
    labels:
        (json['labels'] as List?)?.map((e) => PlanLabel.fromJson(e)).toList() ??
        [],
    paths:
        (json['paths'] as List?)?.map((e) => PlanPath.fromJson(e)).toList() ??
        [],
    shapes:
        (json['shapes'] as List?)?.map((e) => PlanShape.fromJson(e)).toList() ??
        [],
    groups:
        (json['groups'] as List?)?.map((e) => PlanGroup.fromJson(e)).toList() ??
        [],
  );

  PlanFloor copyWith({
    String? id,
    String? name,
    List<Wall>? walls,
    List<PlanObject>? objects,
    List<PlanLabel>? labels,
    List<PlanPath>? paths,
    List<PlanShape>? shapes,
    List<PlanGroup>? groups,
  }) {
    return PlanFloor(
      id: id ?? this.id,
      name: name ?? this.name,
      walls: walls ?? this.walls,
      objects: objects ?? this.objects,
      labels: labels ?? this.labels,
      paths: paths ?? this.paths,
      shapes: shapes ?? this.shapes,
      groups: groups ?? this.groups,
    );
  }
}

class Wall {
  final String id;
  final Offset start;
  final Offset end;
  final double thickness;
  final String description;
  final Color color;

  Wall({
    required this.id,
    required this.start,
    required this.end,
    this.thickness = 2.0,
    this.description = 'Tembok',
    this.color = Colors.black,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sx': start.dx,
    'sy': start.dy,
    'ex': end.dx,
    'ey': end.dy,
    'thick': thickness,
    'desc': description,
    'col': color.value,
  };

  factory Wall.fromJson(Map<String, dynamic> json) => Wall(
    id: json['id'],
    start: Offset(json['sx'], json['sy']),
    end: Offset(json['ex'], json['ey']),
    thickness: (json['thick'] as num?)?.toDouble() ?? 2.0,
    description: json['desc'] ?? 'Tembok',
    color: json['col'] != null ? Color(json['col']) : Colors.black,
  );

  Wall copyWith({
    String? id,
    String? description,
    double? thickness,
    Offset? start,
    Offset? end,
    Color? color,
  }) {
    return Wall(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      thickness: thickness ?? this.thickness,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

  Wall moveBy(Offset delta) => copyWith(start: start + delta, end: end + delta);
}

class PlanObject {
  final String id;
  final Offset position;
  final String name;
  final String description;
  final int iconCodePoint;
  final double rotation;
  final Color color;
  final String? navTargetFloorId;
  final double size;
  final String? imagePath;
  final ui.Image? cachedImage;

  PlanObject({
    required this.id,
    required this.position,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    this.rotation = 0.0,
    this.color = Colors.black87,
    this.navTargetFloorId,
    this.size = 14.0,
    this.imagePath,
    this.cachedImage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': position.dx,
    'y': position.dy,
    'name': name,
    'desc': description,
    'icon': iconCodePoint,
    'rot': rotation,
    'col': color.value,
    'navFloor': navTargetFloorId,
    'size': size,
    'imgPath': imagePath,
  };

  factory PlanObject.fromJson(Map<String, dynamic> json) => PlanObject(
    id: json['id'],
    position: Offset(json['x'], json['y']),
    name: json['name'],
    description: json['description'],
    iconCodePoint: json['icon'],
    rotation: (json['rot'] as num?)?.toDouble() ?? 0.0,
    color: json['col'] != null ? Color(json['col']) : Colors.black87,
    navTargetFloorId: json['navFloor'],
    size: (json['size'] as num?)?.toDouble() ?? 14.0,
    imagePath: json['imgPath'],
  );

  PlanObject copyWith({
    String? id,
    String? name,
    String? description,
    Offset? position,
    double? rotation,
    Color? color,
    String? navTargetFloorId,
    double? size,
    String? imagePath,
    ui.Image? cachedImage,
  }) {
    return PlanObject(
      id: id ?? this.id,
      position: position ?? this.position,
      iconCodePoint: iconCodePoint,
      name: name ?? this.name,
      description: description ?? this.description,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      navTargetFloorId: navTargetFloorId ?? this.navTargetFloorId,
      size: size ?? this.size,
      imagePath: imagePath ?? this.imagePath,
      cachedImage: cachedImage ?? this.cachedImage,
    );
  }

  PlanObject moveBy(Offset delta) => copyWith(position: position + delta);
}

class PlanLabel {
  final String id;
  final Offset position;
  final String text;
  final double fontSize;
  final Color color;

  PlanLabel({
    required this.id,
    required this.position,
    required this.text,
    this.fontSize = 12.0,
    this.color = Colors.black,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': position.dx,
    'y': position.dy,
    'text': text,
    'size': fontSize,
    'col': color.value,
  };

  factory PlanLabel.fromJson(Map<String, dynamic> json) => PlanLabel(
    id: json['id'],
    position: Offset(json['x'], json['y']),
    text: json['text'],
    fontSize: (json['size'] as num?)?.toDouble() ?? 12.0,
    color: json['col'] != null ? Color(json['col']) : Colors.black,
  );

  PlanLabel copyWith({
    String? id,
    String? text,
    double? fontSize,
    Offset? position,
    Color? color,
  }) {
    return PlanLabel(
      id: id ?? this.id,
      position: position ?? this.position,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
    );
  }

  PlanLabel moveBy(Offset delta) => copyWith(position: position + delta);
}

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
    this.name = "Gambar",
    this.description = "",
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

  factory PlanPath.fromJson(Map<String, dynamic> json) => PlanPath(
    id: json['id'],
    points: (json['points'] as List)
        .map((p) => Offset(p['dx'], p['dy']))
        .toList(),
    color: Color(json['color']),
    strokeWidth: (json['width'] as num).toDouble(),
    name: json['name'] ?? "Gambar",
    description: json['desc'] ?? "",
    isSavedAsset: json['isSaved'] ?? false,
  );

  PlanPath copyWith({
    String? id,
    String? name,
    String? description,
    bool? isSavedAsset,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
  }) {
    return PlanPath(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      name: name ?? this.name,
      description: description ?? this.description,
      isSavedAsset: isSavedAsset ?? this.isSavedAsset,
    );
  }

  PlanPath moveBy(Offset delta) =>
      copyWith(points: points.map((p) => p + delta).toList());
}

class PlanShape {
  final String id;
  final Rect rect;
  final PlanShapeType type;
  final Color color;
  final bool isFilled;
  final double rotation;
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

  PlanShape moveBy(Offset delta) => copyWith(rect: rect.shift(delta));
}
