import 'package:flutter/material.dart';
import '../models/weather.dart';

class ForecastChart extends StatelessWidget {
  const ForecastChart({super.key, required this.days});
  final List<ForecastDay> days;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Temperaturas',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43))),
            const SizedBox(height: 4),
            const Text('Mínima e máxima • °C',
                style: TextStyle(color: Color(0xFF627D98), fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
                height: 190,
                child: CustomPaint(
                    size: Size.infinite, painter: _TemperaturePainter(days))),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.circle, size: 9, color: Color(0xFF167D8D)),
              SizedBox(width: 5),
              Text('Máxima', style: TextStyle(fontSize: 11)),
              SizedBox(width: 16),
              Icon(Icons.circle, size: 9, color: Color(0xFFF4A261)),
              SizedBox(width: 5),
              Text('Mínima', style: TextStyle(fontSize: 11))
            ]),
          ])));
}

class _TemperaturePainter extends CustomPainter {
  _TemperaturePainter(this.days);
  final List<ForecastDay> days;
  @override
  void paint(Canvas canvas, Size size) {
    final points = days
        .map((d) => (
              min: double.tryParse(d.min.replaceAll(',', '.')),
              max: double.tryParse(d.max.replaceAll(',', '.'))
            ))
        .toList();
    final values =
        points.expand((p) => [p.min, p.max]).whereType<double>().toList();
    if (values.isEmpty) {
      _label(canvas, 'Sem dados de temperatura', Offset(20, size.height / 2),
          const TextStyle(color: Color(0xFF627D98)));
      return;
    }
    var low = values.reduce((a, b) => a < b ? a : b) - 2,
        high = values.reduce((a, b) => a > b ? a : b) + 2;
    if (high - low < 5) {
      low -= 3;
      high += 3;
    }
    const left = 30.0, right = 8.0, top = 14.0, bottom = 30.0;
    final plot =
        Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    double y(double v) => plot.bottom - (v - low) / (high - low) * plot.height;
    final grid = Paint()
      ..color = const Color(0xFFE8EEF1)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final yy = plot.top + plot.height * i / 3;
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), grid);
      final n = (high - (high - low) * i / 3).round();
      _label(canvas, '$n°', Offset(0, yy - 7),
          const TextStyle(fontSize: 10, color: Color(0xFF829AB1)));
    }
    final maxPoints = <Offset>[], minPoints = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? plot.center.dx
          : plot.left + i * plot.width / (points.length - 1);
      if (points[i].max != null) maxPoints.add(Offset(x, y(points[i].max!)));
      if (points[i].min != null) minPoints.add(Offset(x, y(points[i].min!)));
      final date = days[i].date;
      _label(
          canvas,
          date.length >= 10 ? date.substring(8, 10) : '${i + 1}',
          Offset(x - 7, size.height - 22),
          const TextStyle(fontSize: 10, color: Color(0xFF627D98)));
    }
    _line(canvas, maxPoints, const Color(0xFF167D8D));
    _line(canvas, minPoints, const Color(0xFFF4A261));
  }

  void _line(Canvas canvas, List<Offset> points, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < points.length; i++) {
      canvas.drawLine(points[i - 1], points[i], paint);
    }
    final dot = Paint()..color = color;
    for (final p in points) {
      canvas.drawCircle(p, 4, dot);
      canvas.drawCircle(p, 2, Paint()..color = Colors.white);
    }
  }

  void _label(Canvas c, String s, Offset p, TextStyle style) {
    final tp = TextPainter(
        text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, p);
  }

  @override
  bool shouldRepaint(covariant _TemperaturePainter old) => old.days != days;
}
