import 'package:flutter/material.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaCadastroCliente extends StatefulWidget {
  const TelaCadastroCliente({super.key});

  @override
  State<TelaCadastroCliente> createState() => _TelaCadastroClienteState();
}

class _TelaCadastroClienteState extends State<TelaCadastroCliente> {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl = TextEditingController();
  final _cpfCnpjCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _pesquisaCtrl = TextEditingController();

  final supabase = Supabase.instance.client;

  Future<void> salvarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'CLI_NOME': _nomeCtrl.text,
      'CLI_CPF': _cpfCnpjCtrl.text,
      'CLI_ENDERECO': _enderecoCtrl.text,
      'CLI_CIDADE': _cidadeCtrl.text,
      'CLI_ESTADO': _estadoCtrl.text,
      'CLI_TELEFONE': _telefoneCtrl.text,
      'CLI_DATACAD': DateTime.now().toIso8601String(),
      'CLI_ATIVO': true,
    };

    try {
      await supabase.from('Clientes').insert(dados);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente cadastrado com sucesso!')),
      );
      _formKey.currentState!.reset();
      _nomeCtrl.clear();
      _cpfCnpjCtrl.clear();
      _enderecoCtrl.clear();
      _cidadeCtrl.clear();
      _estadoCtrl.clear();
      _telefoneCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar cliente: $e')),
      );
    }
  }

  Future<void> buscarCliente() async {
    final nomeBusca = _pesquisaCtrl.text.trim();

    if (nomeBusca.isEmpty) return;

    final response = await supabase
        .from('Clientes')
        .select()
        .eq('CLI_NOME', nomeBusca)
        .maybeSingle();

    if (response != null) {
      setState(() {
        _nomeCtrl.text = response['CLI_NOME'] ?? '';
        _cpfCnpjCtrl.text = response['CLI_CPF'] ?? '';
        _enderecoCtrl.text = response['CLI_ENDERECO'] ?? '';
        _cidadeCtrl.text = response['CLI_CIDADE'] ?? '';
        _estadoCtrl.text = response['CLI_ESTADO'] ?? '';
        _telefoneCtrl.text = response['CLI_TELEFONE'] ?? '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente não encontrado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Clientes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _pesquisaCtrl,
              decoration: const InputDecoration(
                labelText: 'Pesquisar por Nome',
                suffixIcon: Icon(Icons.search),
              ),
              onFieldSubmitted: (_) => buscarCliente(),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Informe o nome' : null,
                  ),
                  TextFormField(
                    controller: _cpfCnpjCtrl,
                    decoration: const InputDecoration(labelText: 'CPF ou CNPJ'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o CPF ou CNPJ';
                      }
                      final digits = (value);
                      if (digits.length != 11 && digits.length != 14) {
                        return 'CPF ou CNPJ inválido';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _enderecoCtrl,
                    decoration: const InputDecoration(labelText: 'Endereço'),
                  ),
                  TextFormField(
                    controller: _cidadeCtrl,
                    decoration: const InputDecoration(labelText: 'Cidade'),
                  ),
                  TextFormField(
                    controller: _estadoCtrl,
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                  TextFormField(
                    controller: _telefoneCtrl,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneInputFormatter()],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: salvarCliente,
                    child: const Text('Salvar Cliente'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
