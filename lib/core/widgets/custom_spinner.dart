import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomSpinner extends StatefulWidget {
  final double size;
  final Color? color;

  const CustomSpinner({
    super.key,
    this.size = 80.0,
    this.color,
  });

  @override
  State<CustomSpinner> createState() => _CustomSpinnerState();
}

class _CustomSpinnerState extends State<CustomSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si no se especifica color, dibujamos el spinner completo (con fondo azul como el icono)
    final bool isFullIcon = widget.color == null;
    final themeColor = widget.color ?? Colors.white;

    Widget spinnerContent = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centro fijo: símbolo del dólar
          Text(
            '\$',
            style: TextStyle(
              fontSize: widget.size * 0.45,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          // Anillo interior girando a la izquierda (antihorario)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_controller.value * 2.0 * math.pi * 1.5,
                child: CustomPaint(
                  size: Size(widget.size * 0.75, widget.size * 0.75),
                  painter: _DashedCirclePainter(
                    color: themeColor.withOpacity(0.8),
                    strokeWidth: widget.size * 0.08,
                    dashLength: widget.size * 0.2,
                    gapLength: widget.size * 0.1,
                  ),
                ),
              );
            },
          ),
          // Anillo exterior girando a la derecha (horario)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2.0 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _DashedCirclePainter(
                    color: themeColor,
                    strokeWidth: widget.size * 0.1,
                    dashLength: widget.size * 0.4,
                    gapLength: widget.size * 0.15,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    if (isFullIcon) {
      // Añadir el fondo azul que simula la cartera
      return Container(
        width: widget.size * 1.5,
        height: widget.size * 1.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size * 0.35),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4FC3F7), // Light blue
              Color(0xFF0277BD), // Darker blue
              Color(0xFF01579B), // Darkest blue
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: widget.size * 0.2,
              offset: Offset(0, widget.size * 0.1),
            ),
          ],
        ),
        child: Center(child: spinnerContent),
      );
    }

    return spinnerContent;
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final circumference = math.pi * size.width;
    final double totalDashSpace = dashLength + gapLength;
    final int dashCount = (circumference / totalDashSpace).floor();
    
    // Recalcular para que cierre perfecto
    final double adjustedTotalSpace = circumference / dashCount;
    final double adjustedDashLength = adjustedTotalSpace * (dashLength / totalDashSpace);
    final double adjustedGapLength = adjustedTotalSpace - adjustedDashLength;

    double startAngle = 0;
    
    // Radio
    final radius = size.width / 2;
    
    for (int i = 0; i < dashCount; i++) {
      final sweepAngle = (adjustedDashLength / circumference) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle + ((adjustedGapLength / circumference) * 2 * math.pi);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
