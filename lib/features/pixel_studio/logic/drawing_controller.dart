// lib/features/pixel_studio/logic/drawing_controller.dart
import 'dart:ui';
import 'package:flutter/material.dart';

enum DrawingTool { pencil, eraser, hand }

class DrawingController extends ChangeNotifier {
  // Konfigurasi Kanvas
  final int gridSize = 32; // Ukuran kanvas 32x32 piksel

  // Data Piksel: Key = "x_y", Value = Warna
  final Map<String, Color> _pixels = {};

  // State saat ini
  Color _activeColor = Colors.black;
  DrawingTool _activeTool = DrawingTool.pencil;

  // Getter
  Map<String, Color> get pixels => _pixels;
  Color get activeColor => _activeColor;
  DrawingTool get activeTool => _activeTool;
  int get pixelCount => gridSize;

  // Ganti Alat
  void setTool(DrawingTool tool) {
    _activeTool = tool;
    notifyListeners();
  }

  // Ganti Warna
  void setColor(Color color) {
    _activeColor = color;
    // Jika ganti warna, otomatis pindah ke pensil
    if (_activeTool != DrawingTool.pencil) {
      _activeTool = DrawingTool.pencil;
    }
    notifyListeners();
  }

  // Fungsi Gambar Utama
  void drawPixel(Offset localPosition, Size canvasSize) {
    if (_activeTool == DrawingTool.hand) return;

    // Hitung ukuran satu blok piksel berdasarkan ukuran layar saat ini
    final double pixelSize = canvasSize.width / gridSize;

    // Konversi koordinat sentuh (px layar) ke koordinat grid (0-31)
    int x = (localPosition.dx / pixelSize).floor();
    int y = (localPosition.dy / pixelSize).floor();

    // Validasi batas grid
    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      String key = "${x}_$y";

      if (_activeTool == DrawingTool.eraser) {
        if (_pixels.containsKey(key)) {
          _pixels.remove(key);
          notifyListeners();
        }
      } else {
        // Optimize: Jangan redraw jika warna sama
        if (_pixels[key] != _activeColor) {
          _pixels[key] = _activeColor;
          notifyListeners();
        }
      }
    }
  }

  // Hapus Semua (Opsional untuk New Project)
  void clearCanvas() {
    _pixels.clear();
    notifyListeners();
  }
}
