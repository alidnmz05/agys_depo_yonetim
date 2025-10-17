// lib/pages/login_page.dart  (revizyon: OpenAPI uyumlu)
import 'package:flutter/material.dart';
import 'package:agys_depo_yonetim/models/auth_api.dart';
import 'package:agys_depo_yonetim/services/settings_controller.dart';
import 'package:agys_depo_yonetim/pages/beyanname_liste_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _eposta = TextEditingController();
  final _sifre = TextEditingController();
  final _antrepoKodu = TextEditingController();
  bool _loading = false;
  String? _error;
  final _sc = SettingsController.instance;

  @override
  void dispose() {
    _eposta.dispose();
    _sifre.dispose();
    _antrepoKodu.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AuthApi.instance.login(
      eposta: _eposta.text,
      sifre: _sifre.text,
      antrepoKodu: _antrepoKodu.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    if (res.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BeyannameListePage()),
      );
    } else {
      setState(() {
        _error = res.message ?? 'Giriş başarısız';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Giriş',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _eposta,
                      decoration: const InputDecoration(labelText: 'E-posta'),
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _sifre,
                      decoration: const InputDecoration(labelText: 'Şifre'),
                      obscureText: true,
                      validator:
                          (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _antrepoKodu,
                      decoration: const InputDecoration(
                        labelText: 'Antrepo Kodu',
                      ),
                      validator:
                          (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child:
                          _loading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Giriş Yap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
