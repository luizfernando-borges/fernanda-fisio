---
id: GOVERNANCE_Templates_Oficiais
tipo: GOVERNANCE
titulo: Templates Oficiais do Borges Core
status: ativo
versao: v1
criado_em: 2026-07-02
---

# Borges Core — Templates Oficiais

Os 15 templates abaixo são a forma oficial de criar qualquer novo documento no Borges Core. Cada um define a estrutura — nenhum contém conteúdo real. Ao criar um documento novo, copie o template correspondente, preencha os campos e salve com o nome no padrão `{ID}_{Slug}.md` (ver `GOVERNANCE_Arquitetura_Borges_Core.md`, seção 2).

Todo template compartilha o front-matter padrão (`id, tipo, titulo, dominio, produtos_consumidores, clientes, status, versao, criado_em, atualizado_em, relacionados`) — ele não é repetido em cada seção abaixo para não poluir a leitura, mas é obrigatório em todos.

---

## BQ_TEMPLATE — Business Question

**Objetivo:** capturar uma pergunta real de negócio que o produto deve responder. É o ponto de entrada de qualquer nova funcionalidade — nada nasce antes da pergunta.

**Quando utilizar:** sempre que uma dúvida recorrente de cliente, consultoria ou observação de operação for identificada, antes de cogitar qualquer tela, indicador ou funcionalidade.

**Campos obrigatórios:**
- Pergunta (texto exato, na linguagem do empresário — não reescrita em termos técnicos)
- Domínio
- Quem pergunta (papel: CEO, diretor, gerente, supervisor, consultor, analista)
- Frequência (diária, semanal, pontual)
- Status (sem resposta, parcialmente respondida, respondida)
- Origem (cliente específico, consultoria, observação geral)

**Relacionamentos:** KPI, Rule, Knowledge, Playbook, Recommendation, Model, Case, Data Dictionary

**Exemplo de estrutura:**
```
Pergunta:
Contexto de quando ela surge:
O que precisa ser verdade para respondê-la bem:
KPIs relacionados:
Regras relacionadas:
Status atual:
```

**Boas práticas:** escrever a pergunta com a mesma frase que o empresário usaria — nunca "criar dashboard de X" no lugar da pergunta real. Uma Business Question sem nenhum KPI/Rule/Knowledge associado ainda é válida — significa que a biblioteca ainda não tem resposta pronta, e isso deve aparecer no campo Status, não ser escondido.

---

## KPI_TEMPLATE — Indicador de Negócio

**Objetivo:** definir formalmente um indicador com significado de negócio, não apenas uma fórmula.

**Quando utilizar:** quando uma Business Question precisa de um número específico, com interpretação, para ser respondida.

**Campos obrigatórios:**
- Nome
- Definição em linguagem simples (o que significa para o negócio, não a fórmula)
- Fórmula, expressa em termos de Metrics
- Unidade
- Polaridade (aumento é bom ou ruim)
- Domínio
- Benchmark ou faixa saudável, quando existir

**Relacionamentos:** Metric (um ou mais), Business Question, Rule, Knowledge

**Exemplo de estrutura:**
```
Nome:
Definição:
Fórmula (em termos de Metrics):
Unidade:
Polaridade:
Benchmark / faixa saudável:
Perguntas de negócio que ele ajuda a responder:
```

**Boas práticas:** nunca definir um KPI só pela fórmula — sempre explicar o que ele significa para quem decide. Se dois KPIs têm a mesma fórmula com nomes diferentes, são o mesmo KPI — unificar, não duplicar.

---

## RULE_TEMPLATE — Regra de Inferência

**Objetivo:** documentar uma condição que, observada nos fatos, gera um Insight ou um Alert — a fonte de verdade do Rule Engine.

**Quando utilizar:** quando um padrão recorrente e observável nos dados justifica uma leitura automática, em vez de depender da atenção manual de alguém.

**Campos obrigatórios:**
- Nome
- Métrica(s)/KPI(s) observados
- Condição de disparo (limiar, comparação, janela de tempo)
- Severidade
- Confiança padrão
- Domínio

