import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageEditorDialog extends StatefulWidget {
  final Uint8List initialBytes;
  const ImageEditorDialog({super.key, required this.initialBytes});

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  late Uint8List _workingBytes;
  double _rotationDeg = 0;
  double _scale = 1.0;

  Rect _cropFrac = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  final TransformationController _transform = TransformationController();
  bool _draggingCrop = false;

  @override
  void initState() {
    super.initState();
    _workingBytes = widget.initialBytes;
  }

  void _applyEditsAndClose() async {
    try {
      final base = img.decodeImage(_workingBytes);
      if (base == null) {
        Navigator.pop(context, _workingBytes);
        return;
      }
      img.Image edited = base;

      final rotSteps = ((_rotationDeg % 360) / 90).round();
      switch (rotSteps % 4) {
        case 1:
          edited = img.copyRotate(edited, angle: 90);
          break;
        case 2:
          edited = img.copyRotate(edited, angle: 180);
          break;
        case 3:
          edited = img.copyRotate(edited, angle: 270);
          break;
        default:
          break;
      }

      if (_scale != 1.0) {
        final w = (edited.width * _scale).clamp(1, 10000).toInt();
        final h = (edited.height * _scale).clamp(1, 10000).toInt();
        edited = img.copyResize(edited, width: w, height: h, interpolation: img.Interpolation.linear);
      }

      final cx = (_cropFrac.left.clamp(0.0, 1.0) * edited.width).toInt();
      final cy = (_cropFrac.top.clamp(0.0, 1.0) * edited.height).toInt();
      final cw = (_cropFrac.width.clamp(0.0, 1.0) * edited.width).toInt();
      final ch = (_cropFrac.height.clamp(0.0, 1.0) * edited.height).toInt();
      edited = img.copyCrop(edited, x: cx, y: cy, width: cw, height: ch);

      final out = img.encodePng(edited);
      Navigator.pop(context, Uint8List.fromList(out));
    } catch (_) {
      Navigator.pop(context, _workingBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Editar imagen', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(children: [
                            InteractiveViewer(
                              transformationController: _transform,
                              minScale: 0.5,
                              maxScale: 5.0,
                              panEnabled: true,
                              scaleEnabled: true,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateZ(_rotationDeg * 3.14159265 / 180)..scale(_scale),
                                child: Center(child: Image.memory(_workingBytes, fit: BoxFit.contain)),
                              ),
                            ),
                            LayoutBuilder(builder: (ctx, c) {
                              final w = c.maxWidth;
                              final h = c.maxHeight;
                              final r = Rect.fromLTWH(
                                _cropFrac.left * w,
                                _cropFrac.top * h,
                                _cropFrac.width * w,
                                _cropFrac.height * h,
                              );
                              return GestureDetector(
                                onPanStart: (_) => setState(() => _draggingCrop = true),
                                onPanUpdate: (d) {
                                  if (!_draggingCrop) return;
                                  final dx = d.delta.dx / w;
                                  final dy = d.delta.dy / h;
                                  final next = Rect.fromLTWH(
                                    (_cropFrac.left + dx).clamp(0.0, 1.0 - _cropFrac.width),
                                    (_cropFrac.top + dy).clamp(0.0, 1.0 - _cropFrac.height),
                                    _cropFrac.width,
                                    _cropFrac.height,
                                  );
                                  setState(() => _cropFrac = next);
                                },
                                onPanEnd: (_) => setState(() => _draggingCrop = false),
                                child: Stack(children: [
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: ShapeDecoration(
                                          shape: _CropOverlayShape(r),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: r.left,
                                    top: r.top,
                                    child: Container(
                                      width: r.width,
                                      height: r.height,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                                      ),
                                    ),
                                  ),
                                ]),
                              );
                            }),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildControl('Rotar', _rotationDeg, -180, 180, (v) {
                        setState(() => _rotationDeg = v);
                      }),
                      _buildControl('Escala', _scale, 0.2, 3.0, (v) {
                        setState(() => _scale = v);
                      }),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _applyEditsAndClose,
                            child: const Text('Aplicar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControl(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            value: value,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _CropOverlayShape extends ShapeBorder {
  final Rect cropRect;
  const _CropOverlayShape(this.cropRect);
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final p = Path()..addRect(rect);
    final hole = Path()..addRect(cropRect);
    return Path.combine(PathOperation.difference, p, hole);
  }
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()..color = Colors.black.withOpacity(0.35);
    final path = getOuterPath(rect, textDirection: textDirection);
    canvas.drawPath(path, paint);
  }
  @override
  ShapeBorder scale(double t) => this;
}
