import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class TelaPedidos extends StatefulWidget {
  const TelaPedidos({super.key});

  @override
  State<TelaPedidos> createState() => _TelaPedidosState();
}

class _TelaPedidosState extends State<TelaPedidos> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para os campos do pedido principal
  final _pedNumCtrl = TextEditingController();
  double _pedTotal = 0.0;

  // IDs para as chaves estrangeiras
  int? _repId;
  int? _cliId;
  String? _usrId; // UUID do usuário logado

  // Campo para o status do pedido
  String? _pedStatus = 'A'; // 'A' para Aberto, 'F' para Fechado, 'C' para Cancelado
  final Map<String, String> _statusOptions = {
    'A': 'Aberto',
    'F': 'Fechado',
    'C': 'Cancelado',
  };

  // Listas para armazenar dados de Representadas, Clientes e Produtos disponíveis
  List<Map<String, dynamic>> _representadas = [];
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _produtosDisponiveis = [];

  // Lista para armazenar os produtos do pedido
  List<Map<String, dynamic>> _produtosPedido = [];

  // Lista para armazenar os pedidos existentes
  List<Map<String, dynamic>> _pedidosList = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _usrId = supabase.auth.currentUser?.id;
    _fetchRepresentadas();
    _fetchClientes();
    _fetchPedidos(); // Adicionando a chamada para buscar pedidos existentes
  }

  Future<void> _fetchRepresentadas() async {
    try {
      final data = await supabase.from('Representadas').select('REP_ID, REP_NOME').order('REP_NOME', ascending: true);
      setState(() {
        _representadas = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar representadas: $e')),
      );
    }
  }

  Future<void> _fetchClientes() async {
    try {
      final data = await supabase.from('Clientes').select('CLI_ID, CLI_NOME').order('CLI_NOME', ascending: true);
      setState(() {
        _clientes = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar clientes: $e')),
      );
    }
  }

  Future<void> _fetchProdutosPorRepresentada(int repId) async {
    try {
      // Primeiro, selecione os produtos da Representada_Produto
      final dataRepresentadaProduto = await supabase
          .from('Representada_Produto')
          .select('PROD_ID, RPROD_VALOR')
          .eq('REP_ID', repId);

      // Extraia os PROD_ID para buscar os nomes dos produtos
      final List<int> prodIds = dataRepresentadaProduto.map<int>((e) => e['PROD_ID'] as int).toList();

      // Busque os nomes dos produtos na tabela Produtos
      final dataProdutos = await supabase
          .from('Produtos')
          .select('PROD_ID, PROD_NOME')
          .inFilter('PROD_ID', prodIds);

      // Crie um mapa para fácil acesso aos nomes dos produtos
      final Map<int, String> nomesProdutos = {
        for (var prod in dataProdutos) prod['PROD_ID'] as int: prod['PROD_NOME'] as String
      };

      // Combine os dados para criar a lista _produtosDisponiveis
      final List<Map<String, dynamic>> produtosCombinados = [];
      for (var rp in dataRepresentadaProduto) {
        produtosCombinados.add({
          'PROD_ID': rp['PROD_ID'],
          'RPROD_VALOR': rp['RPROD_VALOR'],
          'Produtos': {'PROD_NOME': nomesProdutos[rp['PROD_ID']]}
        });
      }

      setState(() {
        _produtosDisponiveis = produtosCombinados;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos da representada: $e')),
      );
    }
  }

  Future<void> _fetchPedidos() async {
    try {
      final data = await supabase
          .from('Pedidos')
          .select('*, Clientes(CLI_NOME), Representadas(REP_NOME)') // Incluindo nomes de cliente e representada
          .order('PED_CADDATA', ascending: false);
      setState(() {
        _pedidosList = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pedidos: $e')),
      );
    }
  }

  void _adicionarProdutoAoPedido(Map<String, dynamic> produto) {
    setState(() {
      _produtosPedido.add(produto);
      _calcularTotalPedido();
    });
  }

  void _removerProdutoDoPedido(int index) {
    setState(() {
      _produtosPedido.removeAt(index);
      _calcularTotalPedido();
    });
  }

  void _calcularTotalPedido() {
    double total = 0.0;
    for (var produto in _produtosPedido) {
      total += produto['PPROD_TOTAL'];
    }
    setState(() {
      _pedTotal = total;
    });
  }

  Future<void> _showAddProductDialog() async {
    if (_repId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma Representada primeiro.')),
      );
      return;
    }

    // Garante que os produtos da representada selecionada estejam carregados
    await _fetchProdutosPorRepresentada(_repId!);

    int? selectedProdId;
    double quantidade = 1.0;
    double desconto = 0.0;
    double acrescimo = 0.0;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Produto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Produto'),
                  value: selectedProdId,
                  items: _produtosDisponiveis.map((prod) {
                    return DropdownMenuItem<int>(
                      value: prod['PROD_ID'],
                      child: Text(prod['Produtos']['PROD_NOME'] + ' (R\$ ' + prod['RPROD_VALOR'].toStringAsFixed(2) + ')')
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    selectedProdId = newValue;
                  },
                  validator: (value) =>
                      value == null ? 'Selecione um produto' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                  keyboardType: TextInputType.number,
                  initialValue: '1.0',
                  onChanged: (value) {
                    quantidade = double.tryParse(value) ?? 1.0;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Desconto (%)'),
                  keyboardType: TextInputType.number,
                  initialValue: '0.0',
                  onChanged: (value) {
                    desconto = double.tryParse(value) ?? 0.0;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Acréscimo (%)'),
                  keyboardType: TextInputType.number,
                  initialValue: '0.0',
                  onChanged: (value) {
                    acrescimo = double.tryParse(value) ?? 0.0;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Adicionar'),
              onPressed: () {
                if (selectedProdId != null) {
                  final produtoSelecionado = _produtosDisponiveis.firstWhere(
                      (prod) => prod['PROD_ID'] == selectedProdId);
                  final valorUnitario = produtoSelecionado['RPROD_VALOR'];
                  final totalProduto = (valorUnitario * quantidade) * (1 - desconto / 100) * (1 + acrescimo / 100);

                  _adicionarProdutoAoPedido({
                    'PROD_ID': selectedProdId,
                    'PROD_NOME': produtoSelecionado['Produtos']['PROD_NOME'],
                    'PPROD_QTD': quantidade,
                    'PPROD_DESC': desconto,
                    'PPROD_ACRESC': acrescimo,
                    'PPROD_TOTAL': totalProduto,
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> salvarPedido() async {
    if (!_formKey.currentState!.validate()) return;

    // Dados para a tabela Pedidos
    final dadosPedido = {
      'REP_ID': _repId,
      'CLI_ID': _cliId,
      'USR_ID': _usrId,
      'PED_NUM': _pedNumCtrl.text,
      'PED_TOTAL': _pedTotal,
      'PED_CADDATA': DateTime.now().toIso8601String(),
      'PED_STATUS': _pedStatus, // Adicionando o status do pedido
    };

    try {
      // Inserir na tabela Pedidos
      final responsePedido = await supabase.from('Pedidos').insert(dadosPedido).select();
      final pedId = responsePedido[0]['PED_ID'];

      // Inserir na tabela Pedidos_Produto
      for (var produto in _produtosPedido) {
        final dadosProdutoPedido = {
          'PED_ID': pedId, // Link com o pedido principal
          'PROD_ID': produto['PROD_ID'],
          'PPROD_QTD': produto['PPROD_QTD'],
          'PPROD_DESC': produto['PPROD_DESC'],
          'PPROD_ACRESC': produto['PPROD_ACRESC'],
          'PPROD_TOTAL': produto['PPROD_TOTAL'],
          'PPROD_DATACAD': DateTime.now().toIso8601String(),
        };
        await supabase.from('Pedidos_Produto').insert(dadosProdutoPedido);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido salvo com sucesso!')),
      );
      _formKey.currentState!.reset();
      _pedNumCtrl.clear();
      setState(() {
        _pedTotal = 0.0;
        _repId = null;
        _cliId = null;
        _pedStatus = 'A'; // Resetar para 'Aberto' após salvar
        _produtosPedido = [];
      });
      _fetchPedidos(); // Atualiza a lista de pedidos após salvar um novo
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar pedido: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Pedidos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Campo para o número do pedido
              TextFormField(
                controller: _pedNumCtrl,
                decoration: const InputDecoration(labelText: 'Número do Pedido'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o número do pedido' : null,
              ),
              const SizedBox(height: 16),

              // Seleção de Representada
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Representada'),
                value: _repId,
                items: _representadas.map((rep) {
                  return DropdownMenuItem<int>(
                    value: rep['REP_ID'],
                    child: Text(rep['REP_NOME']),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _repId = newValue;
                    _produtosDisponiveis = []; // Limpa produtos ao mudar de representada
                    _produtosPedido = []; // Limpa produtos do pedido
                    _calcularTotalPedido();
                    if (newValue != null) {
                      _fetchProdutosPorRepresentada(newValue);
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione uma Representada' : null,
              ),
              const SizedBox(height: 16),

              // Seleção de Cliente
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Cliente'),
                value: _cliId,
                items: _clientes.map((cli) {
                  return DropdownMenuItem<int>(
                    value: cli['CLI_ID'],
                    child: Text(cli['CLI_NOME']),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _cliId = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione um Cliente' : null,
              ),
              const SizedBox(height: 16),

              // Seleção de Status do Pedido
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status do Pedido'),
                value: _pedStatus,
                items: _statusOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _pedStatus = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione o Status do Pedido' : null,
              ),
              const SizedBox(height: 16),

              // Botão para adicionar produtos
              ElevatedButton(
                onPressed: _showAddProductDialog,
                child: const Text('Adicionar Produto'),
              ),
              const SizedBox(height: 16),

              // Lista de produtos no pedido
              _produtosPedido.isEmpty
                  ? const Text('Nenhum produto adicionado ao pedido.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _produtosPedido.length,
                      itemBuilder: (context, index) {
                        final produto = _produtosPedido[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(produto['PROD_NOME']),
                            subtitle: Text(
                                'Qtd: ${produto['PPROD_QTD']} | Total: R\$ ${produto['PPROD_TOTAL'].toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removerProdutoDoPedido(index),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 16),

              Text(
                'Total do Pedido: R\$ ${_pedTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: salvarPedido,
                child: const Text('Salvar Pedido'),
              ),

              const Divider(height: 32, thickness: 2),
              const Text(
                'Pedidos Existentes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _pedidosList.isEmpty
                  ? const Text('Nenhum pedido encontrado.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pedidosList.length,
                      itemBuilder: (context, index) {
                        final pedido = _pedidosList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('Pedido Nº: ${pedido['PED_NUM']} - ${pedido['Clientes']['CLI_NOME']}'),
                            subtitle: Text(
                                'Representada: ${pedido['Representadas']['REP_NOME']} | Status: ${_statusOptions[pedido['PED_STATUS']]} | Total: R\$ ${pedido['PED_TOTAL'].toStringAsFixed(2)}'),
                            // Você pode adicionar mais detalhes ou ações aqui, como um botão para ver detalhes do pedido
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}


