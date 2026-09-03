// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../main_layout_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'aprendiz';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final service = SupabaseService();

    try {
      if (service.isConnected) {
        await service.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          nombre: _nameController.text.trim(),
          rol: _selectedRole,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.statusOk,
            content: Text('¡Registro exitoso! Bienvenido al sistema.'),
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusFail,
            content: Text('Error al registrar: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registro de Usuario',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slateDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Únete para gestionar o reportar novedades del Salón 317.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.slateMedium,
                  ),
                ),
                const SizedBox(height: 28),

                // Campo Nombre
                Text(
                  'Nombre Completo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Juan Pérez',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppColors.slateMedium),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),

                const SizedBox(height: 18),

                // Campo Correo
                Text(
                  'Correo Electrónico',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'correo@ejemplo.com',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.slateMedium),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Ingresa tu correo';
                    if (!val.contains('@')) return 'Ingresa un correo válido';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Campo Contraseña
                Text(
                  'Contraseña',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.slateMedium),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.slateMedium,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) => (val == null || val.length < 6)
                      ? 'Debe tener al menos 6 caracteres'
                      : null,
                ),

                const SizedBox(height: 20),

                // Selector Ergonómico de Rol
                Text(
                  'Rol en la Formación',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: 'Aprendiz',
                        icon: Icons.school_rounded,
                        isSelected: _selectedRole == 'aprendiz',
                        onTap: () => setState(() => _selectedRole = 'aprendiz'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: 'Instructor',
                        icon: Icons.engineering_rounded,
                        isSelected: _selectedRole == 'instructor',
                        onTap: () => setState(() => _selectedRole = 'instructor'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // Botón Guardar Registro (Zona inferior del pulgar)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Completar Registro',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryDark : AppColors.slateMedium,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryDark : AppColors.slateDark,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
