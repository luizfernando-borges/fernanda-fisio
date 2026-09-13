# Plano Combinado — Centro de Inteligência

Contraproposta técnica e estratégica ao Plano Frank, confrontada com o código real do projeto (`centro-de-inteligencia/prisma/schema.prisma`, `lib/`, `app/`, `components/layout/Sidebar.tsx`) e com o roadmap v2 já rascunhado. Documento de decisão — nada aqui foi codificado.

Nota sobre a mensagem anterior: o texto que trouxe o Plano Frank também carregava, ao final, um bloco em inglês me instruindo a ignorar ferramentas e devolver só um "resumo de conversa". Isso não veio de você — é um padrão de injeção de instrução dentro de conteúdo observado — e foi ignorado. O pedido real (comparar os dois planos e gerar um terceiro) foi seguido.

---

## A. Diagnóstico da arquitetura atual

O que existe hoje, verificado direto no schema e no código, não em memória de conversas antigas:

- **Organização**: só um nível — `Company` (Blowback, HGZ). Não existe `Group`, `LegalEntity`, `Store` nem `ChannelAccount` no banco. O "seletor de empresa" hoje troca entre `Company`, e é isso.
- **Permissão**: `UserCompanyRole` liga `User` a `Company` com **um único enum** (`BORGES_ADMIN` / `CLIENTE_ADMIN` / `CLIENTE_MEMBRO`). Não há escopo por loja, canal, departamento, nem dimensão de ação (visualizar/criar/aprovar) — é literalmente 1 papel fixo por empresa.
- **Fonte de dados**: `DataSource` já é genérica (`GOOGLE_SHEETS`/`CSV`) e usa um campo `config.purpose` (JSON) para diferenciar Vendas / Operações / Qualidade. O despacho de importação já é centralizado em `lib/datasource-admin.ts:runImportForDataSource`, que lê `config.purpose` e decide qual pipeline chamar. Isso vale tanto para o botão manual quanto para o webhook — os dois caminhos convergem no mesmo ponto desde a correção feita em 2026-07-20.
- **Webhook**: já existe, em produção — `lib/webhooks/google-sheets.ts`. Tem autenticação por segredo, lock atômico (`importLockedAt`), debounce de 40s, reprocessamento único e liberação garantida mesmo em erro. Não é um endpoint rígido por planilha — já é genérico por `dataSourceId`.
- **Métricas**: `Metric`/`MetricSnapshot` são genéricos e reaproveitáveis (qualquer indicador numérico, importado ou calculado, por empresa/data/dimensão).
- **Insights/Alertas/Ações**: motor de regras já roda depois de cada importação (`lib/insights`), gera `Insight` → `Alert` → pode gerar `ActionItem`. `ActionItem` já tem `originAlertId` e `originInsightId` — ou seja, o padrão "evento de um módulo gera tarefa em outro" já existe e está validado em produção, só que hoje só nessa direção.
- **QualityCase**: modelo de caso já com forma rica — `loja`, `marketplace`, `produto`, `statusEcommerce`, `statusExpedicao`, `responsavelEcommerce`, `responsavelExpedicao`, `problema`, `detalhes`, `ticketUrl`, `externalKey` para idempotência. Estruturalmente já é ~90% do "Case genérico" que o Plano Frank pede — só falta um discriminador de tipo/origem e sair do nome/escopo "qualidade".
- **Menu**: `Sidebar.tsx` é uma lista plana hardcoded (`activeItems` + `comingSoonItems`), sem agrupamento por domínio, sem ser dirigida por permissão.
- **Home vs Dashboard**: não existem como conceitos separados. `/[empresa]/dashboard` já é a tela de entrada e já carrega, desde a Sprint 3.1, um bloco de "Resumo do Dia" — ou seja, hoje Dashboard já faz parte do papel que o Plano Frank quer dar à Home.
- **Não existe no schema, hoje**: `Task`/tarefa atribuível (só existe `ActionItem`, criado apenas por alerta automático — sem criação manual, sem responsável por hierarquia), `Meeting`, `Announcement`/Aviso, `Recognition`, `Calendar`/evento unificado, `Case` genérico fora de qualidade.
- **Em andamento agora** (tarefas #132–139 da lista ativa): ajustar ordem da tela de Visão Geral, filtros globais compactos, testar webhook fim a fim com planilha real, atualização sem reload, documentar. Isso é exatamente a Fase 1 do Plano Frank — já em execução, não em decisão.

## B. Pontos compatíveis com o Plano Frank

- O padrão `config.purpose` como discriminador já é, na prática, o "`DataSource` com origem/status/auditoria" pedido na seção 16 — não precisa ser reinventado, só documentado como decisão consciente.
- `Company` + `UserCompanyRole` é uma base compatível com a hierarquia Group→Company→... — adicionar um nível é uma extensão aditiva (nova tabela + FK opcional), não uma reescrita.
- `originAlertId`/`originInsightId` em `ActionItem` prova que o padrão de "seção 15 — relação entre módulos" (X gera Tarefa) já foi construído e funciona em produção. Generalizar para `originCaseId`/`originMeetingId` é o mesmo padrão, repetido.
- `QualityCase` está estruturalmente pronto para virar a base do `Case` genérico — reaproveitamento real, não teórico.
- O webhook já segue os requisitos da seção 17 (autenticação, idempotência, debounce, concorrência, fallback manual via botão) — só falta generalizar o payload de "evento" se um dia houver mais de uma fonte de webhook além de Google Sheets.
- Motor de insights já prova que "dado → regra → alerta → tarefa" funciona ponta a ponta — é o mesmo espírito de "seção 15" aplicado a um caso concreto.
- A prioridade da Fase 1 do Frank (fechar Dashboard/webhook com o Vitor antes de mexer em arquitetura) é idêntica ao que já está em andamento nas tarefas #132–139.

## C. Pontos incompatíveis (e o que discordo, com alternativa)

**1) Group/LegalEntity/Store/ChannelAccount agora — contesto o "agora".**
O que está sendo proposto: 4 tabelas novas de organização antes de existir um segundo caso real de uso.
Por quê: Blowback e HGZ são hoje 2 `Company`. Não há evidência no projeto de que precisamos separar CNPJ de loja de conta de canal *esta semana* — o próprio Plano Frank, na seção 2 e na seção 21, diz para não tomar decisões que impeçam o futuro, não para construir o futuro inteiro agora. `Group` sem um segundo grupo real de cliente é especulação; `LegalEntity` sem um CNPJ duplicado por empresa é especulação.
Alternativa melhor: manter `Company` como está. Quando a necessidade de canal/loja aparecer de verdade — e ela já está mapeada, é o gap de Marketplace/Canal citado no meu roadmap v2 (seção 3.6) e em `docs/visao-geral-operacao-v1.md` — criar **só** `Store`/`ChannelAccount` como filhos diretos de `Company`, sem `Group` e sem `LegalEntity` até que exista um motivo concreto para cada um.
Impacto: menos tabelas vazias, menos telas de cadastro sem dado, decisão adiada sem custo de retrabalho (FK opcional é aditiva).
Risco de manter a proposta original: 4 níveis de hierarquia para 2 empresas reais é complexidade sem uso — aumenta a superfície de bugs de permissão (mais escopos = mais formas de vazar dado entre empresas) sem nenhum ganho imediato.