**Relacionamentos:** Metric, KPI, Knowledge (fundamento), Model (cálculo de confiança), Recommendation, Insight, Alert

**Exemplo de estrutura:**
```
Nome:
O que observa:
Condição de disparo:
Severidade:
Confiança:
Fundamento (Knowledge relacionado):
Recomendação associada:
```

**Boas práticas:** toda regra aponta para um Knowledge que explique por que aquela condição importa. Regra sem fundamento documentado é regra arbitrária, e viola o princípio do Manifesto de nunca afirmar sem evidência.

---

## KNOWLEDGE_TEMPLATE — Conhecimento

**Objetivo:** registrar um conceito, framework ou boa prática que explica por que os fatos acontecem.

**Quando utilizar:** ao trazer um conceito externo (ex.: Kotler, Porter, Lean) ou ao consolidar um entendimento próprio da Borges sobre marketplace, operação ou administração.

**Campos obrigatórios:**
- Título do conceito
- Domínio
- Fonte/origem (autor, framework, ou "Consultoria Borges" quando for conhecimento proprietário)
- Definição
- Quando se aplica
- Quando NÃO se aplica

**Relacionamentos:** Business Question, Rule, Playbook, Data Dictionary, Case

**Exemplo de estrutura:**
```
Conceito:
Origem:
Definição:
Aplicação prática:
Limites de aplicação:
Perguntas de negócio que ajuda a responder:
```

**Boas práticas:** sempre citar a origem quando não for conhecimento proprietário Borges. Nunca misturar a definição do conceito com um exemplo real de aplicação — o exemplo vira um `CASE` referenciado, não um parágrafo dentro do Knowledge.

---

## PLAYBOOK_TEMPLATE — Playbook

**Objetivo:** descrever como uma empresa específica realmente trabalha, ou consolidar um padrão de processo genérico recomendado.

**Quando utilizar:** ao mapear o processo real de um cliente durante a consultoria, ou ao consolidar um processo genérico a partir de padrões observados em múltiplos clientes.

**Campos obrigatórios:**
- Cliente (ou "genérico")
- Domínio/processo
- Passos do processo real
- Responsáveis (papéis)
- Particularidades (o "DNA" daquele cliente)
- Playbook genérico de origem (obrigatório se for versão de cliente)

**Relacionamentos:** Knowledge (fundamento), Client, Rule, Recommendation, Case

**Exemplo de estrutura:**
```
Processo:
Cliente (ou "genérico"):
Passos:
Responsáveis:
Particularidades:
Baseado em (playbook genérico, se aplicável):
```

**Boas práticas:** um Playbook de cliente nunca copia o genérico inteiro — descreve só a diferença. Se não há diferença relevante em relação ao genérico, não crie o Playbook de cliente.

---

## MODEL_TEMPLATE — Modelo de Confiança

**Objetivo:** documentar como um grau de confiança ou uma pontuação é calculado.

**Quando utilizar:** quando uma Rule ou Recommendation precisa de um cálculo de confiança mais elaborado que um limiar simples.

**Campos obrigatórios:**
- Nome
- O que calcula
- Inputs (métricas/variáveis usadas)
- Lógica de cálculo, em linguagem clara (não código)
- Faixa de saída
- Limitações conhecidas

**Relacionamentos:** Rule, Metric, KPI

**Exemplo de estrutura:**
```
Nome:
O que calcula:
Inputs:
Lógica de cálculo:
Faixa de saída:
Limitações conhecidas:
```

**Boas práticas:** todo modelo declara suas limitações explicitamente — é isso que sustenta o princípio do Manifesto de nunca afirmar quando existe apenas hipótese.

---

## CASE_TEMPLATE — Caso Real

**Objetivo:** registrar um exemplo real de aplicação do método, com resultado conhecido.

**Quando utilizar:** sempre que uma recomendação foi aplicada e existe um resultado observável — positivo ou negativo — para documentar.

**Campos obrigatórios:**
- Cliente
- Contexto
- O que foi recomendado
- O que foi de fato feito
- Resultado observado
- Lição extraída

