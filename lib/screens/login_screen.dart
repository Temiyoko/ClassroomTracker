import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  static const _bg = Color(0xFF0F0D13);
  static const _surface = Color(0xFF1C1A22);
  static const _primary = Color(0xFFC9B8FF);
  static const _priContainer = Color(0xFF3A2E6A);
  static const _t1 = Color(0xFFEDE8F5);
  static const _t3 = Color(0xFF7B7585);

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _idController.text.trim();
    setState(() {
      _loading = true;
    });
    await context.read<AuthService>().login(identifier, _passwordController.text);
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Logo / branding
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _priContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    const Icon(Icons.school_rounded, color: _primary, size: 30),
              ),
              const SizedBox(height: 28),
              const Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: _t1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Connectez-vous avec votre compte Gustave Eiffel',
                style: TextStyle(
                    fontSize: 14, color: _t3, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),

              // Email
              const Text(
                'IDENTIFIANTS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _t3,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _idController,
                keyboardType: TextInputType.text,
                style: const TextStyle(color: _t1, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'prenom.nom',
                  hintStyle: const TextStyle(color: _t3),
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: _t3, size: 20),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Password
              const Text(
                'MOT DE PASSE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _t3,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                style: const TextStyle(color: _t1, fontWeight: FontWeight.w600),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: const TextStyle(color: _t3),
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: _t3, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _t3,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 32),

              // Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _priContainer,
                    foregroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .3),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: _primary),
                        )
                      : const Text('Se connecter'),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Vos identifiants sont ceux de l\'Université Gustave Eiffel',
                  style: const TextStyle(
                      fontSize: 12, color: _t3, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