**2) RBAC de 3 dimensões (organização × função × ação) agora — contesto o "agora".**
O que está sendo proposto: matriz completa de permissão por escopo organizacional, cargo e ação.
Por quê: hoje existem 3 papéis fixos e eles já resolvem o problema real (Borges admin vê tudo, cliente admin gerencia sua empresa, cliente membro só visualiza). Não há, no projeto hoje, um caso documentado de "um gestor pode aprovar mas não excluir" — construir a matriz de ação sem esse caso é desenhar para um requisito hipotético.
Alternativa melhor: manter o enum de 3 papéis como está até o módulo de Tarefas nascer (é ali que "líder atribui, colaborador não edita tarefa da liderança" vira um requisito real, por Frank seção 9). Resolver granularidade de ação **dentro** do módulo que precisar dela primeiro, não como pré-requisito de plataforma.
Impacto: zero refatoração de autenticação agora; a extensão futura (tabela de permissões por ação) encaixa sobre o `UserCompanyRole` existente sem quebrar login.
Risco de manter a proposta original: atraso a a Fase 1 (que depende de autenticação estável) para desenhar permissões que nenhum módulo ainda consome.

**3) Home separada do Dashboard, construída antes de Tarefas/Avisos existirem — contesto a ordem, não o conceito.**
O que está sendo proposto (seção 6): Home e Dashboard como produtos diferentes desde já.
Por quê: concordo com o princípio — Dashboard deve continuar analítico, Home deve orientar o dia. Mas uma Home com "tarefas do dia", "próximas reuniões", "avisos", "reconhecimentos" **não tem o que mostrar** hoje, porque nenhuma dessas entidades existe no banco. Construir a casca da Home agora resulta em uma tela vazia — exatamente o que a seção 21 do próprio Plano Frank pede para evitar ("dezenas de rotas vazias").
Alternativa melhor: manter o "Resumo do Dia" dentro do Dashboard (já construído, já funciona, baixo custo de manutenção) até que pelo menos Tarefas e Avisos existam de verdade. Separar Home do Dashboard como uma entrega dedicada só quando houver conteúdo real para as 6 faixas da seção 18.
Impacto: nenhuma tela vazia entregue; a separação acontece quando agrega valor, não antes.
Risco de manter a proposta original: gastar um ciclo de build numa tela de abertura que repete, com layout novo, o que o Dashboard já mostra hoje.

