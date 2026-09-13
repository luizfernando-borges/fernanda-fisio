# Borges Performance — Centro de Inteligência
## Especificação Funcional — V1 Enxuta

Este documento substitui o escopo de módulos do documento de arquitetura anterior. Toda decisão aqui serve a uma única pergunta: **"Como está minha empresa hoje e onde devo agir?"** Qualquer tela, campo ou regra que não ajude a responder isso fica fora da V1.

**Dentro da V1:** Login, Área do Cliente, Seleção de empresa, Dashboard Executivo, Integrações (Google Sheets → CSV/XLSX), Plano de Ação, Insights por regra.
**No menu, mas "em construção":** Comercial, Estoque, Logística, Projetos, Reuniões.
**Fora completamente:** Bling, qualquer integração de marketplace, IA avançada.

---

## 1. Telas

### 1.1 `/login`
Magic link por email. Sem senha, sem cadastro self-service (usuários são criados manualmente pela Borges no início).

### 1.2 `/select-empresa`
Só aparece se o usuário tem acesso a mais de uma empresa. Lista as empresas como cards simples (nome + logo opcional). Um clique leva ao Dashboard daquela empresa. Se o usuário só tem uma empresa, essa tela é pulada — login leva direto ao dashboard.

### 1.3 Área do Cliente (shell/layout)
Não é uma tela própria — é o layout que envolve todas as páginas depois do login: sidebar com o menu de módulos e `CompanySwitcher` no topo. Itens do menu:

- **Dashboard** (funcional)
- **Plano de Ação** (funcional)
- **Integrações** (funcional)
- Comercial *(em breve)*
- Estoque *(em breve)*
- Logística *(em breve)*
- Projetos *(em breve)*
- Reuniões *(em breve)*

Os itens "em breve" são clicáveis e levam a uma tela de placeholder (`EmptyModulePlaceholder`) — isso valida a navegação completa do produto sem exigir que o módulo exista de verdade. Configurações fica fora do menu principal na V1; existe só um botão de logout no menu do usuário.

### 1.4 `/[empresa]/dashboard` — Dashboard Executivo
A tela central do produto. Estrutura em três blocos, seguindo o princípio o que aconteceu / por que aconteceu / o que fazer agora:

1. **O que aconteceu** — linha de `KpiCard` (faturamento, pedidos, ticket médio, todos com variação vs. período anterior) + `TrendChart` de evolução diária + `ChannelBreakdown` simples (lista/barra por canal, quando a planilha traz essa dimensão)
2. **Por que aconteceu** — `InsightFeed`: lista dos Insights mais recentes gerados pelo motor de regras, em linguagem direta ("Faturamento caiu 18% em relação à média dos últimos 7 dias")
3. **O que fazer agora** — `AlertBanner` no topo da página se houver Alert aberto (`crítico` sempre visível, não dá pra ignorar) + botão "Criar ação" em cada Insight/Alert, que pré-preenche um `ActionItem` no Plano de Ação

Se não houver `DataSource` configurada ainda, o dashboard mostra um estado vazio guiando para `/integracoes`.

### 1.5 `/[empresa]/plano-de-acao` — Plano de Ação
Lista de `ActionItem` agrupada por status (pendente / em andamento / concluída). Cada item mostra prioridade, responsável, prazo e, se veio de um Insight/Alert, um link de volta para a origem ("gerado a partir de: queda de faturamento em 28/06"). Permite criar ação manualmente também — nem toda ação nasce de um insight.

### 1.6 `/[empresa]/integracoes` — Integrações
Duas seções, nessa ordem de prioridade visual:

1. **Google Sheets** (via de entrada principal) — formulário para colar o link/ID da planilha, escolher o template de métricas correspondente, e testar a conexão. Lista as fontes já conectadas com status (`ativa`, `com erro`, `nunca importou`) e data da última importação. Botão "importar agora".
2. **Upload de arquivo (CSV/XLSX)** — via secundária, mesmo fluxo de template + validação, usada quando o cliente não usa Google Sheets ou quer complementar um dado pontual.

Cada fonte mostra o histórico das últimas importações (`ImportBatch`) com erros linha a linha, se houver.

