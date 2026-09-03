// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../models/equipo_model.dart';
import '../../services/supabase_service.dart';
import 'report_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salón 317',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              'Monitoreo Ergonómico en Vivo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.slateMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: service.isConnected
                  ? AppColors.statusOkBg
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: service.isConnected
                    ? AppColors.statusOk
                    : const Color(0xFFF59E0B),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: service.isConnected
                        ? AppColors.statusOk
                        : const Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  service.isConnected ? 'Realtime CDC' : 'Modo Demo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: service.isConnected
                        ? AppColors.statusOk
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Equipo>>(
        stream: service.getEquiposStream(),
        builder: (context, snapshot) {
          final equipos = snapshot.data ?? [];
          final operativos = equipos.where((e) => e.estado).length;
          final fallas = equipos.where((e) => !e.estado).length;
          final total = equipos.length;
          final pctOk = total > 0 ? (operativos / total) * 100 : 0.0;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Etiqueta explicativa de la Guía SENA
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.slateLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.touch_app_rounded,
                                  size: 16, color: AppColors.slateMedium),
                              const SizedBox(width: 6),
                              Text(
                                'ZONA DIFÍCIL (Lectura / Métricas Visuales)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slateMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Métricas según el Wireframe de la pág. 4 del SENA
                        Row(
                          children: [
                            // Tarjeta Operativos (Verde)
                            Expanded(
                              child: _MetricCard(
                                count: operativos.toString().padLeft(2, '0'),
                                label: 'PCs Operativos',
                                sublabel: 'Listos para uso',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.statusOk,
                                bgColor: AppColors.statusOkBg,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Tarjeta Con Falla (Rojo)
                            Expanded(
                              child: _MetricCard(
                                count: fallas.toString().padLeft(2, '0'),
                                label: 'Con Falla',
                                sublabel: 'Requieren soporte',
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.statusFail,
                                bgColor: AppColors.statusFailBg,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Barra de Disponibilidad del Salón
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Disponibilidad del Aula',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.slateDark,
                                    ),
                                  ),
                                  Text(
                                    '${pctOk.toStringAsFixed(0)}%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: pctOk > 80
                                          ? AppColors.statusOk
                                          : AppColors.statusFail,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: total > 0 ? (operativos / total) : 0,
                                  minHeight: 10,
                                  backgroundColor: AppColors.statusFailBg,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppColors.statusOk),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$operativos de $total puestos listos para formación',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.slateMedium,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Equipos con Novedades / Fallas Rápidas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Equipos con Falla Reciente',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.slateDark,
                              ),
                            ),
                            TextButton(
                              onPressed: () => onNavigateToTab?.call(1),
                              child: Text(
                                'Ver todos ($total)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.senaGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        if (fallas == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.sentiment_very_satisfied_rounded,
                                    color: AppColors.statusOk, size: 36),
                                const SizedBox(height: 8),
                                Text(
                                  '¡Todos los 30 computadores están operativos!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.slateDark,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...equipos.where((e) => !e.estado).take(3).map(
                                (eq) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.statusFailBg, width: 2),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: AppColors.statusFailBg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.desktop_access_disabled_rounded,
                                          color: AppColors.statusFail,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              eq.codigo,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: AppColors.slateDark,
                                              ),
                                            ),
                                            Text(
                                              eq.observacion ?? 'Sin detalle',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color: AppColors.statusFail,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.build_rounded,
                                            color: AppColors.primary, size: 20),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ReportScreen(equipo: eq),
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
                ),

                // ============================================
                // ZONA NATURAL DEL PULGAR (Interacción Primaria)
                // Regla del Pulgar: Acciones frecuentes al alcance del pulgar
                // ============================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    border: const Border(
                      top: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Etiqueta explicativa ergonómica
                      Text(
                        'Que deseas hacer?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slateMedium,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReportScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 22),
                          label: Text(
                            '+ Nuevo Reporte',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => onNavigateToTab?.call(1),
                          icon: const Icon(Icons.qr_code_scanner_rounded,
                              color: AppColors.slateDark, size: 20),
                          label: Text(
                            'Explorar 30 PCs del Salón',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slateDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String count;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.count,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1,
                ),
              ),
              Icon(icon, color: color, size: 28),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            sublabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.slateMedium,
            ),
          ),
        ],
      ),
    );
  }
}
