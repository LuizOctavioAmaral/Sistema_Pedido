import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tela_login.dart';

class TelaCadastroUsuario extends StatefulWidget {
  const TelaCadastroUsuario({super.key});

  @override
  State<TelaCadastroUsuario> createState() => _TelaCadastroUsuarioState();
}

class _TelaCadastroUsuarioState extends State<TelaCadastroUsuario> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _carregando = false;
  String? _erro;
  String? _sucesso;

  Future<void> _cadastrar() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _sucesso = null;
    });

    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmar = _confirmarSenhaController.text;

    if (senha != confirmar) {
      setState(() {
        _erro = 'As senhas não coincidem.';
        _carregando = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: senha,
      );

      if (response.user != null) {
        setState(() => _sucesso = 'Cadastro realizado com sucesso!');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TelaLogin()),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() => _erro = e.message);
    } catch (e) {
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Usuário')),
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
            TextField(
              controller: _confirmarSenhaController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar Senha'),
            ),
            const SizedBox(height: 20),
            if (_erro != null)
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            if (_sucesso != null)
              Text(_sucesso!, style: const TextStyle(color: Colors.green)),
            if (_carregando)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _cadastrar,
                child: const Text('Cadastrar'),
              ),
          ],
        ),
      ),
    );
  }
}
