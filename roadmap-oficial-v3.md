# Roadmap Oficial v3 — Centro de Inteligência

Status: **aprovado como base técnica e estratégica**, com 2 ajustes obrigatórios do Head de Produto sobre o Plano Combinado. Documento de decisão — nada aqui foi codificado.

## Decisões já aprovadas (sem mudança)

- Concluir a Fase 1 antes de expandir.
- Não criar `Group`, `LegalEntity` nem RBAC completo agora.
- Não separar Home do Dashboard enquanto não houver conteúdo real (Tarefas/Avisos) para preencher.
- Permitir criação manual no Centro de Qualidade.
- Manter a planilha de Qualidade em transição híbrida (importação + criação manual convivendo).
- Separar Aviso (conteúdo humano) de Alerta (gerado pelo sistema a partir do dado).
- Adiar Reconhecimentos até existir política definida.
- Reorganizar o menu gradualmente, sem criar dezenas de telas vazias.

---

## Ajuste 1 — Canal/Marketplace sobe para a Fase 2

Aceito o argumento: não é mais um gap hipotético, é um gap já documentado no próprio código em três lugares — que valem como prova de que a necessidade é real, não projetada:

- `lib/control-tower/expedicao.ts`: "a planilha operacional tem a coluna Marketplace, mas o pipeline de importação hoje só preserva esse valor dentro do log de texto do lote de importação — nunca como dado agregável."
- `lib/control-tower/full.ts`: "o que NÃO existe: a grade Loja × Marketplace (Blowback→ML, Blowback→Shopee, HGZ→ML, HGZ→Shopee) — Marketplace não é dado estruturado hoje em Operações."
- `lib/quality/queries.ts`: aqui `marketplace` **já é** coluna estruturada e filtrável em `QualityCase` (`distinct: ["marketplace"]`, filtro por igualdade) — ou seja, Qualidade já resolveu esse problema para o próprio domínio; Operações e Vendas, não.

Isso já responde à primeira pergunta da proposta mínima (dados atuais disponíveis) antes mesmo da Fase 1 terminar: **Qualidade tem canal estruturado, Operações tem canal só como texto solto em log, Vendas tem canal só como sufixo de `Metric.key`** (ver `lib/dashboard/channels.ts` — o "canal" no Dashboard hoje é calculado juntando KPIs cujo nome de métrica já embute o canal, não uma FK).

**Conforme instruído, a proposta completa (normalização, migração de textos, associação com dado operacional, compatibilidade com QualityCase, segundo seletor, filtros, risco de registros sem correspondência, estratégia de fallback, migration) será apresentada como documento próprio depois que a Fase 1 for validada — não antes.** `Store` como nível separado ou `ChannelAccount` como filho direto de `Company` também fica para essa análise, com os dois caminhos avaliados lado a lado.

## Ajuste 2 — ActionItem versus Task

Comparação técnica, com uma correção ao Plano Combinado anterior: o documento anterior descreveu `ActionItem` como "criado apenas por alerta automático, sem criação manual" — **isso está errado**. Conferido agora no código: `app/[empresa]/plano-de-acao/actions.ts` já tem `createActionItemAction` (criação manual completa: título, descrição, prioridade, responsável em texto livre, prazo, origem opcional em Alert/Insight) e `updateActionItemStatusAction`. O que **não** existe é o motor de insights criando `ActionItem` automaticamente — `lib/insights` hoje só grava `Insight`/`Alert`, nunca `ActionItem`. Ou seja, "alerta sugere tarefa" (pedido na Fase 4) ainda não foi construído em nenhum dos dois modelos — é trabalho novo de qualquer forma.

| Critério | A. Evoluir ActionItem | B. Criar Task e migrar | C. Manter as duas separadas |
|---|---|---|---|
| Reaproveitamento | Máximo — schema, `plano-de-acao/actions.ts`, `plano-de-acao/page.tsx`, `ActionItemCard`, `CreateActionItemForm`, `dashboard/daily-summary.ts` e `dashboard/executive-reading.ts` continuam valendo | Baixo — os mesmos 6 arquivos precisam ser reescritos para apontar pra tabela nova | Nenhum ganho — mantém duplicidade |
| Impacto no motor Insight→Alert→ActionItem | Nenhum — motor não cria ActionItem hoje; ganha capacidade de sugerir no futuro | Nenhum direto, mas motor precisaria decidir para qual tabela apontar quando isso for construído | Motor teria que decidir, para cada alerta, se gera ActionItem ou Task — regra arbitrária sem critério real |
| Impacto nas telas atuais | Mínimo — troca `owner` (texto livre) por `assignedToId` (FK a User); resto é aditivo | Alto — os 6 arquivos mudam de tabela | Usuário vê "Plano de Ação" e "Tarefas" como coisas diferentes sem diferença de conceito real |
| Migração de histórico | Trivial — `ALTER TABLE` aditivo na mesma tabela | Precisa script de cópia + mapeamento `owner` (texto) → `assignedToId` (FK), com casos sem correspondência | Nenhuma migração, mas dívida técnica permanente |
| Complexidade | Baixa | Média-alta | Baixa agora, alta depois (2 sistemas paralelos para o mesmo conceito) |
| Risco | Baixo — nenhum consumidor read-only quebra | Médio — janela de migração, risco de perder vínculo `originAlertId`/`originInsightId` se o script errar | Alto a médio prazo — mesma classe de duplicidade que o próprio Plano Frank já alertava entre Aviso/Alerta/Notificação (seção 22.13), agora entre Tarefa/Ação |
| Rollback | Fácil — reverter migration aditiva | Difícil — duas tabelas coexistindo durante a transição | N/A |
| Manutenção futura | Um único conceito de "coisa a fazer" no sistema, para sempre | Só compensa se Task e ActionItem precisassem divergir de verdade — não é o caso hoje | Pior opção: 2 tabelas fazendo a mesma coisa, indefinidamente |

