// lib/ui/auth/complete_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🚀 IMPORTAMOS TU HOME SHELL PARA NAVEGAR SEGURO
import 'package:barapp/ui/home_shell.dart'; 

class CompleteProfileScreen extends StatefulWidget {
  final User user;

  const CompleteProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-llenamos con el nombre de Google si existe
    final currentName = widget.user.displayName ?? '';
    if (currentName.trim().isNotEmpty &&
        currentName.trim().toLowerCase() != 'sin nombre') {
      _nameCtrl.text = currentName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final name = _nameCtrl.text.trim();

    try {
      // 1) Actualizamos el displayName en Auth (Firebase)
      await widget.user.updateDisplayName(name);
      await widget.user.reload(); // Recargamos para asegurar que impacte

      // 2) Guardamos en Firestore con los campos CORRECTOS
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user.uid)
          .set(
        {
          'displayName': name,          
          'nombre': name, // Guardamos ambos por compatibilidad
          'email': widget.user.email, // Útil tener el mail
          'hasCompletedProfile': true, // 👈 CORREGIDO: Debe coincidir con user_profile_service
          'role': 'user', // Rol por defecto
          'updatedAt': FieldValue.serverTimestamp(),
          
          // Si trae foto de Google, la guardamos
          if (widget.user.photoURL != null && widget.user.photoURL!.isNotEmpty)
            'imageUrl': widget.user.photoURL,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      // 3) NAVEGACIÓN SEGURA AL HOME
      // Usamos pushAndRemoveUntil con MaterialPageRoute para no depender de rutas nombradas
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false, // Borra todo el historial para que no pueda volver atrás
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Completar perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Sin botón de atrás
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.waving_hand, size: 40, color: Colors.amber),
              const SizedBox(height: 20),
              
              const Text(
                '¡Bienvenido!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Para terminar de configurar tu cuenta, necesitamos saber cómo querés que te llamen en la app.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tu nombre o Apodo',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person, color: Colors.amber),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'El nombre es obligatorio';
                  if (text.length < 3) return 'Mínimo 3 letras';
                  return null;
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Text('Continuar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}