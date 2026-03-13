import 'dart:ui';

/// Stroke segment data for Ukrainian letter tracing.
/// Coordinates are normalised [0..1] relative to the letter INK BOUNDS.
class LetterSegments {
  static List<List<Offset>> getSegments(String character) {
    return _segments[character] ?? _defaultSegment();
  }

  static List<List<Offset>> _defaultSegment() => [
    [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
  ];

  static final Map<String, List<List<Offset>>> _segments = {
    // ═══ А ═══ crossbar at ~65%
    'А': [
      [const Offset(0.08, 0.95), const Offset(0.50, 0.05)],
      [const Offset(0.50, 0.05), const Offset(0.92, 0.95)],
      [const Offset(0.22, 0.65), const Offset(0.78, 0.65)],
    ],
    // ═══ а ═══ bowl first, then vertical
    'а': [
      [
        const Offset(0.68, 0.18),
        const Offset(0.42, 0.05),
        const Offset(0.15, 0.22),
        const Offset(0.08, 0.50),
        const Offset(0.15, 0.78),
        const Offset(0.42, 0.95),
        const Offset(0.68, 0.82),
      ],
      [const Offset(0.75, 0.05), const Offset(0.75, 0.95)],
    ],
    // ═══ Б ═══ (perfect)
    'Б': [
      [const Offset(0.15, 0.05), const Offset(0.85, 0.05)],
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [
        const Offset(0.15, 0.50),
        const Offset(0.70, 0.50),
        const Offset(0.85, 0.65),
        const Offset(0.85, 0.80),
        const Offset(0.70, 0.95),
        const Offset(0.15, 0.95),
      ],
    ],
    // ═══ б ═══ ascending stroke + bowl
    'б': [
      [
        const Offset(0.82, 0.05),
        const Offset(0.55, 0.15),
        const Offset(0.45, 0.32),
      ],
      [
        const Offset(0.45, 0.32),
        const Offset(0.22, 0.42),
        const Offset(0.12, 0.60),
        const Offset(0.15, 0.80),
        const Offset(0.35, 0.95),
        const Offset(0.60, 0.95),
        const Offset(0.80, 0.80),
        const Offset(0.82, 0.60),
        const Offset(0.75, 0.42),
        const Offset(0.45, 0.32),
      ],
    ],
    // ═══ В / в ═══ (perfect)
    'В': [
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [
        const Offset(0.15, 0.05),
        const Offset(0.65, 0.05),
        const Offset(0.80, 0.15),
        const Offset(0.80, 0.38),
        const Offset(0.65, 0.50),
        const Offset(0.15, 0.50),
      ],
      [
        const Offset(0.15, 0.50),
        const Offset(0.68, 0.50),
        const Offset(0.85, 0.62),
        const Offset(0.85, 0.82),
        const Offset(0.68, 0.95),
        const Offset(0.15, 0.95),
      ],
    ],
    'в': [
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [
        const Offset(0.15, 0.05),
        const Offset(0.60, 0.05),
        const Offset(0.78, 0.15),
        const Offset(0.78, 0.38),
        const Offset(0.60, 0.50),
        const Offset(0.15, 0.50),
      ],
      [
        const Offset(0.15, 0.50),
        const Offset(0.65, 0.50),
        const Offset(0.82, 0.62),
        const Offset(0.82, 0.82),
        const Offset(0.65, 0.95),
        const Offset(0.15, 0.95),
      ],
    ],
    // ═══ Г / г ═══ (perfect)
    'Г': [
      [const Offset(0.15, 0.05), const Offset(0.85, 0.05)],
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
    ],
    'г': [
      [const Offset(0.15, 0.05), const Offset(0.85, 0.05)],
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
    ],
    // ═══ Ґ / ґ ═══ vertical + horizontal with uptick
    'Ґ': [
      [const Offset(0.15, 0.95), const Offset(0.15, 0.05)],
      [
        const Offset(0.15, 0.05),
        const Offset(0.62, 0.05),
        const Offset(0.70, 0.00),
      ],
    ],
    'ґ': [
      [const Offset(0.15, 0.95), const Offset(0.15, 0.05)],
      [
        const Offset(0.15, 0.05),
        const Offset(0.62, 0.05),
        const Offset(0.70, 0.00),
      ],
    ],
    // ═══ Д / д ═══ left slant + top + right slant
    'Д': [
      [
        const Offset(0.08, 0.95),
        const Offset(0.08, 0.78),
        const Offset(0.28, 0.05),
      ],
      [const Offset(0.28, 0.05), const Offset(0.72, 0.05)],
      [
        const Offset(0.72, 0.05),
        const Offset(0.92, 0.78),
        const Offset(0.92, 0.95),
      ],
    ],
    'д': [
      [
        const Offset(0.08, 0.95),
        const Offset(0.08, 0.78),
        const Offset(0.28, 0.05),
      ],
      [const Offset(0.28, 0.05), const Offset(0.72, 0.05)],
      [
        const Offset(0.72, 0.05),
        const Offset(0.92, 0.78),
        const Offset(0.92, 0.95),
      ],
    ],
    // ═══ Е ═══ 4 segments: vertical + 3 horizontals
    'Е': [
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [const Offset(0.15, 0.05), const Offset(0.85, 0.05)],
      [const Offset(0.15, 0.50), const Offset(0.70, 0.50)],
      [const Offset(0.15, 0.95), const Offset(0.85, 0.95)],
    ],
    // ═══ е ═══ (perfect)
    'е': [
      [const Offset(0.15, 0.50), const Offset(0.85, 0.50)],
      [
        const Offset(0.85, 0.50),
        const Offset(0.85, 0.20),
        const Offset(0.55, 0.05),
        const Offset(0.20, 0.20),
        const Offset(0.15, 0.50),
        const Offset(0.20, 0.80),
        const Offset(0.55, 0.95),
        const Offset(0.85, 0.80),
      ],
    ],
    // ═══ Є / є ═══ longer C-curve
    'Є': [
      [
        const Offset(0.88, 0.08),
        const Offset(0.62, 0.02),
        const Offset(0.25, 0.10),
        const Offset(0.08, 0.35),
        const Offset(0.08, 0.65),
        const Offset(0.25, 0.90),
        const Offset(0.62, 0.98),
        const Offset(0.88, 0.92),
      ],
      [const Offset(0.08, 0.50), const Offset(0.62, 0.50)],
    ],
    'є': [
      [
        const Offset(0.88, 0.08),
        const Offset(0.62, 0.02),
        const Offset(0.25, 0.10),
        const Offset(0.08, 0.35),
        const Offset(0.08, 0.65),
        const Offset(0.25, 0.90),
        const Offset(0.62, 0.98),
        const Offset(0.88, 0.92),
      ],
      [const Offset(0.08, 0.50), const Offset(0.62, 0.50)],
    ],
    // ═══ Ж / ж ═══ adjusted diagonals
    'Ж': [
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
      [
        const Offset(0.05, 0.08),
        const Offset(0.46, 0.50),
        const Offset(0.05, 0.92),
      ],
      [
        const Offset(0.95, 0.08),
        const Offset(0.54, 0.50),
        const Offset(0.95, 0.92),
      ],
    ],
    'ж': [
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
      [
        const Offset(0.05, 0.08),
        const Offset(0.46, 0.50),
        const Offset(0.05, 0.92),
      ],
      [
        const Offset(0.95, 0.08),
        const Offset(0.54, 0.50),
        const Offset(0.95, 0.92),
      ],
    ],
    // ═══ З / з ═══ smoother curves
    'З': [
      [
        const Offset(0.18, 0.10),
        const Offset(0.42, 0.03),
        const Offset(0.68, 0.06),
        const Offset(0.82, 0.18),
        const Offset(0.82, 0.34),
        const Offset(0.68, 0.46),
        const Offset(0.50, 0.50),
      ],
      [
        const Offset(0.50, 0.50),
        const Offset(0.72, 0.54),
        const Offset(0.85, 0.68),
        const Offset(0.85, 0.82),
        const Offset(0.68, 0.94),
        const Offset(0.42, 0.97),
        const Offset(0.18, 0.90),
      ],
    ],
    'з': [
      [
        const Offset(0.18, 0.10),
        const Offset(0.42, 0.03),
        const Offset(0.68, 0.06),
        const Offset(0.82, 0.18),
        const Offset(0.82, 0.34),
        const Offset(0.68, 0.46),
        const Offset(0.50, 0.50),
      ],
      [
        const Offset(0.50, 0.50),
        const Offset(0.72, 0.54),
        const Offset(0.85, 0.68),
        const Offset(0.85, 0.82),
        const Offset(0.68, 0.94),
        const Offset(0.42, 0.97),
        const Offset(0.18, 0.90),
      ],
    ],
    // ═══ И / и ═══ (perfect)
    'И': [
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [const Offset(0.15, 0.95), const Offset(0.85, 0.05)],
      [const Offset(0.85, 0.05), const Offset(0.85, 0.95)],
    ],
    'и': [
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [const Offset(0.15, 0.95), const Offset(0.85, 0.05)],
      [const Offset(0.85, 0.05), const Offset(0.85, 0.95)],
    ],
    // ═══ І ═══ (perfect)
    'І': [
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
    ],
    // ═══ і ═══ vertical + dot
    'і': [
      [const Offset(0.50, 0.28), const Offset(0.50, 0.95)],
      [const Offset(0.50, 0.05), const Offset(0.50, 0.10)], // dot (quick tap)
    ],
    // ═══ Ї ═══ vertical + no dots needed for uppercase
    'Ї': [
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
    ],
    // ═══ ї ═══ vertical + 2 dots
    'ї': [
      [const Offset(0.50, 0.28), const Offset(0.50, 0.95)],
      [const Offset(0.35, 0.05), const Offset(0.35, 0.10)], // left dot
      [const Offset(0.65, 0.05), const Offset(0.65, 0.10)], // right dot
    ],
    // ═══ Й / й ═══ body below breve + breve as 4th stroke
    'Й': [
      [const Offset(0.15, 0.22), const Offset(0.15, 0.95)],
      [const Offset(0.15, 0.95), const Offset(0.85, 0.22)],
      [const Offset(0.85, 0.22), const Offset(0.85, 0.95)],
      [
        const Offset(0.35, 0.08),
        const Offset(0.50, 0.16),
        const Offset(0.65, 0.08),
      ], // breve
    ],
    'й': [
      [const Offset(0.15, 0.22), const Offset(0.15, 0.95)],
      [const Offset(0.15, 0.95), const Offset(0.85, 0.22)],
      [const Offset(0.85, 0.22), const Offset(0.85, 0.95)],
      [
        const Offset(0.35, 0.08),
        const Offset(0.50, 0.16),
        const Offset(0.65, 0.08),
      ], // breve
    ],
    // ═══ К / к ═══ extended arms to cover full letter
    'К': [
      [const Offset(0.12, 0.05), const Offset(0.12, 0.95)],
      [const Offset(0.88, 0.02), const Offset(0.15, 0.50)],
      [const Offset(0.15, 0.50), const Offset(0.88, 0.98)],
    ],
    'к': [
      [const Offset(0.12, 0.05), const Offset(0.12, 0.95)],
      [const Offset(0.88, 0.02), const Offset(0.15, 0.50)],
      [const Offset(0.15, 0.50), const Offset(0.88, 0.98)],
    ],
    // ═══ Л / л ═══ rounded arch (Nunito style)
    'Л': [
      [
        const Offset(0.05, 0.95),
        const Offset(0.10, 0.30),
        const Offset(0.30, 0.08),
        const Offset(0.50, 0.05),
      ],
      [const Offset(0.50, 0.05), const Offset(0.88, 0.05)],
      [const Offset(0.88, 0.05), const Offset(0.88, 0.95)],
    ],
    'л': [
      [
        const Offset(0.05, 0.95),
        const Offset(0.10, 0.30),
        const Offset(0.30, 0.08),
        const Offset(0.50, 0.05),
      ],
      [const Offset(0.50, 0.05), const Offset(0.88, 0.05)],
      [const Offset(0.88, 0.05), const Offset(0.88, 0.95)],
    ],
    // ═══ М / м ═══ V goes deeper (matches Nunito)
    'М': [
      [const Offset(0.05, 0.95), const Offset(0.05, 0.05)],
      [
        const Offset(0.05, 0.05),
        const Offset(0.50, 0.68),
        const Offset(0.95, 0.05),
      ],
      [const Offset(0.95, 0.05), const Offset(0.95, 0.95)],
    ],
    'м': [
      [const Offset(0.05, 0.95), const Offset(0.05, 0.05)],
      [
        const Offset(0.05, 0.05),
        const Offset(0.50, 0.68),
        const Offset(0.95, 0.05),
      ],
      [const Offset(0.95, 0.05), const Offset(0.95, 0.95)],
    ],
    // ═══ Н / н ═══ (perfect)
    'Н': [
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [const Offset(0.15, 0.50), const Offset(0.85, 0.50)],
      [const Offset(0.85, 0.05), const Offset(0.85, 0.95)],
    ],
    'н': [
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [const Offset(0.15, 0.50), const Offset(0.85, 0.50)],
      [const Offset(0.85, 0.05), const Offset(0.85, 0.95)],
    ],
    // ═══ О / о ═══ single full circle (distance check prevents auto-complete)
    'О': [
      [
        const Offset(0.50, 0.02),
        const Offset(0.25, 0.08),
        const Offset(0.08, 0.25),
        const Offset(0.03, 0.50),
        const Offset(0.08, 0.75),
        const Offset(0.25, 0.92),
        const Offset(0.50, 0.98),
        const Offset(0.75, 0.92),
        const Offset(0.92, 0.75),
        const Offset(0.97, 0.50),
        const Offset(0.92, 0.25),
        const Offset(0.75, 0.08),
        const Offset(0.50, 0.02),
      ],
    ],
    'о': [
      [
        const Offset(0.50, 0.02),
        const Offset(0.25, 0.08),
        const Offset(0.08, 0.25),
        const Offset(0.03, 0.50),
        const Offset(0.08, 0.75),
        const Offset(0.25, 0.92),
        const Offset(0.50, 0.98),
        const Offset(0.75, 0.92),
        const Offset(0.92, 0.75),
        const Offset(0.97, 0.50),
        const Offset(0.92, 0.25),
        const Offset(0.75, 0.08),
        const Offset(0.50, 0.02),
      ],
    ],
    // ═══ П / п ═══ (perfect)
    'П': [
      [const Offset(0.15, 0.95), const Offset(0.15, 0.05)],
      [const Offset(0.15, 0.05), const Offset(0.85, 0.05)],
      [const Offset(0.85, 0.05), const Offset(0.85, 0.95)],
    ],
    'п': [
      [const Offset(0.15, 0.95), const Offset(0.15, 0.05)],
      [const Offset(0.15, 0.05), const Offset(0.85, 0.05)],
      [const Offset(0.85, 0.05), const Offset(0.85, 0.95)],
    ],
    // ═══ Р ═══ (nearly perfect)
    'Р': [
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [
        const Offset(0.15, 0.05),
        const Offset(0.65, 0.05),
        const Offset(0.85, 0.15),
        const Offset(0.85, 0.38),
        const Offset(0.65, 0.50),
        const Offset(0.15, 0.50),
      ],
    ],
    // ═══ р ═══ fixed bump position for lowercase (has descender)
    'р': [
      [const Offset(0.18, 0.00), const Offset(0.18, 0.95)],
      [
        const Offset(0.18, 0.00),
        const Offset(0.55, 0.00),
        const Offset(0.78, 0.10),
        const Offset(0.82, 0.25),
        const Offset(0.78, 0.38),
        const Offset(0.55, 0.45),
        const Offset(0.18, 0.45),
      ],
    ],
    // ═══ С / с ═══ fully extended C-curve
    'С': [
      [
        const Offset(0.92, 0.06),
        const Offset(0.65, 0.00),
        const Offset(0.25, 0.08),
        const Offset(0.05, 0.35),
        const Offset(0.05, 0.65),
        const Offset(0.25, 0.92),
        const Offset(0.65, 1.00),
        const Offset(0.92, 0.94),
      ],
    ],
    'с': [
      [
        const Offset(0.92, 0.06),
        const Offset(0.65, 0.00),
        const Offset(0.25, 0.08),
        const Offset(0.05, 0.35),
        const Offset(0.05, 0.65),
        const Offset(0.25, 0.92),
        const Offset(0.65, 1.00),
        const Offset(0.92, 0.94),
      ],
    ],
    // ═══ Т / т ═══ vertical FIRST, then horizontal
    'Т': [
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
      [const Offset(0.05, 0.05), const Offset(0.95, 0.05)],
    ],
    'т': [
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
      [const Offset(0.05, 0.05), const Offset(0.95, 0.05)],
    ],
    // ═══ У / у ═══ adjusted arms
    'У': [
      [const Offset(0.08, 0.05), const Offset(0.48, 0.52)],
      [
        const Offset(0.90, 0.05),
        const Offset(0.48, 0.52),
        const Offset(0.32, 0.95),
      ],
    ],
    'у': [
      [const Offset(0.08, 0.05), const Offset(0.48, 0.52)],
      [
        const Offset(0.90, 0.05),
        const Offset(0.48, 0.52),
        const Offset(0.32, 0.95),
      ],
    ],
    // ═══ Ф / ф ═══ vertical + 2 half-circles
    'Ф': [
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
      [
        const Offset(0.50, 0.22),
        const Offset(0.30, 0.25),
        const Offset(0.12, 0.38),
        const Offset(0.08, 0.50),
        const Offset(0.12, 0.62),
        const Offset(0.30, 0.75),
        const Offset(0.50, 0.78),
      ],
      [
        const Offset(0.50, 0.22),
        const Offset(0.70, 0.25),
        const Offset(0.88, 0.38),
        const Offset(0.92, 0.50),
        const Offset(0.88, 0.62),
        const Offset(0.70, 0.75),
        const Offset(0.50, 0.78),
      ],
    ],
    'ф': [
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
      [
        const Offset(0.50, 0.22),
        const Offset(0.30, 0.25),
        const Offset(0.12, 0.38),
        const Offset(0.08, 0.50),
        const Offset(0.12, 0.62),
        const Offset(0.30, 0.75),
        const Offset(0.50, 0.78),
      ],
      [
        const Offset(0.50, 0.22),
        const Offset(0.70, 0.25),
        const Offset(0.88, 0.38),
        const Offset(0.92, 0.50),
        const Offset(0.88, 0.62),
        const Offset(0.70, 0.75),
        const Offset(0.50, 0.78),
      ],
    ],
    // ═══ Х / х ═══ (nearly perfect)
    'Х': [
      [const Offset(0.10, 0.05), const Offset(0.90, 0.95)],
      [const Offset(0.90, 0.05), const Offset(0.10, 0.95)],
    ],
    'х': [
      [const Offset(0.10, 0.05), const Offset(0.90, 0.95)],
      [const Offset(0.90, 0.05), const Offset(0.10, 0.95)],
    ],
    // ═══ Ц / ц ═══ left vert + right vert + bottom bar with tail
    'Ц': [
      [const Offset(0.10, 0.02), const Offset(0.10, 0.78)],
      [const Offset(0.72, 0.02), const Offset(0.72, 0.78)],
      [
        const Offset(0.10, 0.78),
        const Offset(0.80, 0.78),
        const Offset(0.88, 0.98),
      ],
    ],
    'ц': [
      [const Offset(0.10, 0.02), const Offset(0.10, 0.78)],
      [const Offset(0.72, 0.02), const Offset(0.72, 0.78)],
      [
        const Offset(0.10, 0.78),
        const Offset(0.80, 0.78),
        const Offset(0.88, 0.98),
      ],
    ],
    // ═══ Ч / ч ═══ adjusted hook
    'Ч': [
      [
        const Offset(0.15, 0.05),
        const Offset(0.15, 0.38),
        const Offset(0.32, 0.50),
        const Offset(0.82, 0.50),
      ],
      [const Offset(0.82, 0.05), const Offset(0.82, 0.95)],
    ],
    'ч': [
      [
        const Offset(0.15, 0.05),
        const Offset(0.15, 0.38),
        const Offset(0.32, 0.50),
        const Offset(0.82, 0.50),
      ],
      [const Offset(0.82, 0.05), const Offset(0.82, 0.95)],
    ],
    // ═══ Ш / ш ═══ 4 segments, all top-to-bottom consistent
    'Ш': [
      [const Offset(0.08, 0.05), const Offset(0.08, 0.95)],
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
      [const Offset(0.92, 0.05), const Offset(0.92, 0.95)],
      [const Offset(0.08, 0.95), const Offset(0.92, 0.95)],
    ],
    'ш': [
      [const Offset(0.08, 0.05), const Offset(0.08, 0.95)],
      [const Offset(0.50, 0.05), const Offset(0.50, 0.95)],
      [const Offset(0.92, 0.05), const Offset(0.92, 0.95)],
      [const Offset(0.08, 0.95), const Offset(0.92, 0.95)],
    ],
    // ═══ Щ / щ ═══ 4 segments like Ш + tail
    'Щ': [
      [const Offset(0.06, 0.02), const Offset(0.06, 0.78)],
      [const Offset(0.40, 0.02), const Offset(0.40, 0.78)],
      [const Offset(0.74, 0.02), const Offset(0.74, 0.78)],
      [
        const Offset(0.06, 0.78),
        const Offset(0.80, 0.78),
        const Offset(0.88, 0.98),
      ],
    ],
    'щ': [
      [const Offset(0.06, 0.02), const Offset(0.06, 0.78)],
      [const Offset(0.40, 0.02), const Offset(0.40, 0.78)],
      [const Offset(0.74, 0.02), const Offset(0.74, 0.78)],
      [
        const Offset(0.06, 0.78),
        const Offset(0.80, 0.78),
        const Offset(0.88, 0.98),
      ],
    ],
    // ═══ Ь ═══ (OK)
    'Ь': [
      [const Offset(0.15, 0.05), const Offset(0.15, 0.95)],
      [
        const Offset(0.15, 0.50),
        const Offset(0.68, 0.50),
        const Offset(0.85, 0.62),
        const Offset(0.85, 0.82),
        const Offset(0.68, 0.95),
        const Offset(0.15, 0.95),
      ],
    ],
    // ═══ Ю / ю ═══ vertical + connector + full circle
    'Ю': [
      [const Offset(0.08, 0.05), const Offset(0.08, 0.95)],
      [const Offset(0.08, 0.50), const Offset(0.32, 0.50)],
      [
        const Offset(0.58, 0.04),
        const Offset(0.40, 0.12),
        const Offset(0.28, 0.30),
        const Offset(0.25, 0.50),
        const Offset(0.28, 0.70),
        const Offset(0.40, 0.88),
        const Offset(0.58, 0.96),
        const Offset(0.76, 0.88),
        const Offset(0.88, 0.70),
        const Offset(0.92, 0.50),
        const Offset(0.88, 0.30),
        const Offset(0.76, 0.12),
        const Offset(0.58, 0.04),
      ],
    ],
    'ю': [
      [const Offset(0.08, 0.05), const Offset(0.08, 0.95)],
      [const Offset(0.08, 0.50), const Offset(0.32, 0.50)],
      [
        const Offset(0.58, 0.04),
        const Offset(0.40, 0.12),
        const Offset(0.28, 0.30),
        const Offset(0.25, 0.50),
        const Offset(0.28, 0.70),
        const Offset(0.40, 0.88),
        const Offset(0.58, 0.96),
        const Offset(0.76, 0.88),
        const Offset(0.88, 0.70),
        const Offset(0.92, 0.50),
        const Offset(0.88, 0.30),
        const Offset(0.76, 0.12),
        const Offset(0.58, 0.04),
      ],
    ],
    // ═══ Я / я ═══ (perfect)
    'Я': [
      [const Offset(0.85, 0.05), const Offset(0.85, 0.95)],
      [
        const Offset(0.85, 0.05),
        const Offset(0.35, 0.05),
        const Offset(0.15, 0.15),
        const Offset(0.15, 0.38),
        const Offset(0.35, 0.50),
        const Offset(0.85, 0.50),
      ],
      [const Offset(0.50, 0.50), const Offset(0.15, 0.95)],
    ],
    'я': [
      [const Offset(0.85, 0.05), const Offset(0.85, 0.95)],
      [
        const Offset(0.85, 0.05),
        const Offset(0.35, 0.05),
        const Offset(0.15, 0.15),
        const Offset(0.15, 0.38),
        const Offset(0.35, 0.50),
        const Offset(0.85, 0.50),
      ],
      [const Offset(0.50, 0.50), const Offset(0.15, 0.95)],
    ],
  };
}
