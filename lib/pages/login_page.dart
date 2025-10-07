import 'package:flutter/material.dart';
import 'beyanname_liste_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _antrepoKoduCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();

  bool _loading = false;
  bool _sifreGoster = false;

  // Hardcoded credentials
  static const _dogruEmail = 'adamar.antrepo@dalyanygm.com';
  static const _dogruAntrepoKodu = 'C35000352';
  static const _dogruSifre = '1234';

  void _girisYap() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // Simüle edilmiş yükleme
    await Future.delayed(const Duration(seconds: 1));

    if (_emailCtrl.text == _dogruEmail &&
        _antrepoKoduCtrl.text == _dogruAntrepoKodu &&
        _sifreCtrl.text == _dogruSifre) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BeyannameListePage()),
      );
    } else {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-posta, antrepo kodu veya şifre hatalı!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo veya başlık
                  Icon(
                    Icons.inventory_2,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Antrepo Yönetim',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Giriş Yapın',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // E-posta
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'E-posta gerekli';
                      if (!v.contains('@')) return 'Geçerli e-posta girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Antrepo Kodu
                  TextFormField(
                    controller: _antrepoKoduCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Antrepo Kodu',
                      prefixIcon: Icon(Icons.warehouse_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Antrepo kodu gerekli';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Şifre
                  TextFormField(
                    controller: _sifreCtrl,
                    obscureText: !_sifreGoster,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _sifreGoster ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _sifreGoster = !_sifreGoster),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Şifre gerekli';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Giriş Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _loading ? null : _girisYap,
                      child: _loading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Giriş Yap', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _antrepoKoduCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }
}