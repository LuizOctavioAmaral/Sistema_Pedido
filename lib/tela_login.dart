import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tela_menu.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  Future<void> _fazerLogin() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      if (response.user != null) {
        // Login bem-sucedido
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TelaMenu(usuario: email),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() => _erro = e.message);
    } catch (e) {
      setState(() => _erro = 'Erro desconhecido. Tente novamente.');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: _senhaController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 20),
            if (_erro != null)
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            if (_carregando)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _fazerLogin,
                child: const Text('Entrar'),
              ),
          ],
        ),
      ),
    );
  }
}
