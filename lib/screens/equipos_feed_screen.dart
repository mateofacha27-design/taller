// lib/screens/equipos_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../models/equipo_model.dart';
import '../../services/supabase_service.dart';
import 'crear_pc_screen.dart';
import 'report_screen.dart';

class EquiposFeedScreen extends StatefulWidget {
  const EquiposFeedScreen({super.key});

  @override
  State<EquiposFeedScreen> createState() => _EquiposFeedScreenState();
}

class _EquiposFeedScreenState extends State<EquiposFeedScreen> {
  String _filter = 'todos'; // 'todos', 'operativos', 'fallas'
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleQuickStatus(Equipo equipo) async {
    final service = SupabaseService();
    final nuevoEstado = !equipo.estado;

    try {
      await service.updateEquipoEstado(
        id: equipo.id,
        nuevoEstado: nuevoEstado,
        observacion: nuevoEstado
            ? 'Operativo / Restaurado'
            : (equipo.observacion ?? 'Reportado con falla'),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            backgroundColor:
                nuevoEstado ? AppColors.statusOk : AppColors.statusFail,
            content: Text(
              '${equipo.codigo}: Marcado como ${nuevoEstado ? "BIEN (Operativo)" : "MAL (Con Falla)"}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusFail,
            content: Text('Error al actualizar: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<List<Equipo>>(
          stream: service.getEquiposStream(),
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 30;
            return Text(
              'Salón 317 ($count PCs)',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            );
          },
        ),
        actions: [
          // Botón + Nuevo PC en la barra superior
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CrearPcScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(100, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: Text(
                'Nuevo PC',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Buscador táctil y ergonómico
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Buscar por código (ej. PC-317-05)...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.slateMedium, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ),

            // Píldoras de Filtro Rápido
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos los Puestos',
                    isSelected: _filter == 'todos',
                    onTap: () => setState(() => _filter = 'todos'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '🟢 Operativos (BIEN)',
                    isSelected: _filter == 'operativos',
                    onTap: () => setState(() => _filter = 'operativos'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '🔴 Con Falla (MAL)',
                    isSelected: _filter == 'fallas',
                    onTap: () => setState(() => _filter = 'fallas'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Feed Reactivo StreamBuilder (Actividad 3 SENA)
            Expanded(
              child: StreamBuilder<List<Equipo>>(
                stream: service.getEquiposStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (snapshot.hasError && (!snapshot.hasData || snapshot.data!.isEmpty)) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sync_problem_rounded,
                                size: 48, color: AppColors.statusFail),
                            const SizedBox(height: 12),
                            Text(
                              'Sincronizando con Supabase...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.slateDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final equipos = snapshot.data ?? [];

                  // Filtrado local en vivo
                  final filtered = equipos.where((e) {
                    final matchesFilter = _filter == 'todos' ||
                        (_filter == 'operativos' && e.estado) ||
                        (_filter == 'fallas' && !e.estado);

                    final matchesSearch = _searchQuery.isEmpty ||
                        e.codigo
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        (e.observacion
                                ?.toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ??
                            false);

                    return matchesFilter && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.slateLight),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron computadores',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slateMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final eq = filtered[index];
                      return _EquipoCard(
                        equipo: eq,
                        onToggle: () => _toggleQuickStatus(eq),
                        onEdit: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportScreen(equipo: eq),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CrearPcScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Agregar PC',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slateDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.slateDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.slateMedium,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta que implementa el Semáforo Visual (BIEN / MAL)
/// Diseñada para identificación visual en menos de 3 segundos
class _EquipoCard extends StatelessWidget {
  final Equipo equipo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _EquipoCard({
    required this.equipo,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isOk = equipo.estado;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOk
              ? AppColors.border
              : AppColors.statusFail.withValues(alpha: 0.3),
          width: isOk ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Punto Semáforo de Estado
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOk ? AppColors.statusOk : AppColors.statusFail,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isOk ? AppColors.statusOk : AppColors.statusFail)
                          .withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Código y Detalle Técnico
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipo.codigo,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.slateDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      equipo.observacion ??
                          (isOk ? 'Operativo' : 'Con Falla Reportada'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isOk
                            ? AppColors.slateMedium
                            : AppColors.statusFail,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón Semáforo Táctil (BIEN / MAL)
              // Al tocarlo, conmuta el estado de forma inmediata
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 68,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isOk ? AppColors.statusOk : AppColors.statusFail,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isOk ? AppColors.statusOk : AppColors.statusFail)
                                .withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isOk ? 'BIEN' : 'MAL',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
