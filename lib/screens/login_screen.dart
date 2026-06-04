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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
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
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    Icon(Icons.school_rounded, color: cs.onPrimaryContainer, size: 30),
              ),
              const SizedBox(height: 28),
              Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connectez-vous avec votre compte Gustave Eiffel',
                style: TextStyle(
                    fontSize: 14, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),

              // Email
              Text(
                'IDENTIFIANTS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _idController,
                keyboardType: TextInputType.text,
                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'prenom.nom',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: cs.onSurfaceVariant, size: 20),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
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
              Text(
                'MOT DE PASSE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      color: cs.onSurfaceVariant, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: cs.onSurfaceVariant,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
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
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .3),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: cs.onPrimaryContainer),
                        )
                      : const Text('Se connecter'),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Vos identifiants sont ceux de l\'Université Gustave Eiffel',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
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
