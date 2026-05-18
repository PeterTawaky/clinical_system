import 'package:flutter/material.dart';
import 'dart:math' as math;

class RouterErrorView extends StatefulWidget {
  final Color? primaryColor;
  final Brightness? brightness;

  const RouterErrorView({super.key, this.primaryColor, this.brightness});

  @override
  State<RouterErrorView> createState() => _RouterErrorViewState();
}

class _RouterErrorViewState extends State<RouterErrorView>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = widget.brightness ?? Brightness.dark;
    final isDark = brightness == Brightness.dark;
    final primaryColor = widget.primaryColor ?? const Color(0xFF6C63FF);
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    final backgroundColor = isDark ? const Color(0xFF0F0F1E) : Colors.grey[50]!;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background circles
            ...List.generate(5, (index) {
              return AnimatedBuilder(
                animation: _rotateAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BackgroundCirclePainter(
                      rotation: _rotateAnimation.value + (index * 0.5),
                      color: primaryColor.withOpacity(0.05),
                      index: index,
                    ),
                    size: Size.infinite,
                  );
                },
              );
            }),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 60 : 24,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated 404 illustration
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _floatAnimation,
                        _pulseAnimation,
                      ]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: Transform.scale(
                            scale: _pulseAnimation.value,
                            child: SizedBox(
                              width: isTablet ? 400 : size.width * 0.8,
                              height: isTablet ? 300 : 250,
                              child: CustomPaint(
                                painter: Error404Painter(
                                  primaryColor: primaryColor,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: isTablet ? 60 : 40),

                    // Error title with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.6)],
                      ).createShader(bounds),
                      child: Text(
                        'Route Not Found',
                        style: TextStyle(
                          fontSize: isTablet ? 42 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: isTablet ? 24 : 16),

                    // Description
                    Text(
                      'Oops! Page Not Exist',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isTablet ? 50 : 40),

                    // Animated go back button
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.05,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 48 : 40,
                                    vertical: isTablet ? 20 : 16,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: isTablet ? 26 : 24,
                                      ),
                                      SizedBox(width: isTablet ? 16 : 12),
                                      Text(
                                        'Go Back',
                                        style: TextStyle(
                                          fontSize: isTablet ? 20 : 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for animated background circles
class BackgroundCirclePainter extends CustomPainter {
  final double rotation;
  final Color color;
  final int index;

  BackgroundCirclePainter({
    required this.rotation,
    required this.color,
    required this.index,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 3) + (index * 30);
    final offset = Offset(
      math.cos(rotation) * radius,
      math.sin(rotation) * radius,
    );

    canvas.drawCircle(center + offset, 50 + (index * 20), paint);
  }

  @override
  bool shouldRepaint(BackgroundCirclePainter oldDelegate) =>
      rotation != oldDelegate.rotation;
}

// Custom painter for 404 illustration
class Error404Painter extends CustomPainter {
  final Color primaryColor;
  final bool isDark;

  Error404Painter({required this.primaryColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Draw broken road/path
    final pathPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.5,
      size.width * 0.45,
      size.height * 0.5,
    );

    path.moveTo(size.width * 0.55, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.5,
      size.width * 0.8,
      size.height * 0.3,
    );

    canvas.drawPath(path, pathPaint);

    // Draw large "404" numbers with modern style
    final textStyle = TextStyle(
      fontSize: size.width * 0.35,
      fontWeight: FontWeight.w900,
      foreground: Paint()
        ..shader = LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.6)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final textSpan = TextSpan(text: '404', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2 - 20,
      ),
    );

    // Draw floating geometric shapes
    final shapePaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Triangle
    final trianglePath = Path();
    trianglePath.moveTo(size.width * 0.15, size.height * 0.2);
    trianglePath.lineTo(size.width * 0.2, size.height * 0.3);
    trianglePath.lineTo(size.width * 0.1, size.height * 0.3);
    trianglePath.close();
    canvas.drawPath(trianglePath, shapePaint);

    // Circle
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      15,
      shapePaint,
    );

    // Square
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, size.height * 0.8, 25, 25),
        const Radius.circular(5),
      ),
      shapePaint,
    );

    // Small dots
    final dotPaint = Paint()
      ..color = primaryColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.75),
      8,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.5),
      6,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(Error404Painter oldDelegate) => false;
}