**Confirmo a preferência inicial do produto: Opção A.** É a única que reaproveita os 6 arquivos que já consomem `ActionItem`, tem menor risco de regressão no Dashboard (que só lê, nunca escreve — regra já documentada em `executive-reading.ts`), e evita recriar a mesma duplicidade que o próprio Plano Frank pediu para evitar entre Aviso e Alerta. Não compromete o motor existente porque o motor hoje não toca em `ActionItem` de forma alguma.

Campos a adicionar em `ActionItem` quando a Fase 4 for construída (não agora): `assignedById`, `assignedToId` (ambos FK a `User`, substituindo/complementando `owner` texto livre para quando não há usuário cadastrado no sistema — ex. parceiro externo), `recurrence`, `sourceType`/`sourceId` (generalização de `originAlertId`/`originInsightId` para aceitar também origem de Reunião e Caso, no mesmo padrão já validado), `visibility`, `completedAt`. Checklist/subtarefas ficam para depois da Fase 4, não são pré-requisito dela.

**Não implementar nada disso até a decisão formal ser confirmada por vocês.**

---

## Roadmap oficial

**Fase 1 — Concluir entrega do Vitor** (em andamento, tarefas #132–139: layout executivo, filtros globais, webhook testado fim a fim com planilha real, atualização sem reload, documentação, validação do Vitor).

**Fase 2 — Canal/Marketplace mínimo** — proposta detalhada apresentada só depois da Fase 1 validada, conforme Ajuste 1.

**Fase 3 — Qualidade com criação interna** — caso manual, edição, tratamento, mantendo importação em paralelo, registrando origem (planilha vs. manual), evitando duplicidade, preservando histórico.

**Fase 4 — Tarefas V1** — depende da decisão formal sobre Ajuste 2. Pessoais e atribuídas, prazo, prioridade, status, origem, alertas sugerindo tarefa (motor de insights ganha essa capacidade nesta fase, não antes), visão individual e de liderança.

**Fase 5 — Menu por domínios** — só os módulos que já existem ou estão prontos para nascer:
- Geral: Visão Geral, Dashboard, Tarefas, Atendimentos.
- Operação: Visão Operacional, Qualidade, Integrações.
Nenhuma tela vazia.

**Fase 6 — Avisos** — conteúdo humano, público (empresa/canal opcional), prioridade, validade, exibição. Mantido separado de Alerta desde o schema.

**Fase 7 — Home V1** — só quando Tarefas e Avisos já existirem: saudação, tarefas, avisos, resumo operacional, alertas, calendário inicial, atalhos.

**Fase 8 — Reuniões e Calendário** — participantes, pauta, ata, decisões, tarefas geradas, calendário.

**Fase 9 — Case genérico** — só quando existir um segundo tipo real de caso além de Qualidade.

**Fase 10 — Reconhecimentos** — só depois da política definida por vocês.

---

## Regra de conclusão

Usar sempre os estados: **planejado → codificado → commitado → publicado → configurado → testado → validado.** Nada é chamado de concluído sem ter passado por "validado".

## Movimento imediato

Não iniciar a Fase 2 agora. Próximo passo: concluir #132–139 (layout executivo, filtros globais compactos, teste do webhook fim a fim com planilha real, atualização sem reload, documentação) e entregar relatório com: URL de produção, commit publicado, indicadores reais disponíveis, indicadores ainda indisponíveis, teste realizado no webhook, edição feita na planilha, evento recebido, importação concluída, banco atualizado, dashboard atualizado, erros encontrados, pendências que dependem do Luiz, roteiro de validação do Vitor.

Esse relatório só pode ser preenchido depois que #137–139 forem executados de verdade (o webhook precisa ser testado com uma planilha real, não descrito) — não está pronto ainda. Aviso quando quiser que eu comece a executar essas tarefas.
