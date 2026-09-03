// lib/screens/salones_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../services/supabase_service.dart';
import 'auth/login_screen.dart';

class SalonesScreen extends StatefulWidget {
  const SalonesScreen({super.key});

  @override
  State<SalonesScreen> createState() => _SalonesScreenState();
}

class _SalonesScreenState extends State<SalonesScreen> {
  bool _isSeeding = false;

  void _handleSeedDatabase() async {
    setState(() => _isSeeding = true);
    final service = SupabaseService();

    try {
      await service.seed30EquiposIfEmpty();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.statusOk,
            content: Text('¡30 Computadores precargados con éxito!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusFail,
            content: Text('Error al cargar datos: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  void _handleLogout() async {
    final service = SupabaseService();
    await service.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();
    final user = service.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Salones y Configuración',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Perfil del Usuario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryDark,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Aprendiz / Instructor SENA',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.slateDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.senaGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user != null
                                ? 'Usuario Autenticado'
                                : 'Sesión en Modo Local / Demo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.senaGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ambientes de Formación Disponibles
            Text(
              'Ambientes de Aprendizaje',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.slateDark,
              ),
            ),
            const SizedBox(height: 12),

            _SalonTile(
              codigo: '317',
              nombre: 'Salón 317 - Desarrollo de Software',
              puestos: 30,
              isActive: true,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _SalonTile(
              codigo: '318',
              nombre: 'Salón 318 - Multimedia y Web',
              puestos: 28,
              isActive: false,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _SalonTile(
              codigo: 'LAB',
              nombre: 'Laboratorio de Telecomunicaciones',
              puestos: 24,
              isActive: false,
              onTap: () {},
            ),

            const SizedBox(height: 28),

            // Estado de Conexión a Supabase
            Text(
              'Infraestructura Backend (BaaS)',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.slateDark,
              ),
            ),
            const SizedBox(height: 12),

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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: service.isConnected
                              ? AppColors.statusOkBg
                              : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          service.isConnected
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_queue_rounded,
                          color: service.isConnected
                              ? AppColors.statusOk
                              : const Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.isConnected
                                  ? 'Supabase Conectado'
                                  : 'Modo Demo (Credenciales Pendientes)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.slateDark,
                              ),
                            ),
                            Text(
                              SupabaseConfig.supabaseUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.slateLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (service.isConnected)
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSeeding ? null : _handleSeedDatabase,
                        icon: _isSeeding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          _isSeeding
                              ? 'Cargando computadores...'
                              : 'Precargar 30 PCs en Supabase',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Botón Cerrar Sesión
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusFail,
                  side: const BorderSide(color: AppColors.statusFail, width: 1.2),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  'Cerrar Sesión',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SalonTile extends StatelessWidget {
  final String codigo;
  final String nombre;
  final int puestos;
  final bool isActive;
  final VoidCallback onTap;

  const _SalonTile({
    required this.codigo,
    required this.nombre,
    required this.puestos,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 1.8 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryLight : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            codigo,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: isActive ? AppColors.primaryDark : AppColors.slateMedium,
            ),
          ),
        ),
        title: Text(
          nombre,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.slateDark,
          ),
        ),
        subtitle: Text(
          '$puestos computadores en red',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.slateMedium,
          ),
        ),
        trailing: isActive
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusOkBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ACTIVO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.statusOk,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.slateLight),
      ),
    );
  }
}