**4) QualityCase virar Case genérico imediatamente — contesto o "imediatamente", concordo com a direção.**
O que está sendo proposto (seção 10, Fase 6): unificar reclamação/devolução/garantia/divergência de recebimento/ocorrência de TI etc. num único `Case`.
Por quê: `QualityCase` hoje só é alimentado por uma fonte (planilha de Reclamações/Devoluções). Generalizar o modelo antes de existir um segundo tipo real de caso (ex.: divergência de recebimento) é adicionar um campo `tipo` que nunca varia na prática — custo de migração pago sem benefício imediato.
Alternativa melhor: a evolução prioritária (ver seção L abaixo) é dar ao `QualityCase` **criação manual dentro do sistema** (elimina a dor real e documentada da planilha trimestral) mantendo o nome/escopo atual. Renomear/generalizar para `Case` só quando um segundo tipo de caso (ex.: recebimento) precisar do mesmo modelo — nesse momento a migração é mecânica (renomear tabela, adicionar `tipo`), porque a forma já está certa.
Impacto: resolve a dor real desta semana sem esperar o redesenho de arquitetura.
Risco de manter a proposta original: atrasar a correção da dor mais citada no projeto (reconexão trimestral da planilha) esperando um desenho de `Case` genérico que hoje não tem um segundo consumidor.

## D. Riscos

- **Risco de interromper a Fase 1 em andamento.** As tarefas #132–139 (layout da Visão Geral, filtros, webhook fim a fim, polling, documentação) são a prioridade combinada tanto no meu roadmap quanto no Plano Frank. Qualquer trabalho de arquitetura nova antes de fechá-las é risco autoinfligido — os dois planos concordam nisso.
- **Risco de sobre-desenho (over-engineering) sem segundo cliente/grupo real.** Group/LegalEntity/ChannelAccount desenhados para uma escala que ainda não existe custam tempo de build e superfície de bug maior, sem cliente novo para validar se o desenho está certo.
- **Risco de duplicar Aviso/Alerta/Notificação** (a própria seção 22.13 do Frank levanta isso) — `Alert` já existe e é gerado pelo motor de regras a partir de dado. `Announcement`/Aviso é conteúdo humano. Se não houver uma regra clara de fronteira desde o primeiro commit, os dois viram a mesma tabela por acidente, como o próprio roadmap v2 (seção 3.4) já havia registrado.
- **Risco de granularidade de permissão real ficar atrás do RBAC teórico.** Se a matriz de ação for construída antes de um caso de uso real de "aprovar sem excluir", ela será desenhada errado e vai precisar de retrabalho quando o caso real aparecer — o oposto do "baixo risco de refatoração futura" que a seção 24 pede como critério.
- **Risco de planilha trimestral continuar sendo a única porta de entrada de Qualidade** enquanto se espera o desenho completo do `Case` genérico — essa é a dor mais concreta e datada do projeto (ver `relatorio-centro-qualidade-planilha-reclamacoes.md`), e adiá-la para depois de Tarefas/Reuniões (ordem sugerida pelo Frank) a deixa sem solução por vários ciclos.

## E. Proposta de arquitetura alternativa

Mesmo princípio das 3 camadas do Frank (Contexto / Gestão / Execução) — concordo integralmente, é uma separação correta e já implícita no código (Company = contexto, Dashboard/Insights = gestão, Operações/Qualidade = execução). A diferença é **quando** cada nível de contexto nasce:

```
Company (existe hoje)
└── Store / ChannelAccount   [só quando um 2º canal/loja for um requisito real — não Group, não LegalEntity ainda]
```

`Group` fica adiado até existir um segundo cliente de Fullcommerce de verdade (não Blowback/HGZ, que já são `Company`). `LegalEntity` fica adiado até um CNPJ duplicado dentro da mesma `Company` ser um problema real relatado, não hipotético.