**Relacionamentos:** Client, Playbook, Rule, Recommendation, Knowledge

**Exemplo de estrutura:**
```
Contexto:
Recomendação aplicada:
Ação tomada:
Resultado:
Lição:
```

**Boas práticas:** registrar tanto os casos de sucesso quanto os de recomendação que não funcionou como esperado — um Case negativo é tão valioso quanto um positivo, e é o que mais protege o método do viés de só guardar o que deu certo.

---

## PROMPT_TEMPLATE — Prompt Estruturado

**Objetivo:** documentar um prompt estruturado para uso por IA — hoje aplicado manualmente, no futuro pela IA Borges.

**Quando utilizar:** ao formalizar como pedir a um modelo de linguagem para gerar uma leitura, resposta ou recomendação usando a biblioteca do Borges Core.

**Campos obrigatórios:**
- Caso de uso
- Objetivo do prompt
- Contexto necessário (quais outros documentos ele precisa consumir)
- Estrutura do prompt
- Exemplo de saída esperada
- Produto onde é usado

**Relacionamentos:** Business Question, Knowledge, Rule

**Exemplo de estrutura:**
```
Caso de uso:
Objetivo:
Contexto necessário (Knowledge/Rule/BQ consumidos):
Estrutura do prompt:
Exemplo de saída esperada:
Produto de uso:
```

**Boas práticas:** todo prompt deve poder citar suas fontes (quais Knowledge/Rule usou) — nunca gerar uma afirmação sem essa rastreabilidade, seguindo o princípio de explicabilidade do Manifesto.

---

## RECOMMENDATION_TEMPLATE — Recomendação

**Objetivo:** definir o que sugerir quando uma Rule dispara.

**Quando utilizar:** sempre que uma Rule é criada e precisa de uma ação sugerida associada a ela.

**Campos obrigatórios:**
- Regra de origem
- Texto da recomendação (no formato "Minha recomendação é..." ou "Com base nos dados disponíveis...")
- Evidências necessárias para sustentar a recomendação
- Resultado esperado
- Como validar se a recomendação funcionou

**Relacionamentos:** Rule, Playbook, Action, Model (confiança)

**Exemplo de estrutura:**
```
Regra de origem:
Texto da recomendação:
Evidências necessárias:
Resultado esperado:
Como validar:
Playbook relacionado (se houver):
```

**Boas práticas:** seguir sempre o formato de linguagem definido no Manifesto — nunca a forma imperativa ("faça isso"), sempre "minha recomendação é" ou equivalente.

---

## DATA_DICTIONARY_TEMPLATE — Dicionário de Dados

**Objetivo:** documentar o significado de negócio de um campo ou fonte de dado bruto.

**Quando utilizar:** ao integrar uma nova fonte (Bling, Mercado Livre, Shopee, planilha, Maestro) ou ao formalizar um campo já usado informalmente.

**Campos obrigatórios:**
- Fonte
- Nome do campo
- Significado de negócio
- Tipo de dado
- Unidade
- Observações de qualidade (ex.: pode vir vazio, pode divergir entre lojas/contas)

**Relacionamentos:** Metric, Knowledge

**Exemplo de estrutura:**
```
Fonte:
Campo:
Significado de negócio:
Tipo:
Unidade:
Observações de qualidade:
```

**Boas práticas:** documentar mesmo os campos "óbvios" — o que é óbvio para quem integrou a fonte não é óbvio para quem só consome o dado depois, anos mais tarde.

---

## LEARNING_TEMPLATE — Aprendizado / Decisão

**Objetivo:** registrar uma decisão de método ou um aprendizado geral que muda o entendimento do Borges Core.

**Quando utilizar:** sempre que uma decisão de método é tomada, ou um aprendizado não ligado a um cliente específico emerge de alguma interação.

**Campos obrigatórios:**
- Data
- O que mudou ou foi decidido
- Por que (motivação)
- O que motivou (evento, observação, caso)
- Impacto (quais outros documentos precisam ser revisados)

