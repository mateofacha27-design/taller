// lib/screens/crear_pc_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';

class CrearPcScreen extends StatefulWidget {
  const CrearPcScreen({super.key});

  @override
  State<CrearPcScreen> createState() => _CrearPcScreenState();
}

class _CrearPcScreenState extends State<CrearPcScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController(text: 'PC-317-');
  final _especificacionesController =
      TextEditingController(text: 'Core i7 · 16GB RAM · SSD 512GB');
  bool _estadoOperativo = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _especificacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardarNuevoPc() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final service = SupabaseService();
    final codigo = _codigoController.text.trim();

    try {
      await service.createEquipo(
        codigo: codigo,
        estado: _estadoOperativo,
        observacion: _especificacionesController.text.trim().isEmpty
            ? (_estadoOperativo ? 'Core i7 · 16GB · OK' : 'Con Novedad')
            : _especificacionesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusOk,
            content: Text('¡Computador $codigo registrado con éxito en Salón 317!'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusFail,
            content: Text('Error al crear equipo: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nuevo Computador'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tarjeta decorativa con icono de hardware
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.senaGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_to_queue_rounded,
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nuevo Puesto de Formación',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  Text(
                                    'Salón 317 - Ambiente de Software',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.slateMedium,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Campo 1: Código del Computador
                      Text(
                        'Código del Computador',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slateDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _codigoController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Ej. PC-317-31',
                          prefixIcon: Icon(Icons.pin_rounded,
                              color: AppColors.slateMedium),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa un código para el equipo';
                          }
                          if (val.trim().length < 3) {
                            return 'El código es demasiado corto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo 2: Especificaciones Técnicas del Hardware
                      Text(
                        'Especificaciones Técnicas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slateDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _especificacionesController,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Core i7 · 16GB RAM · SSD 512GB',
                          prefixIcon: Icon(Icons.memory_rounded,
                              color: AppColors.slateMedium),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Campo 3: Estado Inicial de la Máquina
                      Text(
                        'Estado Inicial del Equipo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slateDark,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _estadoOperativo = true),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: _estadoOperativo
                                      ? AppColors.statusOkBg
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _estadoOperativo
                                        ? AppColors.statusOk
                                        : AppColors.border,
                                    width: _estadoOperativo ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: _estadoOperativo
                                          ? AppColors.statusOk
                                          : AppColors.slateMedium,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'OPERATIVO',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: _estadoOperativo
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: _estadoOperativo
                                            ? AppColors.statusOk
                                            : AppColors.slateMedium,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _estadoOperativo = false),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: !_estadoOperativo
                                      ? AppColors.statusFailBg
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !_estadoOperativo
                                        ? AppColors.statusFail
                                        : AppColors.border,
                                    width: !_estadoOperativo ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cancel_rounded,
                                      color: !_estadoOperativo
                                          ? AppColors.statusFail
                                          : AppColors.slateMedium,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'CON FALLA',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: !_estadoOperativo
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: !_estadoOperativo
                                            ? AppColors.statusFail
                                            : AppColors.slateMedium,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botón Inferior en Zona Natural del Pulgar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _guardarNuevoPc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox.shrink()
                      : const Icon(Icons.add_circle_outline_rounded,
                          color: Colors.white, size: 20),
                  label: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'GUARDAR COMPUTADOR EN SUPABASE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
