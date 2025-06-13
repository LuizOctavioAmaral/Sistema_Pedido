import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart' as multi_formatter;
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaCadastroRepresentada extends StatefulWidget {
  const TelaCadastroRepresentada({super.key});

  @override
  State<TelaCadastroRepresentada> createState() => _TelaCadastroRepresentadaState();
}

class _TelaCadastroRepresentadaState extends State<TelaCadastroRepresentada> {
  final _formKey = GlobalKey<FormState>();

  final _cnpjCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _ieCtrl = TextEditingController();
  bool _ativo = true;

  final supabase = Supabase.instance.client;

  Future<void> salvarRepresentada() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'REP_CNPJ': multi_formatter.toNumericString(_cnpjCtrl.text),
      'REP_NOME': _nomeCtrl.text,
      'REP_ENDERECO': _enderecoCtrl.text,
      'REP_CIDADE': _cidadeCtrl.text,
      'REP_ESTADO': _estadoCtrl.text,
      'REP_CEP': multi_formatter.toNumericString(_cepCtrl.text),
      'REP_IE': _ieCtrl.text,
      'REP_ATIVO': _ativo,
      'REP_DATACAD': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('Representadas').insert(dados);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Representada cadastrada com sucesso!')),
      );
      _formKey.currentState!.reset();
      _cnpjCtrl.clear();
      _nomeCtrl.clear();
      _enderecoCtrl.clear();
      _cidadeCtrl.clear();
      _estadoCtrl.clear();
      _cepCtrl.clear();
      _ieCtrl.clear();
      setState(() {
        _ativo = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar representada: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Representada')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cnpjCtrl,
                decoration: const InputDecoration(labelText: 'CNPJ'),
                keyboardType: TextInputType.number,
                inputFormatters: [multi_formatter.MaskedInputFormatter('##.###.###/####-##')],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o CNPJ';
                  }
                  final digits = multi_formatter.toNumericString(value);
                  if (digits.length != 14) {
                    return 'CNPJ inválido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o nome' : null,
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
                controller: _cepCtrl,
                decoration: const InputDecoration(labelText: 'CEP'),
                keyboardType: TextInputType.number,
                inputFormatters: [multi_formatter.MaskedInputFormatter('#####-###')],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o CEP';
                  }
                  final digits = multi_formatter.toNumericString(value);
                  if (digits.length != 8) {
                    return 'CEP inválido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ieCtrl,
                decoration: const InputDecoration(labelText: 'Inscrição Estadual'),
              ),
              SwitchListTile(
                title: const Text('Ativo'),
                value: _ativo,
                onChanged: (bool value) {
                  setState(() {
                    _ativo = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: salvarRepresentada,
                child: const Text('Salvar Representada'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