**Relacionamentos:** qualquer tipo (o que motivou a mudança)

**Exemplo de estrutura:**
```
Data:
Decisão / aprendizado:
Motivação:
Documentos afetados:
```

**Boas práticas:** nunca editar ou apagar um Learning antigo, mesmo que a decisão tenha mudado depois — criar um novo Learning referenciando o anterior, preservando o histórico de raciocínio ao longo dos anos.

---

## INSIGHT_TEMPLATE — Tipo de Insight

**Objetivo:** definir o *tipo* de leitura ("o que aconteceu e por quê") que uma Rule pode gerar — o catálogo, não a instância do dia a dia de um cliente específico.

**Quando utilizar:** ao criar uma nova Rule que precisa de um texto padrão de insight associado a ela.

**Campos obrigatórios:**
- Regra de origem
- Título padrão
- Texto padrão, com placeholders (ex.: "{metrica} caiu {variacao}% em relação a {periodo}")
- Severidades possíveis
- Domínio

**Relacionamentos:** Rule, Metric, KPI

**Exemplo de estrutura:**
```
Regra de origem:
Título padrão:
Texto padrão (com placeholders):
Severidades possíveis:
```

**Boas práticas:** linguagem sempre executiva, nunca cita nome técnico de campo ou tabela. Este documento é o tipo/catálogo — a instância real (o insight gerado para um cliente específico em um dia específico) vive no banco de dados do produto, não no Borges Core.

---

## ALERT_TEMPLATE — Tipo de Alerta

**Objetivo:** definir o *tipo* de sinal acionável ("onde agir agora") associado a uma Rule crítica.

**Quando utilizar:** quando um Insight, a partir de determinada severidade, deve virar um chamado explícito de atenção — não todo Insight vira Alert.

**Campos obrigatórios:**
- Regra/Insight de origem
- Condição de escalonamento (quando um Insight vira Alert)
- Texto padrão
- Nível (atenção, crítico)

**Relacionamentos:** Rule, Insight, Action

**Exemplo de estrutura:**
```
Origem (Rule/Insight):
Condição de escalonamento:
Texto padrão:
Nível:
```

**Boas práticas:** reservar o Alert para o que realmente exige ação — se todo Insight vira Alert, o alerta perde força (fadiga de alerta) e o cliente para de prestar atenção.

---

## ACTION_TEMPLATE — Tipo de Ação

**Objetivo:** definir o *tipo* de ação sugerida que compõe um Plano de Ação.

**Quando utilizar:** quando uma Recommendation ou um Alert precisa se traduzir em algo executável e acompanhável pelo cliente.

**Campos obrigatórios:**
- Origem (Recommendation ou Alert)
- Título padrão da ação
- Responsável sugerido (papel, não pessoa)
- Prazo sugerido
- Critério de conclusão

**Relacionamentos:** Recommendation, Alert, Playbook

**Exemplo de estrutura:**
```
Origem:
Título padrão:
Responsável sugerido (papel):
Prazo sugerido:
Critério de conclusão:
```

**Boas práticas:** toda ação precisa de um critério de conclusão verificável — "revisar campanha" não é verificável, "campanha X pausada ou ajustada" é.

---

## METRIC_TEMPLATE — Métrica

**Objetivo:** definir uma unidade mínima e mensurável de fato — a matéria-prima de KPIs e Rules.

**Quando utilizar:** ao identificar um número que a operação precisa acompanhar, mesmo antes de ele virar um KPI formal.

**Campos obrigatórios:**
- Nome
- Fonte de dado (Data Dictionary relacionado)
- Unidade
- Agregação (soma, média, contagem)
- Granularidade (diária, por pedido, por SKU)

**Relacionamentos:** Data Dictionary, KPI, Rule

**Exemplo de estrutura:**
```
Nome:
Fonte:
Unidade:
Agregação:
Granularidade:
```

**Boas práticas:** uma métrica não carrega opinião — é fato agregado. Qualquer interpretação de "isso é bom ou ruim" pertence ao KPI ou à Rule que a usa, nunca à métrica em si.
