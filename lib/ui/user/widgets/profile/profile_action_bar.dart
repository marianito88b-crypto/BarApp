import 'package:flutter/material.dart';

/// Barra de acciones horizontales del perfil
/// 
/// Organiza los botones (Editar, Mensaje, Reservas) de forma horizontal
/// usando botones de icono minimalistas
class ProfileActionBar extends StatelessWidget {
  final bool isOwnProfile;
  final bool isBlocked;
  final VoidCallback? onEdit;
  final VoidCallback? onMessage;
  final VoidCallback? onReservations;
  final Color accentColor;

  const ProfileActionBar({
    super.key,
    required this.isOwnProfile,
    required this.isBlocked,
    this.onEdit,
    this.onMessage,
    this.onReservations,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      // Botones para perfil propio
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.edit_rounded,
              label: 'Editar',
              onTap: onEdit,
              accentColor: accentColor,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.calendar_today_rounded,
              label: 'Reservas',
              onTap: onReservations,
              accentColor: accentColor,
              isPrimary: true,
            ),
          ),
        ],
      );
    } else {
      // Botón de mensaje para perfil ajeno (si no está bloqueado)
      if (isBlocked) {
        return const SizedBox.shrink();
      }
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.message_rounded,
              label: 'Enviar Mensaje',
              onTap: onMessage,
              accentColor: accentColor,
              isPrimary: true,
            ),
          ),
        ],
      );
    }
  }
}

/// Botón de acción individual minimalista
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color accentColor;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accentColor,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
