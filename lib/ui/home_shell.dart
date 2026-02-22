// lib/ui/home_shell.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

import '../models/categories.dart';
import '../theme.dart';

// --- Imports de Pantallas ---
import 'home/home_feed_screen.dart';
import 'muro/community_wall_screen.dart';
import 'user/user_profile_screen.dart';
import 'chat/chat_list_screen.dart';

// --- Servicios y Providers ---
import 'package:firebase_auth/firebase_auth.dart';
import '../services/presence_service.dart';
import '../providers/blocked_users_provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late PresenceService _presenceService;
  
  // Ya no necesitamos controladores de páginas ni índices 
  // porque es una sola pantalla vertical infinita.

  @override
  void initState() {
    super.initState();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      // 1. Iniciar servicio de presencia (Online)
      _presenceService = PresenceService(userId: userId);
      _presenceService.init();

      // 2. CARGAR LISTA NEGRA (BLOQUEOS)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<BlockedUsersProvider>(context, listen: false).init();
      });
    }
  }

  @override
  void dispose() {
    // _pageController.dispose(); // Ya no existe
    _presenceService.dispose(); 
    super.dispose();
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
  }

  void _navigateToProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
  }

  // Menú de ajustes simplificado (que tenías antes, luego puedes poner el nuevo BottomSheet aquí si quieres)
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              leading: Icon(Icons.settings_rounded, color: Colors.white),
              title: Text('Ajustes', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                _navigateToProfile();
              },
            ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openChat() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const ChatListScreen())
    );
  }

  void _openWall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityWallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el color principal de la marca para el degradado sutil del fondo
    final Color accent = colorForCategory(Category.todos); 

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: .06), Colors.transparent],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Para que se vea el gradiente del Container
        appBar: null,
        
        body: SafeArea( 
          bottom: false, 
          // 🔥 AQUÍ ESTÁ EL CAMBIO: Ya no hay PageView, solo la pantalla principal
          child: HomeFeedScreen(
            // Pasamos 'todos' solo para cumplir con el constructor, 
            // aunque adentro ya modificamos para que ignore categorías.
            category: Category.todos, 
            onOpenWall: _openWall,
            onOpenProfile: _navigateToProfile,
            onOpenSettings: _openSettings,
            onOpenChat: _openChat, 
          ),
        ),
        
        // ❌ BottomNavigationBar ELIMINADO
      ),
    );
  }
}