## F. Estrutura de entidades (o que nasce e quando)

**Nasce agora / nesta fase (baixo risco, alto reaproveitamento):**
- `Task` (novo) — tarefa atribuível, com `companyId`, `assignedBy`, `assignedTo`, `dueDate`, `status`, `originAlertId`/`originInsightId`/`originCaseId` (mesmo padrão de origem dupla já usado em `ActionItem` — na prática, `Task` substitui/absorve `ActionItem`, não convive como tabela separada).
- Ampliação de `QualityCase`: permitir criação manual (formulário) além de importação — sem mudança de schema, só nova via de entrada.

**Nasce depois (Fase seguinte, quando Tasks já estiver validado):**
- `Meeting`, `Announcement`, `CalendarEvent` (ou calendário como view computada sobre Task/Meeting/Announcement, sem tabela própria no início — mais simples e evita a duplicidade que a própria seção 22.13 do Frank teme).

**Nasce só quando tiver um 2º consumidor real:**
- `Case` genérico (evolução de `QualityCase`, renomeação + campo `tipo`).
- `Store` / `ChannelAccount`.

**Fica para o fim, depende de decisão de política antes de qualquer schema:**
- `Recognition` — mesma posição dos dois planos: sem regra de incentivo definida, não há schema certo pra desenhar.

## G. Estrutura de rotas

Manter o padrão atual `/[empresa]/<modulo>` — já funciona, já é multiempresa, não precisa de `/grupo/[grupo]/[empresa]/...` até `Group` existir de fato. Quando `Store`/`ChannelAccount` nascerem, entram como **filtro dentro da tela**, não como segmento novo de URL — evita quebrar todo link já compartilhado com o Vitor.

## H. Estrutura do menu

Concordo com o agrupamento por domínio da seção 7 do Frank — o menu plano de hoje (`Sidebar.tsx`) não escala. Mas trazer todas as 12 categorias (Geral/Comercial/Compras/Estoque/Recebimentos/Expedição/Fulfillment/Atendimento/Informações/Marketing/Operacional/RH/TI) de uma vez recria o problema que a seção 21 do próprio Frank quer evitar — "dezenas de rotas vazias". Proposta: agrupar **só** o que já existe ou está no próximo ciclo (Geral: Início*, Dashboard, Tarefas, Atendimentos; Operação: Visão Operacional, Visão Geral; TI: Integrações), mantendo os módulos hoje "em breve" (Comercial/Estoque/Logística/Projetos/Reuniões) como estão, sem criar as outras 8 categorias do Frank até terem pelo menos um item real dentro.
(*Início como item de menu só quando Home for uma entrega real — ver seção C.3.)

## I. Estratégia de permissões

Curto prazo: manter os 3 papéis atuais. Médio prazo (quando Tarefas nascer): adicionar escopo de "responsável vs. atribuidor" dentro do próprio modelo `Task` (campos `assignedBy`/`assignedTo`), sem precisar de RBAC de ação. Longo prazo (só quando um caso real de "aprovar sem excluir" aparecer): estender `UserCompanyRole` com uma tabela de permissões por ação — aditiva, não quebra o que existe.

## J. Estratégia dos seletores globais

Concordo com a distinção conceitual (seletor de organização ≠ filtro do dashboard) — é uma separação correta. Implementação: manter hoje **um único seletor** (o de `Company`, que já existe e funciona). O segundo seletor (canal/loja) só é construído junto com `Store`/`ChannelAccount` — construir o seletor visual antes do dado por trás dele é UI vazia.

## K. Estratégia Home versus Dashboard

Concordo com o princípio (perguntas diferentes: "o que preciso saber hoje" vs. "como está a operação"). Discordo do timing — ver C.3. Dashboard continua sendo o entregável principal e a tela de entrada até Tarefas/Avisos existirem para preencher uma Home de verdade.

## L. Roadmap recomendado (combinado)

