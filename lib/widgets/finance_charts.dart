import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/money.dart';
import '../services/analytics_service.dart';

const chartColors = [
  Color(0xff00ab6b),
  Color(0xffa18ce8),
  Color(0xff529cd7),
  Color(0xffffbd59),
  Color(0xffff7285),
  Color(0xff47cddd),
  Color(0xffcf9d76),
];

final class ChartLine {
  const ChartLine(this.label, this.values, this.color);
  final String label;
  final List<Money?> values;
  final Color color;
}

String compactMoney(BigInt minor) {
  final n = minor.abs();
  final sign = minor.isNegative ? '-' : '';
  for (final (base, label) in [
    (100000000000000, 'T'),
    (100000000000, 'M'),
    (100000000, 'jt'),
    (100000, 'rb'),
  ]) {
    if (n >= BigInt.from(base)) {
      final tenth = (n * BigInt.from(10)) ~/ BigInt.from(base);
      return '$sign${tenth ~/ BigInt.from(10)}${tenth % BigInt.from(10) == BigInt.zero ? '' : ',${tenth % BigInt.from(10)}'}$label';
    }
  }
  return '$sign${n ~/ BigInt.from(100)}';
}

class FinanceLineChart extends StatefulWidget {
  const FinanceLineChart({
    super.key,
    required this.dates,
    required this.lines,
    this.formatValue,
    this.formatAxis,
    this.compact = false,
  });
  final bool compact;
  final List<String> dates;
  final List<ChartLine> lines;
  final String Function(Money)? formatValue;
  final String Function(BigInt)? formatAxis;
  @override
  State<FinanceLineChart> createState() => _FinanceLineChartState();
}

