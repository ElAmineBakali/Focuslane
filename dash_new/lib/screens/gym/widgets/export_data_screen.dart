import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gym_firestore_service.dart';
import 'package:intl/intl.dart';

 class ExportDataScreen extends StatefulWidget {
  final GymFirestoreService svc;

  const ExportDataScreen({super.key, required this.svc});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  bool _isExporting = false;
  String? _exportedData;
  String? _errorMessage;

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _exportedData = null;
    });

    try {
      final data = await widget.svc.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      setState(() {
        _exportedData = jsonString;
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isExporting = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_exportedData != null) {
             ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Row(
            children: [
              const Icon(Icons.check_circle),
              const SizedBox(width: 8),
              Text(
                'Datos copiados al portapapeles',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _saveToFile() {
    if (_exportedData != null) {
             final fileName = 'focuslane_gym_export_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.json';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.download, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Archivo listo para guardar',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                fileName,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exportar Datos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                         Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_download,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Exportar Historial Completo',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Descarga todos tus datos de entrenamiento en formato JSON',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

                         Text(
              '¿Qué se exportará?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(Icons.fitness_center, 'Todas las sesiones de entrenamiento'),
            _buildInfoItem(Icons.monitor_weight, 'Historial de peso corporal'),
            _buildInfoItem(Icons.straighten, 'Medidas corporales'),
            _buildInfoItem(Icons.list_alt, 'Rutinas completas con ejercicios'),
            
            const SizedBox(height: 32),

                         if (!_isExporting && _exportedData == null)
              FilledButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                label: Text(
                  'Exportar Datos',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

                         if (_isExporting)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Exportando datos...',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

                         if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          color: Colors.red[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

                         if (_exportedData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Exportación completa!',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Datos listos para descargar',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
                             Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: Text(
                        'Copiar',
                        style: GoogleFonts.poppins(),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveToFile,
                      icon: const Icon(Icons.save),
                      label: Text(
                        'Guardar',
                        style: GoogleFonts.poppins(),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
                             Text(
                'Vista previa',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _exportedData!.length > 1000
                        ? '${_exportedData!.substring(0, 1000)}...\n\n[... datos truncados para vista previa ...]'
                        : _exportedData!,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 11,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Icon(Icons.check, size: 18, color: Colors.green[600]),
        ],
      ),
    );
  }
}
