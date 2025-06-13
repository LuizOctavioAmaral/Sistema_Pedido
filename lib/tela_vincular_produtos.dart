import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaVincularProdutos extends StatefulWidget {
  const TelaVincularProdutos({super.key});

  @override
  State<TelaVincularProdutos> createState() => _TelaVincularProdutosState();
}

class _TelaVincularProdutosState extends State<TelaVincularProdutos> {
  final supabase = Supabase.instance.client;

  int? _representadaSelecionada;
  int? _produtoSelecionado;
  double? _valorProduto;

  List<Map<String, dynamic>> _representadas = [];
  List<Map<String, dynamic>> _produtos = [];
  List<Map<String, dynamic>> _vinculos = [];

  @override
  void initState() {
    super.initState();
    _carregarRepresentadas();
    _carregarProdutos();
  }

  Future<void> _carregarRepresentadas() async {
    final response = await supabase.from('Representadas').select();
    setState(() {
      _representadas = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _carregarProdutos() async {
    final response = await supabase.from('Produtos').select();
    setState(() {
      _produtos = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _carregarVinculos() async {
    final repId = _representadaSelecionada;
    if (repId == null) return;

    final response = await supabase
        .from('Representada_Produto')
        .select('RPROD_ID, PROD_ID, RPROD_VALOR, RPROD_DATACAD, Produtos(PROD_DESCRICAO)')
        .eq('REP_ID', repId);

    setState(() {
      _vinculos = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _adicionarProduto() async {
    if (_representadaSelecionada == null || _produtoSelecionado == null || _valorProduto == null) return;

    await supabase.from('Representada_Produto').insert({
      'REP_ID': _representadaSelecionada,
      'PROD_ID': _produtoSelecionado,
      'RPROD_VALOR': _valorProduto,
    });

    _valorProduto = null;
    _produtoSelecionado = null;
    await _carregarVinculos();
  }

  Future<void> _removerVinculo(int rprodId) async {
    await supabase.from('Representada_Produto').delete().eq('RPROD_ID', rprodId);
    await _carregarVinculos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Vincular Produtos a Representada'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Representada'),
              value: _representadaSelecionada,
              items: _representadas.map<DropdownMenuItem<int>>((rep) {
  return DropdownMenuItem<int>(
    value: rep['REP_ID'] as int,
    child: Text('${rep['REP_NOME']} (${rep['REP_CNPJ'] ?? 'sem CNPJ'})'),
  );
}).toList(),

              onChanged: (value) {
                setState(() {
                  _representadaSelecionada = value;
                });
                _carregarVinculos();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Produto'),
                    value: _produtoSelecionado,
                    items: _produtos.map<DropdownMenuItem<int>>((prod) {
  return DropdownMenuItem<int>(
    value: prod['PROD_ID'] as int,
    child: Text(prod['PROD_DESCRICAO']),
  );
}).toList(),

                    onChanged: (value) {
                      setState(() {
                        _produtoSelecionado = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Valor'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _valorProduto = double.tryParse(value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _adicionarProduto,
                  child: const Text('Adicionar'),
                )
              ],
            ),
            const SizedBox(height: 24),
            const Text('Produtos vinculados:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _vinculos.length,
                itemBuilder: (context, index) {
                  final item = _vinculos[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['Produtos']['PROD_DESCRICAO']),
                      subtitle: Text('Valor: R\$ ${item['RPROD_VALOR']?.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removerVinculo(item['RPROD_ID']),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
