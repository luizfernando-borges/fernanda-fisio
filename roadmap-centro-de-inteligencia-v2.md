# Centro de Inteligência — Roadmap de Evolução (v2)

Documento de planejamento, não de execução. Nada aqui foi construído ainda — é a base pra decisão do time sobre por onde seguir.

## 1. Contexto

O Centro de Inteligência hoje cobre: Dashboard (vendas), Visão Operacional (Expedição/Full/Recebimento/Garantias), Centro de Qualidade (Reclamações/Devoluções), Visão Geral da Operação (consolidado Blowback+HGZ), Integrações (conexão de planilhas) e um webhook que atualiza os dados sozinho quando a planilha é editada. Todo o produto já é multi-empresa (troca entre Blowback/HGZ pelo seletor no topo) e tem módulos reservados no menu ("em breve"): Comercial, Estoque, Logística, Projetos, Reuniões.

Depois de ver o software de referência do cliente, a ideia é evoluir de "painel de indicadores" pra um sistema de gestão mais completo: comunicação de time, tarefas, reconhecimento e atendimento tudo no mesmo lugar, alimentando o mesmo banco de dados.

## 2. Arquitetura geral proposta

```
Home (Dashboard executivo)
├─ Seletor de Empresa (grupo → CNPJ)              [já existe]
├─ Seletor de Canal/Marketplace                    [Fase 2, já mapeado]
├─ Calendário + Avisos                              [novo]
Reuniões                                            [novo — módulo já reservado no menu]
Tarefas (evolução do Plano de Ação)                 [evolução]
Tickets (evolução do Centro de Qualidade)           [evolução — maior prioridade]
Avisos / Mural do time                              [novo]
Premiações e Reconhecimento                         [novo — domínio isolado]
Visão Operacional / Visão Geral / Comercial /
Estoque / Logística / Projetos                      [já existem ou já reservados]
```

Princípio que já vem sendo seguido no projeto e que continua valendo pra tudo daqui pra frente: nenhum número aparece sem dado real por trás ("Aguardando dados" em vez de zero inventado); toda lógica de negócio fica numa camada de serviço (`lib/`), nunca dentro da tela; multi-empresa sempre isolado por `companyId`.

## 3. Módulos — o que já existe, o que evolui, o que é novo

### 3.1 Tickets (evolução do Centro de Qualidade) — maior prioridade

**O que é:** os atendimentos/reclamações passam a ser criados direto no sistema, por formulário, além de (ou no lugar de) importar da planilha trimestral.

**Por que é prioridade:** resolve uma dor que já vivemos essa semana — a planilha de Reclamações é trimestral, precisa ser reconectada manualmente a cada troca de trimestre, e qualquer mudança de estrutura da planilha quebra a importação. Um formulário dentro do sistema elimina essa dependência.

**Reaproveita:** o modelo `QualityCase` já existe, já tem todos os campos certos (Status E-commerce/Expedição, Responsável, Detalhes, Loja, Marketplace). Os KPIs, gráficos e Top 10 do Centro de Qualidade e da Visão Geral já leem dessa tabela — não muda nada na exibição, só ganha uma segunda porta de entrada.

**Constrói:** formulário de criação/edição de caso; decidir quem pode criar (time de atendimento) e quem só visualiza; a planilha continua podendo ser usada em paralelo pra importação em massa, se fizer sentido, ou ser desligada.

**Decisão que precisa do time:** manter a planilha como opção de importação em paralelo, ou migrar 100% para criação manual no sistema?

### 3.2 Tarefas (evolução do Plano de Ação)

**O que é:** liderança atribui tarefa para o time; cada analista também cria as próprias tarefas; tudo aparece numa agenda pessoal (ex.: "revisar anúncio X dia 15", "mexer no Full estoque dia 9").

**Reaproveita:** já existe um módulo "Plano de Ação" (`ActionItem`), hoje alimentado só pelo motor de alertas automáticos (ex.: "importação falhou → criar ação").

**Constrói:** permitir criação manual de tarefa (não só via alerta automático); campo de responsável e data; visão de calendário pessoal por analista; hierarquia simples (quem atribuiu para quem).

**Decisão que precisa do time:** o motor de alertas automáticos continua criando tarefa sozinho como já faz, ou vira só uma sugestão que alguém aprova?

### 3.3 Reuniões / Calendário

**O que é:** agenda de reuniões de time, com parceiros, com fornecedores — todo mundo vê quem está ocupado.

**Já reservado:** "Reuniões" já existe como item de menu marcado "em breve" desde o início do projeto.

**Constrói:** do zero — modelo de Reunião/Evento, participantes, integração com a agenda de Tarefas (mesma tela de calendário pode mostrar os dois).

### 3.4 Avisos / Mural do time

**O que é:** comunicados do time — campanhas do Mercado Livre, estratégias da liderança, treinamentos.

**Importante:** isto é diferente dos alertas operacionais que o sistema já gera sozinho (ex.: "importação falhou", "recebimento aguardando conferência"). Aviso é conteúdo humano, postado por alguém; alerta é gerado pelo sistema a partir do dado. Não devem virar a mesma coisa.

**Constrói:** do zero — mural simples, quem pode postar, se tem prazo de validade, se aparece na Home.

### 3.5 Premiações e Reconhecimento

**O que é:** funcionário do mês, bonificações, política de incentivos.

**Mais isolado de tudo:** não tem ponte natural com o que já existe — é o único módulo puramente de RH/gente, sem se apoiar em dado operacional.

**Decisão que precisa do time:** vale a pena definir a política de incentivos (as regras) antes de desenhar a tela — sem isso não dá pra saber que dado o sistema precisa guardar.

### 3.6 Seletor de Canal/Marketplace (Fase 2 já documentada)

**O que é:** ver a operação por canal (Mercado Livre, Shopee, Site), não só por empresa.

**Já mapeado:** esse é exatamente o gap já registrado em `docs/visao-geral-operacao-v1.md` — a planilha tem a coluna Marketplace, mas hoje ela só fica guardada em texto solto, não em formato que dá pra somar/filtrar. Resolver isso destrava não só esse seletor, como os KPIs por canal que já estão pendentes na Visão Geral.

## 4. Ordem recomendada

1. **Tickets no Centro de Qualidade** — maior prioridade. Resolve dor já sentida, reaproveita mais, menor risco.
2. **Tarefas (evolução do Plano de Ação)** — segunda maior prioridade, reaproveita bastante, ajuda a organizar o time desde já.
3. **Canal/Marketplace estruturado (Fase 2)** — tecnicamente independente das duas acima, pode entrar em paralelo se houver capacidade.
4. **Reuniões/Calendário** — novo, mas de escopo bem definido.
5. **Avisos/Mural** — novo, escopo pequeno, pode vir junto com Reuniões.
6. **Premiações e Reconhecimento** — por último; depende de decisão de política antes de qualquer tela.

## 5. O que NÃO está neste plano

Este documento não cobre: prazos, estimativa de tempo por módulo, nem changes de UI visual (cores, layout fino) — isso entra na hora de detalhar cada módulo, um de cada vez, depois que o time decidir a ordem.

## 6. Próximo passo

Depois da conversa com o time: escolher qual módulo entra primeiro (recomendação: Tickets) e eu volto com o desenho detalhado só daquele módulo — telas, campos, e o que precisa de decisão de vocês antes de eu construir.
