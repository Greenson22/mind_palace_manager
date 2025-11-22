// lib/features/pixel_studio/logic/drawing_controller.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

enum DrawingTool { pencil, eraser, hand, line, rectangle, circle }

class DrawingController extends ChangeNotifier {
  // Konfigurasi Kanvas
  final int gridSize = 32;

  // Data Piksel Utama: Key = "x_y", Value = Warna
  Map<String, Color> _pixels = {};

  // Layer Preview (Untuk melihat bentuk sebelum dilepas jari)
  Map<String, Color> _previewPixels = {};

  // History untuk Undo/Redo
  final List<Map<String, Color>> _history = [];
  int _historyIndex = -1;

  // State saat ini
  Color _activeColor = Colors.black;
  DrawingTool _activeTool = DrawingTool.pencil;
  Offset? _startDragPos; // Posisi awal sentuhan untuk bentuk

  // Getter
  Map<String, Color> get pixels => _pixels;
  Map<String, Color> get previewPixels => _previewPixels;
  Color get activeColor => _activeColor;
  DrawingTool get activeTool => _activeTool;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  DrawingController() {
    // Simpan state awal kosong
    _saveState();
  }

  // --- MANAJEMEN STATE (UNDO/REDO) ---

  void _saveState() {
    // Hapus history di depan jika kita melakukan aksi baru setelah undo
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    // Simpan copy dari pixels saat ini
    _history.add(Map.from(_pixels));
    _historyIndex++;

    // Batasi history max 50 langkah untuk hemat memori
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
    notifyListeners();
  }

  void undo() {
    if (canUndo) {
      _historyIndex--;
      _pixels = Map.from(_history[_historyIndex]);
      notifyListeners();
    }
  }

  void redo() {
    if (canRedo) {
      _historyIndex++;
      _pixels = Map.from(_history[_historyIndex]);
      notifyListeners();
    }
  }

  // --- MANAJEMEN ALAT ---

  void setTool(DrawingTool tool) {
    _activeTool = tool;
    _previewPixels.clear();
    notifyListeners();
  }

  void setColor(Color color) {
    _activeColor = color;
    if (_activeTool == DrawingTool.eraser || _activeTool == DrawingTool.hand) {
      _activeTool = DrawingTool.pencil;
    }
    notifyListeners();
  }

  // --- CORE DRAWING ENGINE ---

  // 1. Saat Jari Mulai Menyentuh (OnPanStart)
  void startStroke(Offset localPosition, Size canvasSize) {
    if (_activeTool == DrawingTool.hand) return;

    final point = _getGridCoord(localPosition, canvasSize);
    if (point == null) return;

    _startDragPos = point; // Simpan titik awal

    if (_isShapeTool()) {
      // Jika tool bentuk, jangan gambar ke _pixels dulu, tapi siapkan preview
      _previewPixels.clear();
    } else {
      // Jika pensil/penghapus, langsung gambar dan simpan state nanti
      _drawDirect(point);
    }
  }

  // 2. Saat Jari Bergerak (OnPanUpdate)
  void updateStroke(Offset localPosition, Size canvasSize) {
    if (_activeTool == DrawingTool.hand) return;

    final point = _getGridCoord(localPosition, canvasSize);
    if (point == null) return;

    if (_isShapeTool() && _startDragPos != null) {
      // Hitung bentuk di layer preview
      _calculateShape(_startDragPos!, point);
    } else {
      // Gambar langsung (Pensil/Penghapus)
      _drawDirect(point);
    }
  }

  // 3. Saat Jari Diangkat (OnPanEnd)
  void endStroke() {
    if (_activeTool == DrawingTool.hand) return;

    if (_isShapeTool()) {
      // Commit preview ke layer utama
      _pixels.addAll(_previewPixels);
      _previewPixels.clear();
    }

    _startDragPos = null;
    _saveState(); // Simpan langkah ini ke history
  }

  // --- HELPER FUNGSI ---