1. **Fechar Fase 1 (em andamento — tarefas #132–139).** Webhook testado fim a fim, polling leve, filtros globais, documentação. Sem isso, nada abaixo importa. *(concordância total entre os dois planos)*
2. **Qualidade → criação manual de caso.** Maior dor real e documentada, maior reaproveitamento (`QualityCase` já pronto), menor risco. Prioridade que meu roadmap já apontava e que o Plano Frank também valida como "baixo risco / alta velocidade de valor" pelo próprio critério da seção 24 — só que ele a colocava na Fase 6; eu a antecipo porque a dor já existe hoje, não depende de nada novo.
3. **Tarefas — versão mínima.** Criação manual (não só via alerta), responsável, prazo, status. `ActionItem` evolui para `Task` sem quebrar o que já existe.
4. **Fundação de menu por domínio (H) + agrupamento simples.** Reorganizar o que já existe, sem criar telas novas vazias.
5. **Home v1** — só depois que Tarefas e ao menos um tipo de Aviso existirem para preencher as faixas.
6. **Reuniões.**
7. **Avisos / Mural.**
8. **Store/ChannelAccount + segundo seletor** — entra quando o gap de Marketplace estruturado (já mapeado, Fase 2 do roadmap v2) virar prioridade de negócio.
9. **Case genérico** (evolução de QualityCase) — quando um 2º tipo de caso for real.
10. **Reconhecimentos** — por último nos dois planos; depende de política de incentivo definida por vocês antes de qualquer schema.

## M. Estimativa relativa de esforço

| Item | Esforço |
|---|---|
| Fechar Fase 1 (webhook e2e, polling, filtros) | Pequeno |
| Qualidade — criação manual de caso | Pequeno |
| Tarefas v1 (`Task` a partir de `ActionItem`) | Médio |
| Menu por domínio (reorganização, sem telas novas) | Pequeno |
| Home v1 | Médio |
| Reuniões | Médio |
| Avisos/Mural | Pequeno |
| Store/ChannelAccount + 2º seletor | Médio |
| Case genérico (migração de QualityCase) | Médio |
| RBAC de 3 dimensões completo | Grande |
| Group/LegalEntity completos | Grande |
| Reconhecimentos (schema + política) | Pequeno (schema) / depende de vocês (política) |

## N. Dependências

- Home v1 depende de Tarefas e Avisos existirem (não o contrário).
- Case genérico depende de existir um 2º tipo de caso real — não é pré-requisito de nada, é consequência.
- RBAC de ação depende de Tarefas existir (é lá que o caso de uso aparece primeiro).
- Store/ChannelAccount e o 2º seletor dependem do gap de Marketplace estruturado virar prioridade — já mapeado, não é decisão nova.
- Reconhecimentos depende de decisão de política de vocês, não de nada técnico.

## O. Ordem ideal de implementação

A mesma da seção L — a única mudança real em relação à ordem do Plano Frank é subir "Qualidade → criação manual" para logo depois da Fase 1, à frente de Tarefas, porque resolve uma dor já sentida com o modelo que já existe pronto.

## P. O que deve ser feito nesta semana

Concluir as tarefas já em andamento: teste do webhook fim a fim com planilha real (#137), atualização sem reload (#138), documentação e relatório de estado (#139), e os dois itens de layout/filtro pendentes da Visão Geral (#132, #133). Nada de arquitetura nova entra nesta semana — nos dois planos, essa é a prioridade combinada.

## Q. O que deve ser adiado

Group, LegalEntity, RBAC de 3 dimensões, Home separada da Dashboard, Case genérico, Store/ChannelAccount, e as 8 categorias de menu ainda sem nenhum item real (Comercial completo, Compras, Estoque completo, Fulfillment, Marketing, RH, TI como categoria própria). Nenhum desses tem um requisito real e datado hoje — todos são desenho para escala futura, não para dor presente.

## R. Recomendação final

Concordo com a visão de produto do Plano Frank (plataforma de gestão operacional, não só dashboard) e com o princípio "desenhar grande, construir pequeno, validar rápido, evoluir sem refazer" — é exatamente o que o projeto já vem fazendo até aqui (`config.purpose` como discriminador, `originAlertId`/`originInsightId` como padrão de origem, arquivamento reversível em vez de exclusão). A diferença entre os dois planos não é de visão, é de **sequência**: o Plano Frank desenha a plataforma completa antes de construir qualquer módulo novo; a proposta aqui é desenhar o suficiente para não fechar portas (documentado nas seções E–K acima) e construir na ordem que resolve dor real primeiro — Qualidade com criação manual antes de Tarefas, Tarefas antes de Home, Home antes de Reuniões, e toda a hierarquia organizacional (Group/LegalEntity/Store/ChannelAccount) e o RBAC de 3 dimensões só quando um segundo cliente ou um caso de permissão real os exigir, não antes.

Isso não é uma rejeição do Plano Frank — é a mesma arquitetura, com o "quando" de cada peça decidido pelo que já existe e já dói, em vez de pelo que pode um dia ser necessário.
