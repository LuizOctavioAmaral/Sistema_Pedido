import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaCadastroProduto extends StatefulWidget {
  const TelaCadastroProduto({super.key});

  @override
  State<TelaCadastroProduto> createState() => _TelaCadastroProdutoState();
}

class _TelaCadastroProdutoState extends State<TelaCadastroProduto> {
  final _descricaoController = TextEditingController();
  final _unidadeController = TextEditingController();

  bool _carregando = false;
  List<dynamic> _produtos = [];
  int? _produtoEditandoId;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    final response = await Supabase.instance.client
        .from('Produtos')
        .select()
        .order('PROD_ID', ascending: false);
    setState(() {
      _produtos = response;
    });
  }

  Future<void> _salvarProduto() async {
    final descricao = _descricaoController.text.trim();
    final unidade = _unidadeController.text.trim();

    if (descricao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descrição é obrigatória')),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      if (_produtoEditandoId != null) {
        // Editar produto
        await Supabase.instance.client.from('Produtos').update({
          'PROD_DESCRICAO': descricao,
          'PROD_UNIDADE': unidade,
        }).eq('PROD_ID', _produtoEditandoId!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
      } else {
        // Novo produto
        await Supabase.instance.client.from('Produtos').insert({
          'PROD_DESCRICAO': descricao,
          'PROD_UNIDADE': unidade,
          'PROD_DATACAD': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto cadastrado com sucesso!')),
        );
      }

      _descricaoController.clear();
      _unidadeController.clear();
      _produtoEditandoId = null;
      await _carregarProdutos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _excluirProduto(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir este produto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar != true) return;

    await Supabase.instance.client.from('Produtos').delete().eq('PROD_ID', id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produto excluído')),
    );
    await _carregarProdutos();
  }

  void _preencherEdicao(dynamic produto) {
    setState(() {
      _produtoEditandoId = produto['PROD_ID'];
      _descricaoController.text = produto['PROD_DESCRICAO'] ?? '';
      _unidadeController.text = produto['PROD_UNIDADE'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _produtoEditandoId == null
                  ? 'Cadastro de Produto'
                  : 'Editar Produto ($_produtoEditandoId)',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _unidadeController,
              decoration: const InputDecoration(labelText: 'Unidade (opcional)'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _carregando ? null : _salvarProduto,
                  child: _carregando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_produtoEditandoId == null ? 'Salvar' : 'Atualizar'),
                ),
                if (_produtoEditandoId != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _produtoEditandoId = null;
                        _descricaoController.clear();
                        _unidadeController.clear();
                      });
                    },
                    child: const Text('Cancelar'),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Produtos Cadastrados', style: TextStyle(fontSize: 18)),
            const Divider(),
            ..._produtos.map((produto) => ListTile(
                  title: Text(produto['PROD_DESCRICAO'] ?? ''),
                  subtitle: Text('Unidade: ${produto['PROD_UNIDADE'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _preencherEdicao(produto),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _excluirProduto(produto['PROD_ID']),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