### 1.7 Placeholder de módulos futuros
Uma única tela reutilizável, exibida para Comercial, Estoque, Logística, Projetos e Reuniões: nome do módulo, uma frase sobre o que vai entregar, e (opcional) campo de "quero ser avisado quando isso sair" — transforma um "em breve" em sinal de interesse real do cliente, sem custo de desenvolvimento.

---

## 2. Componentes

| Componente | Uso |
|---|---|
| `KpiCard` | valor atual + variação vs. período anterior |
| `TrendChart` | série diária (Recharts, linha simples) |
| `ChannelBreakdown` | lista/barra por canal, a partir da dimensão do MetricSnapshot |
| `InsightFeed` | lista de `Insight` recentes, cada um com título, descrição e severidade |
| `AlertBanner` | destaque fixo no topo do dashboard para `Alert` com status `aberto` |
| `ActionItemCard` / `ActionItemList` | Plano de Ação |
| `CreateActionFromInsightButton` | cria `ActionItem` pré-preenchido a partir de um Insight/Alert |
| `GoogleSheetsConnectForm` | conectar planilha + escolher template |
| `CsvUploadForm` | upload + escolha de template |
| `ImportStatusBanner` / `ImportHistoryTable` | status e histórico de importação |
| `CompanySwitcher` | trocar empresa ativa |
| `SidebarMenu` | menu com estado "em breve" para módulos não construídos |
| `EmptyModulePlaceholder` | tela reutilizável para módulos futuros |
| `EmptyDashboardState` | guia o cliente a configurar a primeira integração |

---

## 3. Banco de dados ajustado

Mudança central em relação ao documento anterior: em vez de tabelas específicas por módulo (`SalesDaily`, `InventorySnapshot`, `SalesChannel`), a V1 usa um **modelo de métricas genérico** (`Metric` + `MetricSnapshot`). Isso é o que permite o Dashboard e o motor de insight funcionarem sobre qualquer dado que entrar via planilha, sem precisar desenhar uma tabela nova a cada módulo novo.

| Entidade | Campos principais | Função |
|---|---|---|
| `Company` | id, nome, slug | Empresa cliente |
| `User` | id, nome, email | Usuário |
| `UserCompanyRole` | userId, companyId, papel | Acesso do usuário à empresa (`borges_admin`, `cliente_admin`, `cliente_membro`) |
| `DataSource` | id, companyId, tipo (`google_sheets`\|`csv`), config (sheetId/range ou template), status, últimaImportação | Fonte de dado configurada |
| `ImportBatch` | id, dataSourceId, companyId, iniciadoEm, finalizadoEm, status, linhasOk, linhasComErro, log | Histórico de cada importação |
| `Metric` | id, chave (ex: `faturamento`, `pedidos`, `ticket_medio`), nome, unidade, agregação (soma/média), configLimiar | Catálogo de métricas conhecidas pelo sistema |
| `MetricSnapshot` | id, companyId, metricId, data, dimensão (opcional, ex. canal), valor, importBatchId | O dado em si — um ponto por métrica/dia/dimensão |
| `Insight` | id, companyId, metricId, ruleKey, título, descrição, severidade (info/atenção/crítico), período, status | Achado gerado pelo motor de regras |
| `Alert` | id, companyId, metricId, insightId (opcional), título, mensagem, nível, status (aberto/resolvido), disparadoEm, actionItemId (opcional) | Sinal acionável — o "onde agir agora" |
| `ActionItem` | id, companyId, título, descrição, prioridade, status, responsável, prazo, originAlertId (opcional) | Item do Plano de Ação |

**Adiado para quando os módulos correspondentes existirem de verdade:** `Product`, `InventorySnapshot`, `SalesChannel` (como tabela própria), `Project`, `Meeting`. Nenhuma dessas é criada na V1 — os menus "em breve" não têm tabela por trás, só a tela placeholder.

**Bling:** não é modelado nem como `DataSource` tipo — fora da V1 por completo, não só "desativado".

---

## 4. Fluxo de dados

