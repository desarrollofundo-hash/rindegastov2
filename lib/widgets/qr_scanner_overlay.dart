import 'package:flutter/material.dart';

/// Clase para crear el overlay del marco de escaneo QR
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    Path oval = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, oval);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final boxSize = cutOutSize + borderOffset * 2;
    final boxRect = Rect.fromLTWH(
      (width - boxSize) / 2,
      (height - boxSize) / 2,
      boxSize,
      boxSize,
    );

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    // Draw the border lines
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.left, boxRect.top + borderLength)
        ..lineTo(boxRect.left, boxRect.top + borderRadius)
        ..arcToPoint(
          Offset(boxRect.left + borderRadius, boxRect.top),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(boxRect.left + borderLength, boxRect.top),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.right - borderLength, boxRect.top)
        ..lineTo(boxRect.right - borderRadius, boxRect.top)
        ..arcToPoint(
          Offset(boxRect.right, boxRect.top + borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(boxRect.right, boxRect.top + borderLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.left, boxRect.bottom - borderLength)
        ..lineTo(boxRect.left, boxRect.bottom - borderRadius)
        ..arcToPoint(
          Offset(boxRect.left + borderRadius, boxRect.bottom),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(boxRect.left + borderLength, boxRect.bottom),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(boxRect.right - borderLength, boxRect.bottom)
        ..lineTo(boxRect.right - borderRadius, boxRect.bottom)
        ..arcToPoint(
          Offset(boxRect.right, boxRect.bottom - borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(boxRect.right, boxRect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