  bool _isShapeTool() {
    return _activeTool == DrawingTool.line ||
        _activeTool == DrawingTool.rectangle ||
        _activeTool == DrawingTool.circle;
  }

  Offset? _getGridCoord(Offset local, Size size) {
    final double pixelSize = size.width / gridSize;
    int x = (local.dx / pixelSize).floor();
    int y = (local.dy / pixelSize).floor();
    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      return Offset(x.toDouble(), y.toDouble());
    }
    return null;
  }

  void _drawDirect(Offset point) {
    String key = "${point.dx.toInt()}_${point.dy.toInt()}";
    if (_activeTool == DrawingTool.eraser) {
      if (_pixels.containsKey(key)) {
        _pixels.remove(key);
        notifyListeners();
      }
    } else {
      if (_pixels[key] != _activeColor) {
        _pixels[key] = _activeColor;
        notifyListeners();
      }
    }
  }

  // --- ALGORITMA BENTUK ---

  void _calculateShape(Offset start, Offset end) {
    _previewPixels.clear();
    List<Point<int>> points = [];

    int x0 = start.dx.toInt();
    int y0 = start.dy.toInt();
    int x1 = end.dx.toInt();
    int y1 = end.dy.toInt();

    switch (_activeTool) {
      case DrawingTool.line:
        points = _getBresenhamLine(x0, y0, x1, y1);
        break;
      case DrawingTool.rectangle:
        points = _getRectangle(x0, y0, x1, y1);
        break;
      case DrawingTool.circle:
        points = _getCircle(x0, y0, x1, y1);
        break;
      default:
        break;
    }

    for (var p in points) {
      if (p.x >= 0 && p.x < gridSize && p.y >= 0 && p.y < gridSize) {
        _previewPixels["${p.x}_${p.y}"] = _activeColor;
      }
    }
    notifyListeners();
  }

  // Algoritma Garis Bresenham
  List<Point<int>> _getBresenhamLine(int x0, int y0, int x1, int y1) {
    List<Point<int>> points = [];
    int dx = (x1 - x0).abs();
    int dy = -(y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    while (true) {
      points.add(Point(x0, y0));
      if (x0 == x1 && y0 == y1) break;
      int e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }
    }
    return points;
  }

  // Algoritma Kotak (Outline)
  List<Point<int>> _getRectangle(int x0, int y0, int x1, int y1) {
    List<Point<int>> points = [];
    int minX = min(x0, x1);
    int maxX = max(x0, x1);
    int minY = min(y0, y1);
    int maxY = max(y0, y1);

    // Garis Horizontal
    for (int x = minX; x <= maxX; x++) {
      points.add(Point(x, minY));
      points.add(Point(x, maxY));
    }
    // Garis Vertikal
    for (int y = minY; y <= maxY; y++) {
      points.add(Point(minX, y));
      points.add(Point(maxX, y));
    }
    return points;
  }

  // Algoritma Lingkaran (Bresenham / Midpoint)
  List<Point<int>> _getCircle(int x0, int y0, int x1, int y1) {
    List<Point<int>> points = [];
    // Gunakan jarak sebagai radius
    int r = sqrt(pow(x1 - x0, 2) + pow(y1 - y0, 2)).round();
    int x = 0;
    int y = r;
    int d = 3 - 2 * r;

    _addCirclePoints(x0, y0, x, y, points);
    while (y >= x) {
      x++;
      if (d > 0) {
        y--;
        d = d + 4 * (x - y) + 10;
      } else {
        d = d + 4 * x + 6;
      }
      _addCirclePoints(x0, y0, x, y, points);
    }
    return points;
  }

  void _addCirclePoints(int xc, int yc, int x, int y, List<Point<int>> points) {
    points.addAll([
      Point(xc + x, yc + y),
      Point(xc - x, yc + y),
      Point(xc + x, yc - y),
      Point(xc - x, yc - y),
      Point(xc + y, yc + x),
      Point(xc - y, yc + x),
      Point(xc + y, yc - x),
      Point(xc - y, yc - x),
    ]);
  }
}