class _FinanceLineChartState extends State<FinanceLineChart> {
  int? selected;
  @override
  void didUpdateWidget(covariant FinanceLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dates != widget.dates) selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.dates;
    if (dates.isEmpty) {
      return const Text('Belum ada riwayat untuk periode ini.');
    }
    final n = (selected ?? dates.length - 1).clamp(0, dates.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (ctx, size) {
            void select(double x) => setState(
              () => selected =
                  (((x - 62) / math.max(1, size.maxWidth - 74)) *
                          (dates.length - 1))
                      .round()
                      .clamp(0, dates.length - 1),
            );
            return Semantics(
              label: 'Grafik garis. Ketuk atau geser untuk memilih tanggal.',
              child: GestureDetector(
                key: const Key('finance-line-chart'),
                onTapDown: (d) => select(d.localPosition.dx),
                onHorizontalDragUpdate: (d) => select(d.localPosition.dx),
                child: SizedBox(
                  height: widget.compact ? 140 : 220,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _LinePainter(
                      dates,
                      widget.lines,
                      n,
                      Theme.of(ctx).colorScheme.onSurfaceVariant,
                      Theme.of(ctx).colorScheme.outlineVariant,
                      Directionality.of(ctx),
                      widget.formatAxis,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (!widget.compact)
          Text(dates[n], style: Theme.of(context).textTheme.labelLarge),
        for (final line in widget.lines)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: line.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${line.label}: ${line.values[n] == null ? 'Data belum lengkap' : widget.formatValue?.call(line.values[n]!) ?? line.values[n]!.formatted}',
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (!widget.compact)
          const Text(
            'Ketuk atau geser grafik untuk melihat nilai tanggal tertentu.',
          ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(
    this.dates,
    this.lines,
    this.selected,
    this.textColor,
    this.gridColor,
    this.direction,
    this.formatAxis,
  );
  final List<String> dates;
  final List<ChartLine> lines;
  final int selected;
  final Color textColor, gridColor;
  final TextDirection direction;
  final String Function(BigInt)? formatAxis;
  @override
  void paint(Canvas canvas, Size size) {
    final values = lines
        .expand((l) => l.values)
        .whereType<Money>()
        .map((m) => m.minor)
        .toList();
    if (values.isEmpty || dates.isEmpty) return;
    var low = values.first, high = values.first;
    for (final v in values) {
      if (v < low) low = v;
      if (v > high) high = v;
    }
    if (low == high) {
      low -= BigInt.from(100);
      high += BigInt.from(100);
    }
    final rect = Rect.fromLTRB(62, 12, size.width - 12, size.height - 28);
    double x(int i) => dates.length == 1
        ? rect.center.dx
        : rect.left + rect.width * i / (dates.length - 1);
    double y(BigInt v) =>
        rect.bottom -
        ((v - low) * BigInt.from(10000) ~/ (high - low)).toInt() /
            10000 *
            rect.height;
    void text(String s, Offset at, {bool right = false}) {
      final p = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: 'BitSans',
            fontSize: 10,
            color: textColor,
          ),
        ),
        textDirection: direction,
      )..layout();
      p.paint(canvas, Offset(right ? at.dx - p.width : at.dx, at.dy));
    }

    for (var i = 0; i <= 4; i++) {
      final value = low + (high - low) * BigInt.from(i) ~/ BigInt.from(4);
      canvas.drawLine(
        Offset(rect.left, y(value)),
        Offset(rect.right, y(value)),
        Paint()
          ..color = gridColor
          ..strokeWidth = .6,
      );
      text(
        formatAxis?.call(value) ?? compactMoney(value),
        Offset(rect.left - 7, y(value) - 6),
        right: true,
      );
    }
    text(dates.first.substring(5), Offset(rect.left, rect.bottom + 8));
    text(
      dates.last.substring(5),
      Offset(rect.right, rect.bottom + 8),
      right: true,
    );
    canvas.drawLine(
      Offset(x(selected), rect.top),
      Offset(x(selected), rect.bottom),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );
    for (final line in lines) {
      final path = Path();
      var drawing = false;
      for (var i = 0; i < line.values.length; i++) {
        final value = line.values[i];
        if (value == null) {
          drawing = false;
          continue;
        }
        final point = Offset(x(i), y(value.minor));
        if (!drawing) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
        drawing = true;
        if (i == selected ||
            line.values.length == 1 ||
            (i > 0 && line.values[i - 1] == null) ||
            (i + 1 < line.values.length && line.values[i + 1] == null)) {
          canvas.drawCircle(point, 3.5, Paint()..color = line.color);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.lines != lines ||
      old.selected != selected ||
      old.gridColor != gridColor ||
      old.textColor != textColor;
}

class FinanceDonutChart extends StatefulWidget {
  const FinanceDonutChart({super.key, required this.composition});
  final AssetComposition composition;
  @override
  State<FinanceDonutChart> createState() => _FinanceDonutChartState();
}

class _FinanceDonutChartState extends State<FinanceDonutChart> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    final c = widget.composition;
    // Keep small slices legible without dropping them from the total.
    final rows = c.positive.length > 7
        ? [
            ...c.positive.take(6),
            AssetSlice(
              'Lainnya (${c.positive.length - 6})',
              c.positive.skip(6).fold(Money.zero, (s, v) => s + v.value),
            ),
          ]
        : c.positive;
    final total = c.positiveTotal;
    final index = selected != null && selected! < rows.length ? selected : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isNotEmpty)
          Center(
            child: GestureDetector(
              key: const Key('finance-donut-chart'),
              onTapUp: (d) {
                final dx = d.localPosition.dx - 100,
                    dy = d.localPosition.dy - 100;
                final radius = math.sqrt(dx * dx + dy * dy);
                if (radius < 66 || radius > 96) return;
                var angle = math.atan2(dy, dx) + math.pi / 2;
                if (angle < 0) angle += math.pi * 2;
                var cumulative = 0.0;
                for (var i = 0; i < rows.length; i++) {
                  cumulative +=
                      (rows[i].value.minor *
                              BigInt.from(1000000) ~/
                              total.minor)
                          .toInt() /
                      1000000 *
                      math.pi *
                      2;
                  if (angle <= cumulative || i == rows.length - 1) {
                    setState(() => selected = i);
                    break;
                  }
                }
              },
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DonutPainter(rows, total, index),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(42),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 116,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                index == null
                                    ? 'Aset positif'
                                    : rows[index].label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                compactMoney(
                                  (index == null ? total : rows[index].value)
                                      .minor,
                                ),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Text('IDR'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          const Text(
            'Belum ada saldo positif yang dapat ditampilkan dalam donut.',
          ),
        for (var i = 0; i < rows.length; i++)
          InkWell(
            onTap: () => setState(() => selected = selected == i ? null : i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 5),
                    color: chartColors[i % chartColors.length],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${rows[i].label}\n${rows[i].value.formatted} · ${(rows[i].value.minor * BigInt.from(1000) ~/ total.minor).toInt() / 10}%',
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (c.negative.isNotEmpty) ...[
          const Divider(),
          const Text(
            'Saldo negatif / utang (pengurang kekayaan, di luar donut)',
          ),
          for (final row in c.negative)
            Text('${row.label}: ${row.value.formatted}'),
        ],
        Text('Nilai bersih terhitung: ${c.net.formatted}'),
        if (c.missing > 0)
          Text(
            '${c.missing} aset/posisi belum memiliki harga atau kurs. Komposisi belum lengkap.',
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.rows, this.total, this.selected);
  final List<AssetSlice> rows;
  final Money total;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    if (total.isZero) return;
    var start = -math.pi / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 80);
    for (var i = 0; i < rows.length; i++) {
      final sweep =
          (rows[i].value.minor * BigInt.from(1000000) ~/ total.minor).toInt() /
          1000000 *
          math.pi *
          2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = chartColors[i % chartColors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = (selected == i ? 30 : 24),
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.rows != rows || old.selected != selected;
}
