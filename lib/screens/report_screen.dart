import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../models/equipo_model.dart';
import '../../services/supabase_service.dart';

class ReportScreen extends StatefulWidget {
  final Equipo? equipo;
  final bool isCreatingNew;

  const ReportScreen({super.key, this.equipo, this.isCreatingNew = false});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCodigo;
  late TextEditingController _codigoController;
  late bool _estadoOperativo;
  late TextEditingController _observacionController;
  bool _isSaving = false;
  late bool _isNewMode;

  final List<String> _quickNovedades = [
    'Sin señal de video',
    'Teclado: tecla rota',
    'No enciende',
    'Falla en cable de red',
    'Mouse no responde',
    'Actualización de software pendiente',
  ];

  @override
  void initState() {
    super.initState();
    _isNewMode = widget.isCreatingNew || widget.equipo == null;
    _selectedCodigo = widget.equipo?.codigo ?? 'PC-317-01';
    _codigoController = TextEditingController(
      text: widget.equipo?.codigo ?? (widget.isCreatingNew ? 'PC-317-31' : 'PC-317-01'),
    );
    _estadoOperativo = widget.equipo?.estado ?? true;
    _observacionController = TextEditingController(
      text: widget.equipo?.observacion ?? (_estadoOperativo ? 'Core i7 · 16GB · OK' : ''),
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _guardarReporte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final service = SupabaseService();
    final finalCode = _codigoController.text.trim();

    try {
      if (widget.equipo != null) {
        // Actualizar equipo existente
        await service.updateEquipoEstado(
          id: widget.equipo!.id,
          nuevoEstado: _estadoOperativo,
          observacion: _observacionController.text.trim(),
        );
      } else {
        // Crear nuevo equipo en Supabase
        await service.createEquipo(
          codigo: finalCode,
          estado: _estadoOperativo,
          observacion: _observacionController.text.trim().isEmpty
              ? (_estadoOperativo ? 'Core i7 · 16GB · OK' : 'Reportado con falla')
              : _observacionController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusOk,
            content: Text(
              '¡Equipo $finalCode guardado correctamente en Supabase!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusFail,
            content: Text('Error al guardar: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.equipo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Reportar Estado' : 'Agregar o Reportar PC'),
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
                      // Encabezado según Modo
                      if (!isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _ModeTab(
                                label: 'Nuevo PC',
                                icon: Icons.add_to_queue_rounded,
                                isSelected: _isNewMode,
                                onTap: () {
                                  setState(() {
                                    _isNewMode = true;
                                    _codigoController.text = 'PC-317-31';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ModeTab(
                                label: 'PC Existente',
                                icon: Icons.list_alt_rounded,
                                isSelected: !_isNewMode,
                                onTap: () {
                                  setState(() {
                                    _isNewMode = false;
                                    _codigoController.text = _selectedCodigo;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],

                      Text(
                        _isNewMode
                            ? 'Código del Nuevo Equipo:'
                            : 'Equipo seleccionado:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slateDark,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (isEditing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.desktop_windows_rounded,
                                  color: Color(0xFF2563EB)),
                              const SizedBox(width: 12),
                              Text(
                                '${widget.equipo!.codigo} (Salón 317)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: const Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_isNewMode)
                        // Campo de texto libre para crear CUALQUIER PC
                        TextFormField(
                          controller: _codigoController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Ej. PC-317-31, PORTATIL-01...',
                            prefixIcon: const Icon(Icons.add_to_queue_rounded,
                                color: AppColors.primary),
                            suffixText: '(Salón 317)',
                            suffixStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.slateMedium,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Ingresa el código del computador';
                            }
                            return null;
                          },
                        )
                      else
                        // Selector de PC existente
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCodigo,
                              isExpanded: true,
                              icon:
                                  const Icon(Icons.keyboard_arrow_down_rounded),
                              items: List.generate(35, (i) {
                                final code =
                                    'PC-317-${(i + 1).toString().padLeft(2, '0')}';
                                return DropdownMenuItem(
                                  value: code,
                                  child: Text(
                                    code,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCodigo = val;
                                    _codigoController.text = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Condición actual
                      Text(
                        'Condición actual:',
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
                            child: _ConditionButton(
                              label: 'OPERATIVO',
                              icon: Icons.check_circle_rounded,
                              isSelected: _estadoOperativo,
                              activeColor: AppColors.statusOk,
                              activeBgColor: AppColors.statusOkBg,
                              onTap: () {
                                setState(() {
                                  _estadoOperativo = true;
                                  if (_observacionController.text.trim().isEmpty) {
                                    _observacionController.text =
                                        'Core i7 · 16GB · OK';
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ConditionButton(
                              label: 'CON FALLA',
                              icon: Icons.cancel_rounded,
                              isSelected: !_estadoOperativo,
                              activeColor: AppColors.statusFail,
                              activeBgColor: AppColors.statusFailBg,
                              onTap: () {
                                setState(() {
                                  _estadoOperativo = false;
                                  if (_observacionController.text ==
                                      'Core i7 · 16GB · OK') {
                                    _observacionController.clear();
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Detalle o Novedad
                      Text(
                        'Especificaciones / Novedad:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slateDark,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _observacionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: _estadoOperativo
                              ? 'Ej. Core i7 · 16GB · SSD 512GB · OK'
                              : 'Ej. No enciende / Pantalla azul / Falla de red',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.slateLight,
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (val) {
                          if (!_estadoOperativo &&
                              (val == null || val.trim().isEmpty)) {
                            return 'Especifica el motivo de la falla';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Atajos de novedad rápida
                      Text(
                        'Atajos rápidos:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slateMedium,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickNovedades.map((tag) {
                          return ActionChip(
                            label: Text(
                              tag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.slateDark,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            onPressed: () {
                              setState(() {
                                _estadoOperativo = false;
                                _observacionController.text = tag;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botón Táctil en Zona Inferior del Pulgar
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
                border: const Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _guardarReporte,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _estadoOperativo
                        ? AppColors.primary
                        : AppColors.statusFail,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isNewMode && !isEditing
                              ? 'AGREGAR EQUIPO A SUPABASE'
                              : 'GUARDAR EN SUPABASE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
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

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primaryDark : AppColors.slateMedium,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDark : AppColors.slateDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color activeBgColor;
  final VoidCallback onTap;

  const _ConditionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.activeBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : AppColors.slateMedium,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : AppColors.slateMedium,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
