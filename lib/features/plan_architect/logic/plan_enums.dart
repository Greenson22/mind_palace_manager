// lib/features/plan_architect/logic/plan_enums.dart
enum PlanTool {
  select,
  wall,
  object,
  text,
  eraser,
  freehand,
  shape,
  hand,
  moveAll,
  door,
  window,
}

enum PlanPortalType { door, window }

// --- UPDATE: Penambahan 50+ Bentuk Baru ---
enum PlanShapeType {
  // 1. Basic
  rectangle,
  roundedRect,
  circle,
  triangle,
  rightTriangle, // Segitiga Siku
  diamond, // Belah Ketupat
  parallelogram, // Jajar Genjang
  trapezoid, // Trapesium
  // 2. Polygons
  pentagon,
  hexagon,
  heptagon,
  octagon,
  decagon, // Segi 10
  // 3. Stars & Symbols
  star,
  star4, // Bintang 4 titik
  star6,
  star8,
  heart,
  moon,
  sun,
  cloud,
  cross, // Palang
  check, // Ceklis
  xMark, // Silang
  // 4. Arrows (Penunjuk Arah)
  arrowUp,
  arrowRight,
  arrowDown,
  arrowLeft,
  doubleArrowH,
  doubleArrowV,
  chevronUp,
  chevronRight,
  blockArrowRight,
  curvedArrowRight,

  // 5. Architectural / Structural (Denah)
  lShape, // Sudut L
  uShape, // Ruangan U
  tShape, // Pertigaan
  plusShape, // Perempatan
  stairs, // Tangga sederhana
  columnRound, // Pilar bulat
  columnSquare, // Pilar kotak
  iBeam, // Baja I
  arc, // Lengkungan
  // 6. Flowchart / Abstract
  process, // Kotak
  decision, // Wajik
  document, // Kertas bergelombang
  database, // Tabung
  manualInput,
  display,

  // 7. Speech Bubbles
  bubbleRound,
  bubbleSquare,
  thoughtBubble,
}
