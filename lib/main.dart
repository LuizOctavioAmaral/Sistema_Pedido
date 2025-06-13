import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tela_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iekrwuoervgoqigmpluq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlla3J3dW9lcnZnb3FpZ21wbHVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk1MjU3ODEsImV4cCI6MjA2NTEwMTc4MX0.dPKOwOWIV7opbzWCqlSo32E9aie_mS9ROTR3n9qssMA',
  );

 runApp(const MeuAppWeb());
}

class MeuAppWeb extends StatelessWidget {
  const MeuAppWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Representante',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TelaLogin(), // <- menu direto
    );
  }
}