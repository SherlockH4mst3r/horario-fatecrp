import 'package:flutter/material.dart';
import 'package:grade/grade.dart';

import '../telas/moldura.dart';
import 'correcao_de_aulas.dart';
import 'entrada_do_admin.dart';
import 'importacao_da_planilha.dart';
import 'sessao.dart';

export 'importacao_da_planilha.dart' show EscolherPlanilha, SalvarPlanilha;

/// O painel `/admin`: entrada do admin, importação da planilha do semestre letivo e correção de aulas avulsas.
class PainelAdmin extends StatefulWidget {
  const PainelAdmin({
    super.key,
    required this.sessao,
    required this.importacao,
    required this.edicao,
    required this.escolherPlanilha,
    required this.salvarPlanilha,
  });

  final Sessao sessao;
  final ImportacaoDeGrade importacao;
  final EdicaoDeAulas edicao;
  final EscolherPlanilha escolherPlanilha;
  final SalvarPlanilha salvarPlanilha;

  @override
  State<PainelAdmin> createState() => _PainelAdminState();
}

enum _Area { importar, corrigir }

class _PainelAdminState extends State<PainelAdmin> {
  _Area _area = _Area.importar;

  Future<void> _sair() async {
    await widget.sessao.sair();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ativa = widget.sessao.ativa;
    return Scaffold(
      body: ListView(
        children: [
          CabecalhoFatec(
            titulo: 'Painel do admin',
            acao: ativa
                ? OutlinedButton(
                    onPressed: _sair,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    child: const Text('Sair'),
                  )
                : null,
          ),
          ColunaDeConteudo(
            children: [
              const SizedBox(height: 24),
              if (ativa) ...[
                SegmentedButton<_Area>(
                  segments: const [
                    ButtonSegment(
                      value: _Area.importar,
                      label: Text('Importar planilha'),
                      icon: Icon(Icons.upload_file),
                    ),
                    ButtonSegment(value: _Area.corrigir, label: Text('Corrigir aulas'), icon: Icon(Icons.edit_note)),
                  ],
                  selected: {_area},
                  onSelectionChanged: (escolha) => setState(() => _area = escolha.single),
                ),
                const SizedBox(height: 24),
                switch (_area) {
                  _Area.importar => ImportacaoDaPlanilha(
                    importacao: widget.importacao,
                    escolherPlanilha: widget.escolherPlanilha,
                    salvarPlanilha: widget.salvarPlanilha,
                  ),
                  _Area.corrigir => CorrecaoDeAulas(edicao: widget.edicao),
                },
              ] else
                EntradaDoAdmin(sessao: widget.sessao, aoEntrar: () => setState(() {})),
            ],
          ),
        ],
      ),
    );
  }
}
