# Borges Performance — Centro de Inteligência
## Especificação de Build — Sprint 3

**Objetivo da sprint:** transformar o dado que já entra em `MetricSnapshot` (Sprint 2) na tela que responde a pergunta do Vitor: "Como está minha empresa hoje e onde devo agir?" É a primeira sprint em que o produto se parece com o produto final — mas ainda sem Insight/Alert persistidos, sem Comercial, sem Estoque.

Ponto que atravessa todo o documento: o bloco "Leitura executiva" desta sprint **não é** o motor de Insight da Sprint 4. São frases calculadas na hora, a partir da mesma comparação de período que já alimenta os KPIs — nada é gravado em `Insight` ou `Alert`. A Sprint 4 vai formalizar e persistir esse raciocínio; aqui ele existe só como texto na tela.

---

## 1. Layout detalhado da tela

### Bloco 1 — Cabeçalho
- Nome da empresa ativa (ex.: "Blowback")
- Seletor de período: três opções fixas — **Hoje**, **7 dias**, **30 dias** — nenhuma outra
- "Última atualização: [data e hora] via [Google Sheets/CSV]"
- Badge de status dos dados: **Atualizado** / **Desatualizado** / **Sem dados** (regra na seção 6)

### Bloco 2 — "Como está a empresa hoje?"
- Três `KpiCard`: Faturamento, Pedidos, Ticket Médio
- Cada card mostra o valor do período selecionado e a variação percentual contra o período anterior comparável (seção 4)
- O card com a maior variação em módulo (positiva ou negativa) dos três ganha destaque visual (borda ou ícone) — é o "isso é o que mais mudou"

### Bloco 3 — "Onde está vendendo?"
- Três valores no mesmo período: Vendas Mercado Livre, Vendas Shopee, Vendas Site
- Participação percentual de cada canal — calculada sobre a soma dos três canais informados, não sobre o `faturamento` total (podem divergir se houver vendas fora desses três canais ou dado incompleto; essa diferença não é escondida, ver seção 5)
- Ordenados do maior para o menor, representados como barra horizontal simples — sem gráfico de pizza, sem 3D, sem legenda interativa

### Bloco 4 — "Pontos de atenção"
- Três `KpiCard`: Pedidos Atrasados, Produtos Críticos, Ruptura de SKUs
- Polaridade invertida em relação ao Bloco 2: aumento é ruim (vermelho), queda é boa (verde) — ver polaridade completa na seção 4
- Se os três estiverem em zero ou em queda no período, o bloco assume tom neutro/positivo (ex.: "Nenhum ponto crítico no período")

### Bloco 5 — "Evolução"
- Gráfico de linha único (não dois gráficos simultâneos), com alternância simples entre **Faturamento** e **Pedidos** via toggle
- Janela do gráfico segue o período selecionado no cabeçalho, com um mínimo de 7 dias de contexto: período "Hoje" e "7 dias" mostram os últimos 7 dias; período "30 dias" mostra os últimos 30 dias
- Sem eixo duplo, sem sobreposição de métricas, sem zoom ou seleção de intervalo customizado

### Bloco 6 — "Leitura executiva"
- Lista curta de frases (2 a 4), geradas por regras simples sobre a mesma comparação de período dos blocos acima, mais uma frase-síntese final
- Exemplos de regra (detalhadas na seção 4):
  - Variação de faturamento relevante → "O faturamento está 18% abaixo do período anterior."
  - Pedidos atrasados subiu → "Pedidos atrasados aumentaram em relação à última atualização."
  - Sín­tese final, conforme o saldo de sinais positivos/negativos → "A operação exige atenção hoje." ou "A operação está estável hoje."
- Texto em linguagem direta de negócio — nunca nome de métrica técnica (`ruptura_skus`) ou termos como "outlier", "desvio padrão", "p50"

---

## 2. Componentes necessários

