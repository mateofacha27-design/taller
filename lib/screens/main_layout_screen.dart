import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import 'dashboard_screen.dart';
import 'equipos_feed_screen.dart';
import 'report_screen.dart';
import 'salones_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onNavigateToTab: _onTabTapped),
      const EquiposFeedScreen(),
      const ReportScreen(),
      const SalonesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // Barra de Navegación Ergonómica (Regla del Pulgar: Fácil acceso inferior)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 0.8),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.senaGreen,
              unselectedItemColor: AppColors.slateLight,
              selectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard_rounded),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.devices_outlined),
                  activeIcon: Icon(Icons.devices_rounded),
                  label: 'Equipos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.edit_note_outlined),
                  activeIcon: Icon(Icons.edit_note_rounded),
                  label: 'Reportar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.meeting_room_outlined),
                  activeIcon: Icon(Icons.meeting_room_rounded),
                  label: 'Salones',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