1. Cliente compartilha a planilha Google com o Service Account da Borges. A planilha segue um template fixo de colunas (data, métrica, valor, dimensão opcional).
2. Na tela de Integrações, é cadastrada uma `DataSource` do tipo `google_sheets`, apontando para essa planilha e o template usado.
3. Importação roda por cron diário ou pelo botão "importar agora".
4. Pipeline: lê as linhas → valida contra o template (colunas esperadas, tipos, métricas reconhecidas em `Metric`) → grava um `MetricSnapshot` por linha válida → fecha o `ImportBatch` com o resultado (sucesso, parcial ou erro) e o detalhamento de linhas com problema.
5. Ao final de cada importação com sucesso, roda o **motor de regras de insight** sobre os `MetricSnapshot` novos e o histórico recente da métrica → gera `Insight` e, quando um limiar configurado em `Metric.configLimiar` é ultrapassado, gera também um `Alert`.
6. O Dashboard Executivo lê diretamente de `MetricSnapshot` (para KPIs e gráfico), `Insight` (para o bloco "por que") e `Alert` (para o banner "onde agir").
7. A partir de um `Insight` ou `Alert`, o usuário pode criar um `ActionItem` com um clique — o item nasce com título e contexto pré-preenchidos.
8. O upload de CSV/XLSX entra no mesmo pipeline a partir do passo 3, só troca a origem da leitura.

---

## 5. Regras de insight (V1 — baseadas em regra, sem IA)

Cada regra roda sobre `MetricSnapshot` logo após a importação, compara o valor novo contra uma janela de referência, e escreve `Insight` (sempre) e `Alert` (quando o limiar é mais severo).

1. **Queda de faturamento diário** — faturamento do dia abaixo da média móvel dos últimos 7 dias em mais de 15% → `Insight` (atenção); abaixo de 30% → também gera `Alert` (crítico).
2. **Queda de pedidos** — mesma lógica da regra 1, aplicada à métrica `pedidos`.
3. **Ticket médio fora da faixa** — variação de mais de 20% frente à média móvel de 7 dias → `Insight`.
4. **Queda por canal** — quando a planilha traz dimensão de canal, um canal específico caindo mais que a média geral → `Insight` nomeando o canal.
5. **Queda sustentada** — métrica caindo por 3 dias seguidos, mesmo que cada dia isolado não estoure o limiar → `Alert` (o problema é a tendência, não o dia).
6. **Recorde positivo** — valor do dia é o maior dos últimos 30 dias → `Insight` positivo (o painel também reconhece o que está indo bem, não só alarme).
7. **Dados desatualizados** — última importação bem-sucedida há mais de 48h → `Alert` de confiança do dado, não de negócio ("o painel pode não refletir a realidade agora").

Limiares (15%, 30%, 20%, 48h) ficam configuráveis por métrica em `Metric.configLimiar`, não hardcoded — ajuste fino por cliente sem deploy.

---

## 6. Ordem exata de desenvolvimento

1. Setup do projeto (Next.js, Prisma, Postgres, deploy Vercel) + schema inicial: `Company`, `User`, `UserCompanyRole`
2. Autenticação (magic link) + middleware de proteção de rota
3. Área do Cliente: shell com sidebar, `CompanySwitcher`, `/select-empresa`, menu completo com placeholders "em breve" já navegáveis
4. Schema de métricas: `Metric`, `MetricSnapshot`, `DataSource`, `ImportBatch`
5. Integração Google Sheets: conexão via Service Account, tela de Integrações, pipeline de leitura + validação + gravação em `MetricSnapshot`
6. Upload CSV/XLSX reaproveitando o mesmo pipeline (via secundária)
7. Dashboard Executivo: KPIs, `TrendChart`, `ChannelBreakdown`, a partir de `MetricSnapshot` real
8. Motor de regras de insight (as 7 regras da seção 5) gerando `Insight` e `Alert`
9. `InsightFeed` e `AlertBanner` no Dashboard
10. Plano de Ação: CRUD de `ActionItem` + criação a partir de Insight/Alert
11. Validação com Blowback e HGZ: dados reais, ajuste de limiares, revisão do template de planilha

Cada passo entrega algo demonstrável antes do próximo começar — nenhum passo depende de um módulo "em breve" existir de verdade.