| Componente | Função |
|---|---|
| `DashboardHeader` | nome da empresa, `PeriodSelector`, última atualização, `DataStatusBadge` |
| `PeriodSelector` | toggle Hoje / 7 dias / 30 dias |
| `DataStatusBadge` | Atualizado / Desatualizado / Sem dados |
| `StaleDataWarning` | aviso destacado quando dado está há mais de 48h sem atualizar |
| `KpiCard` | valor, unidade, variação %, polaridade, estado de destaque opcional |
| `ChannelBar` / `ChannelSummary` | participação por canal, barra horizontal |
| `AttentionPointsBlock` | agrupa os 3 `KpiCard` de polaridade invertida |
| `TrendChart` | gráfico de linha diário |
| `MetricToggle` | alterna a métrica exibida no `TrendChart` |
| `ExecutiveReadingBlock` | lista de frases da Leitura Executiva |
| `EmptyDashboardState` | tela guiando para Integrações quando não há nenhum dado |
| `EmptyMetricState` | estado "sem dado" dentro de um card específico (não confundir com zero) |

---

## 3. Queries necessárias sobre MetricSnapshot

Todas filtradas por `companyId` desde a base — nenhuma query solta sem esse filtro.

1. **Data de referência (D):** maior `data` com pelo menos um `MetricSnapshot` da empresa. É a partir de D que os três períodos são calculados — "Hoje" não é necessariamente o dia do calendário, é o dia mais recente com dado real (a defasagem, se houver, aparece na "última atualização" do cabeçalho, nunca escondida).
2. **Agregação por métrica, período atual:** soma de `valor` por `metricId`, para o conjunto de métricas dos Blocos 2, 3 e 4, dentro do intervalo do período selecionado.
3. **Agregação por métrica, período anterior comparável:** mesma query, no intervalo anterior equivalente (seção 4).
4. **Série diária para o gráfico:** `data` e `valor` de uma métrica (Faturamento ou Pedidos, conforme o toggle), ordenados por data, dentro da janela do Bloco 5.
5. **Existência de qualquer dado:** contagem de `MetricSnapshot` da empresa — se zero, aciona o `EmptyDashboardState` e nenhuma das queries acima chega a rodar.
6. **Freshness:** não vem de `MetricSnapshot`, vem de `DataSource.últimaImportação` (ou do `ImportBatch` mais recente da empresa) — usada para o `DataStatusBadge` e o `StaleDataWarning`.

`ticket_medio` nunca é lido diretamente por soma — é sempre `soma(faturamento) ÷ soma(pedidos)` do mesmo intervalo, calculado a partir dos resultados das queries 2 e 3 (tanto para o período atual quanto o anterior). Fazer média simples dos tickets diários daria um número distorcido em dias de volume desigual.

---

## 4. Cálculo de variação por período

**Período anterior comparável** (D = data de referência, seção 3):

| Período selecionado | Intervalo atual | Intervalo anterior |
|---|---|---|
| Hoje | D | D−1 |
| 7 dias | D−6 até D | D−13 até D−7 |
| 30 dias | D−29 até D | D−59 até D−30 |

**Fórmula:** `variação% = (atual − anterior) ÷ anterior × 100`, com exceções:
- anterior = 0 e atual = 0 → variação = 0%, rótulo "sem mudança"
- anterior = 0 e atual > 0 → não é possível calcular percentual; rótulo "sem comparação anterior", não mostrar infinito nem "0%"
- anterior > 0 e atual = 0 → variação = −100%

**Polaridade** (define se o aumento é verde ou vermelho):

| Aumento é positivo (verde) | Aumento é negativo (vermelho) |
|---|---|
| Faturamento, Pedidos, Ticket Médio, Vendas Mercado Livre, Vendas Shopee, Vendas Site | Pedidos Atrasados, Produtos Críticos, Ruptura de SKUs |

**Destaque do Bloco 2:** entre Faturamento, Pedidos e Ticket Médio, o card com maior variação em módulo recebe destaque visual — não é sobre ser positivo ou negativo, é sobre ser o que mais mudou.

**Leitura executiva** usa o mesmo cálculo acima como fonte — nenhuma métrica nova é computada só para gerar a frase. Limiar sugerido para gerar uma frase: variação em módulo ≥ 10% (abaixo disso, a variação é considerada ruído do dia a dia e não vira frase).

