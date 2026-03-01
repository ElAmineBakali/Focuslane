import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalColorPickerWidget extends StatefulWidget {
  final Color? initialColor;
  final ValueChanged<Color> onColorSelected;
  final String label;

  const GlobalColorPickerWidget({
    super.key,
    this.initialColor,
    required this.onColorSelected,
    this.label = 'Color',
  });

  @override
  State<GlobalColorPickerWidget> createState() =>
      _GlobalColorPickerWidgetState();
}

class _GlobalColorPickerWidgetState extends State<GlobalColorPickerWidget> {
  static const String _recentColorsKey = 'recent_colors';
  late Color _selectedColor;
  List<Color> _recentColors = [];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? Colors.blue;
    _loadRecentColors();
  }

  Future<void> _loadRecentColors() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? colorStrings = prefs.getStringList(_recentColorsKey);
    if (colorStrings != null) {
      setState(() {
        _recentColors =
            colorStrings.map((s) => Color(int.parse(s))).take(5).toList();
      });
    }
  }

  Future<void> _saveRecentColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();

    _recentColors.removeWhere((c) => c.value == color.value);
    _recentColors.insert(0, color);
    if (_recentColors.length > 5) {
      _recentColors = _recentColors.take(5).toList();
    }

    await prefs.setStringList(
      _recentColorsKey,
      _recentColors.map((c) => c.value.toString()).toList(),
    );
  }

  Future<void> _showColorPickerDialog() async {
    Color tempColor = _selectedColor;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Seleccionar color',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) => tempColor = color,
                pickerAreaHeightPercent: 0.8,
                displayThumbColor: true,
                enableAlpha: false,
                labelTypes: const [],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() => _selectedColor = tempColor);
                  widget.onColorSelected(tempColor);
                  _saveRecentColor(tempColor);
                  Navigator.pop(context);
                },
                child: const Text('Seleccionar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        InkWell(
          onTap: _showColorPickerDialog,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _selectedColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _selectedColor, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedColor,
                    ),
                  ),
                ),
                Icon(Icons.palette_rounded, color: _selectedColor),
              ],
            ),
          ),
        ),

        if (_recentColors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Recientes',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                _recentColors.map((color) {
                  final isSelected = color.value == _selectedColor.value;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedColor = color);
                      widget.onColorSelected(color);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            isSelected
                                ? Border.all(
                                  color: colorScheme.primary,
                                  width: 3,
                                )
                                : null,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child:
                          isSelected
                              ? Icon(
                                Icons.check_rounded,
                                color: _getContrastColor(color),
                                size: 24,
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
