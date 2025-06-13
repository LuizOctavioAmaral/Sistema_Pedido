import 'package:flutter/material.dart';
import 'package:rep_sistema/tela_cadastro_cliente.dart';
import 'package:rep_sistema/tela_cadastro_usuario.dart'; // <- importar aqui
import 'package:rep_sistema/tela_login.dart';
import 'package:rep_sistema/tela_cadastro_produto.dart';
import 'package:rep_sistema/tela_vincular_produtos.dart';
import 'package:rep_sistema/tela_cadastro_representada.dart';
import 'package:rep_sistema/tela_pedidos.dart';



class TelaMenu extends StatefulWidget {
  final String usuario;

  const TelaMenu({super.key, required this.usuario});

  @override
  State<TelaMenu> createState() => _TelaMenuState();
}

class _TelaMenuState extends State<TelaMenu> {
  String _telaAtual = 'Home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          // MENU LATERAL
          Container(
            width: 220,
            color: Colors.blue.shade700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.blue.shade900,
                  child: Text(
                    'Bem-vindo\n${widget.usuario}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                _itemMenu('Clientes', Icons.people),
                _itemMenu('Vincular Produtos', Icons.link),
                _itemMenu('Representada', Icons.business),
                _itemMenu('Produtos', Icons.inventory),
                _itemMenu('Pedidos', Icons.shopping_cart),
                _itemMenu('Usuários', Icons.person_add),
                const Spacer(),
                _itemMenu('Sair', Icons.exit_to_app, sair: true),
              ],
            ),
          ),

          // CONTEÚDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildConteudo(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMenu(String titulo, IconData icone, {bool sair = false}) {
    return ListTile(
      leading: Icon(icone, color: Colors.white),
      title: Text(titulo, style: const TextStyle(color: Colors.white)),
      hoverColor: Colors.blue.shade300,
      selected: _telaAtual == titulo,
      selectedTileColor: Colors.blue.shade400,
      onTap: () {
        if (sair) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TelaLogin()),
          );
        } else {
          setState(() {
            _telaAtual = titulo;
          });
        }
      },
    );
  }

  Widget _buildConteudo() {
    switch (_telaAtual) {
      case 'Clientes':
        return const TelaCadastroCliente();
      case 'Usuários':
        return const TelaCadastroUsuario(); // <- Aqui entra a tela de usuários
      case 'Produtos':
        return const TelaCadastroProduto();
      case 'Vincular Produtos':
        return const TelaVincularProdutos();
      case 'Representada':
        return const TelaCadastroRepresentada();
      case 'Pedidos':
        return const TelaPedidos();
      case 'Home':
        return Center(
          child: Text(
            'Tela de $_telaAtual (em breve)',
            style: const TextStyle(fontSize: 20),
          ),
        );
      default:
        return Center(
          child: Text(
            'Selecione uma opção no menu',
            style: TextStyle(fontSize: 20, color: Colors.grey.shade700),
          ),
        );
    }
  }
}