---

## 5. Estados vazios

- **Empresa sem nenhum `MetricSnapshot`:** tela inteira substituída por `EmptyDashboardState` — mensagem direta ("Você ainda não conectou nenhuma fonte de dados") e botão para `/integracoes`. Nenhum card zerado, nenhum gráfico vazio.
- **Métrica específica sem dado no período** (ex.: cliente não vende no Shopee): o card ou barra daquele canal mostra `EmptyMetricState` ("sem dado"), nunca "R$ 0,00" — zero e ausência de dado são coisas diferentes e não podem ser confundidas na leitura do cliente.
- **Participação por canal quando os três canais estão sem dado:** Bloco 3 inteiro mostra um estado vazio único, não três barras zeradas lado a lado.
- **Histórico curto no gráfico de evolução** (ex.: só 2-3 dias importados): mostra o que existe, com uma nota abaixo do gráfico ("Histórico ainda curto — melhora com mais dias de dado importado").

## 6. Estados de erro

- **Última importação com status `falha`:** `DataStatusBadge` mostra "Com erro", com link direto para o histórico em Integrações. O dashboard continua mostrando o último dado bom que já tinha — uma falha de importação não apaga o que já estava correto no banco.
- **Dado desatualizado (mais de 48h desde a última importação bem-sucedida):** `StaleDataWarning` visível no cabeçalho, mensagem explícita: "Os dados podem não refletir a situação atual — última atualização há X dias." Isso é sobre confiança no dado, não é um Alert de negócio (essa distinção fica mais clara na Sprint 4).
- **Falha técnica de leitura** (banco fora do ar, erro de aplicação — não relacionado à qualidade do dado do cliente): tela de erro genérica com opção de recarregar, visualmente distinta dos estados acima para não ser confundida com "sem dados" ou "desatualizado".

## 7. Critérios de aceite

- Os 9 KPIs obrigatórios aparecem corretos nos três períodos, com variação calculada contra o intervalo anterior comparável definido na seção 4
- Ticket médio é sempre `soma(faturamento) ÷ soma(pedidos)` do intervalo, nunca média simples de tickets diários
- Bloco "Onde está vendendo" soma 100% de participação entre os três canais informados
- Bloco "Pontos de atenção" usa a polaridade invertida corretamente — aumento de ruptura ou atraso aparece em vermelho, não em verde
- Gráfico de evolução alterna entre Faturamento e Pedidos sem recarregar a página, respeitando a janela de dias do período selecionado
- Leitura executiva gera ao menos uma frase quando alguma variação passa do limiar de 10%, mais a frase-síntese final
- `DataStatusBadge` reflete corretamente os três estados (Atualizado / Desatualizado / Sem dados) conforme os critérios da seção 6
- Empresa sem nenhuma fonte configurada vê o `EmptyDashboardState`, nunca uma tela zerada ou quebrada
- Nenhum registro é criado em `Insight` ou `Alert` como resultado de carregar essa tela — essas tabelas seguem vazias até a Sprint 4

## 8. O que não fazer

- Não criar `Insight` nem `Alert` — a Leitura Executiva é texto calculado na hora de exibir a tela, não um registro persistido
- Não construir o módulo Comercial nem o módulo Estoque
- Não criar `Product` nem `InventorySnapshot`
- Não exibir `estoque_total` neste dashboard — a métrica existe no banco desde a Sprint 2, mas fica reservada para o futuro módulo de Estoque
- Não criar gráficos complexos: sem eixo duplo, sem múltiplas métricas sobrepostas, sem zoom ou seleção de intervalo livre
- Não criar filtros avançados: sem filtro por canal, por SKU ou por data customizada — só os três períodos fixos (Hoje, 7 dias, 30 dias)
- Não adicionar exportação (PDF, Excel) do dashboard
- Não comparar com meta ou orçamento — não existe entidade de meta na V1
- Não otimizar performance ou adicionar cache prematuramente — a prioridade é o cálculo estar correto, não estar rápido
