---
id: GOVERNANCE_Arquitetura_Borges_Core
tipo: GOVERNANCE
titulo: Arquitetura do Repositório Borges Core
status: ativo
versao: v1
criado_em: 2026-07-02
---

# Borges Core — Arquitetura do Repositório

**Nota de escopo:** este documento organiza a estrutura de documentação do Borges Core com base no `00_MANIFESTO_BORGES_PERFORMANCE`, no `02_PRODUCT_VISION` e no `03_PRODUCT_ARCHITECTURE` já aprovados. Nenhum conceito novo é introduzido — os 5 Pilares (Facts, Knowledge, Playbooks, Business Questions, Learning), o Business Engine e o fluxo Pergunta→Dados→Evidências→Conhecimento→Playbooks→Hipóteses→Confiança→Recomendação→Resultado Esperado→Validação→Aprendizado vêm literalmente desses documentos. Esta versão substitui a proposta preliminar de estrutura discutida antes do envio dos documentos oficiais.

Este documento não contém código nem conteúdo de conhecimento (nenhum Playbook, Rule ou Knowledge real é escrito aqui) — apenas a arquitetura que vai abrigá-los.

---

## 1. Estrutura completa do repositório

```
/borges-core
  README.md
  /00-governance
    GOVERNANCE_Arquitetura_Borges_Core.md   (este documento)
  /01-business-questions
    /por-dominio
      /comercial
      /estoque
      /logistica
      /operacoes
      /financeiro
      /administrativo
  /02-facts
    /sources               (o que cada fonte fornece — Bling, Mercado Livre, Shopee, Sheets, Maestro)
    /data-dictionary
    /metrics
  /03-knowledge
    /marketplace
    /ecommerce
    /logistica
    /operacoes
    /administrativo        (Kotler, Porter, Lean e outros frameworks administrativos)
    /consultoria-borges
    /kpis
    /glossario
  /04-playbooks
    /genericos
    /clientes
      /BLWBK
      /HGZ
      /CLSCR
      /PDRS
      /MGJ
  /05-business-engine
    /rules
    /models
    /recommendations
    /prompts
    /insights
    /alerts
    /actions
  /06-learning
    /cases
    /decisions
    /retrospectives
  /07-clients
    /BLWBK
    /HGZ
    /CLSCR
    /PDRS
    /MGJ
  /08-products
    /CI
    /WMS
    /IA
    /APP
    /API
  /09-templates
  /_meta
    CODES.md
    INDEX.md
```

### 1.1 Por que essa organização

O Manifesto define 5 Pilares: **Facts, Knowledge, Playbooks, Business Questions e Learning**. O Product Architecture acrescenta o **Business Engine** como a camada que consome os quatro primeiros pilares para produzir Rules, cálculo de confiança (Models), Recommendations, evidências e Plano de Ação. Business Engine não é um sexto pilar — é o mecanismo que opera sobre os pilares. A estrutura física respeita essa distinção: pastas `01` a `04` e `06` são os Pilares; a pasta `05` é o Business Engine.

`Business Questions` vem em primeiro lugar na numeração (`01`), antes até de `Facts`, porque o Manifesto é explícito: *"o sistema não começa pelos indicadores, começa pelas perguntas"* e *"nenhuma tela nasce antes da pergunta que ela responde"*.

### 1.2 Função de cada pasta

| Pasta | Pilar/Camada | Função | O que NÃO vai aqui |
|---|---|---|---|
| `/00-governance` | — | Regras do próprio repositório | Conhecimento de negócio |
| `/01-business-questions` | Facts→Pilar Business Questions | "As perguntas que empresários fazem diariamente" — o coração do sistema | A resposta em si (isso vive espalhado nos outros pilares, referenciado) |
| `/02-facts` | Pilar Facts | O que cada fonte registra e o dicionário de dados — nunca os dados em si, que ficam no banco de cada produto | Interpretação do fato (isso é Knowledge ou Rule) |
| `/03-knowledge` | Pilar Knowledge | Conceitos administrativos, frameworks (Kotler, Porter, Lean), marketplace, operações, consultoria Borges, KPIs, glossário | Regra de disparo automático (isso é Rule) |
| `/04-playbooks` | Pilar Playbooks | O DNA operacional de cada empresa — genérico e por cliente | Perfil cadastral do cliente (isso é `/07-clients`) |
| `/05-business-engine` | Business Engine | Rules, Models (cálculo de confiança), Recommendations, Prompts, Insights, Alerts, Actions — a tradução de conhecimento em algo quase executável | Conhecimento conceitual (isso é `/03-knowledge`) |
| `/06-learning` | Pilar Learning | Casos reais, decisões de método, retrospectivas — o que cada interação ensina | Tarefa do dia a dia (não é patrimônio, é gestão de projeto) |
| `/07-clients` | — | Perfil de cada cliente e índice do que existe sobre ele no resto do repositório | Cópia de Playbook/KPI (só referência) |
| `/08-products` | — | O que cada produto consome do Core e sua fronteira de escopo | Documentação técnica/sprint de cada produto (fica no repositório do próprio produto) |
| `/09-templates` | — | Os 15 templates oficiais (seção 3) | Documento preenchido com conteúdo real |
| `/_meta` | — | Tabela de códigos e índice mestre | Conhecimento de negócio |

---

## 2. Padrão oficial de IDs

### 2.1 Prefixos

Um prefixo por tipo de documento, usando exatamente o vocabulário do método (nomes em inglês, como já aparecem no Manifesto e na Arquitetura):

| Tipo | Prefixo | Pasta padrão |
|---|---|---|
| Business Question | `BQ` | `/01-business-questions` |
| KPI | `KPI` | `/03-knowledge/kpis` |
| Metric | `METRIC` | `/02-facts/metrics` |
| Data Dictionary | `DATA_DICTIONARY` | `/02-facts/data-dictionary` |
| Knowledge | `KNOWLEDGE` | `/03-knowledge` |
| Playbook | `PLAYBOOK` | `/04-playbooks` |
| Rule | `RULE` | `/05-business-engine/rules` |
| Model | `MODEL` | `/05-business-engine/models` |
| Recommendation | `RECOMMENDATION` | `/05-business-engine/recommendations` |
| Prompt | `PROMPT` | `/05-business-engine/prompts` |
| Insight | `INSIGHT` | `/05-business-engine/insights` |
| Alert | `ALERT` | `/05-business-engine/alerts` |
| Action | `ACTION` | `/05-business-engine/actions` |
| Case | `CASE` | `/06-learning/cases` |
| Learning | `LEARNING` | `/06-learning` |

Prefixos de apoio, fora dos 15 templates mas necessários à estrutura:

| Tipo | Prefixo | Observação |
|---|---|---|
| Manifesto | `MANIFESTO` | Sem número — documento único |
| Vision | `VISION` | Um por produto ou por ecossistema |
| Architecture | `ARCHITECTURE` | Sem número — documento único |
| Perfil de Cliente | `CLIENT_{CODIGO}` | Um por cliente, sem número sequencial |
| Consumo de Produto | `PRODUCT_{CODIGO}` | Um por produto, sem número sequencial |

### 2.2 Regra de numeração

- Sequencial, por prefixo, começando em 1
- **3 dígitos** para todos os tipos (`RULE_014`, `MODEL_005`, `INSIGHT_007`), **exceto Business Question, que usa 4 dígitos** (`BQ_0001`) — reflete que perguntas de negócio são, por natureza, o tipo de documento com maior volume esperado ao longo dos anos
- Quando o documento é específico de um cliente, o código do cliente entra **entre o prefixo e o número**, e a sequência numérica passa a ser própria daquele par prefixo+cliente: `PLAYBOOK_BLWBK_001`, `PLAYBOOK_HGZ_001` (cada cliente tem sua própria contagem, começando em 1)

### 2.3 Regra de nome de arquivo

```
{ID}_{Slug_Em_Title_Case_Sem_Acento}.md
```

Exemplos: `BQ_0001_Como_Estao_Minhas_Vendas.md`, `KPI_001_Pedidos_Expedidos.md`, `RULE_014_Queda_Conversao.md`, `PLAYBOOK_BLWBK_001_Expedicao.md`, `INSIGHT_007_Queda_Faturamento.md`, `ALERT_009_Ruptura_Critica.md`, `ACTION_012_Revisar_Campanha_Shopee.md`.

O **ID** (sem o slug) é o identificador estável usado em qualquer referência entre documentos — o slug existe só para leitura humana e pode, em tese, mudar sem quebrar referência nenhuma, desde que o ID no início do nome do arquivo permaneça.

### 2.4 Códigos de escopo

**Clientes** (Consultoria):

| Código | Cliente |
|---|---|
| `BLWBK` | Blowback |
| `HGZ` | HGZ |
| `CLSCR` | Classe Couro |
| `PDRS` | Pedrosa |
| `MGJ` | Megaju |

**Produtos** (Tecnologia):

| Código | Produto |
|---|---|
| `CI` | Centro de Inteligência |
| `WMS` | Maestro WMS |
| `IA` | IA Borges |
| `APP` | Aplicativo (mobile) |
| `API` | APIs Borges |

**Domínios**: `COM` (comercial), `EST` (estoque), `LOG` (logística), `OPS` (operações), `FIN` (financeiro), `ADM` (administrativo), `MKT` (marketplace/e-commerce geral)

Essas três tabelas são a semente de `/_meta/CODES.md` — a lista viva de códigos, que cresce conforme novos clientes e produtos entram no ecossistema.

---

## 3. Relacionamentos

Todo documento carrega, no front-matter, um campo `relacionados` com a lista de IDs que ele referencia — nunca cópia de conteúdo. A tabela abaixo define quais relações fazem sentido entre tipos (o que cada tipo *pode* referenciar):

| De | Pode referenciar |
|---|---|
| Business Question | KPI, Rule, Knowledge, Playbook, Recommendation, Model, Case, Data Dictionary |
| Knowledge | Data Dictionary, Case |
| KPI | Metric (1 ou mais) |
| Metric | Data Dictionary |
| Rule | Metric, KPI, Knowledge (fundamento), Model (cálculo de confiança) |
| Model | Rule |
| Recommendation | Rule (origem), Playbook, Action |
| Prompt | Knowledge, Business Question |
| Playbook (cliente) | Playbook (genérico, obrigatório), Knowledge |
| Insight | Rule, Metric |
| Alert | Rule, Insight |
| Action | Recommendation, Alert, Insight, Playbook |
| Case | Client, Playbook, Rule, Recommendation |
| Learning | Qualquer tipo (o que motivou a decisão/aprendizado) |

Esta é a mesma tabela que resolve o pedido do item 5: uma Business Question referencia KPIs, Rules, Knowledge, Playbooks, Recommendations, Prompts, Models, Cases e Data Dictionary — mas a relação não é exclusiva dela; cada tipo tem sua própria rede de referências válidas, e é essa rede que substitui qualquer necessidade de duplicar conteúdo entre documentos.

---

## 4. Diagrama — como o Borges Core conversa

```
                         BUSINESS QUESTION
                    (a pergunta do empresário)
                                │
            ┌───────────────────┼───────────────────┐
            │                   │                   │
          FACTS              KNOWLEDGE           PLAYBOOKS
     (o que aconteceu)    (por que acontece)  (como esta empresa
                                                   trabalha)
            │                   │                   │
            └───────────────────┼───────────────────┘
                                │
                        BUSINESS ENGINE
                 aplica RULES sobre os fatos,
                 usa MODELS para calcular confiança
                                │
                          RECOMMENDATION
              evidências + conceitos + confiança +
                       resultado esperado
                                │
                ┌────────────────┼────────────────┐
                │                │                │
             INSIGHT           ALERT            ACTION
        (o que / por quê)  (onde agir agora)  (plano de ação)
                                │
                            RESULTADO
                                │
                             LEARNING
              o resultado alimenta de volta Knowledge,
                     Playbooks e Rules
                                │
                    ══════════════════════
                          PRODUTOS
                    (executam, não pensam)
                    ══════════════════════
                                │
          ┌──────────────────────┼──────────────────────┬───────────┐
          │                      │                      │           │
    CENTRO DE                MAESTRO                 IA BORGES     APP
    INTELIGÊNCIA                WMS
```

Este diagrama estende o exemplo original (Business Question → Knowledge → Rules → Recommendation → Products → Centro de Inteligência → Maestro → IA) incorporando o que o `02_PRODUCT_VISION` e o `03_PRODUCT_ARCHITECTURE` já documentam sobre o fluxo completo (Facts e Playbooks entrando junto com Knowledge, Models calculando confiança, e o ciclo de Learning fechando de volta para o início) — nenhum elemento novo foi inventado, apenas reunidos num único desenho.

---

## 5. Como os produtos consomem o Borges Core

Regra absoluta, citada literalmente do `03_PRODUCT_ARCHITECTURE`: *"O Centro de Inteligência NÃO possui conhecimento próprio. O Maestro NÃO possui conhecimento próprio. Toda inteligência vem do Borges Core. Os produtos apenas executam."*

O que cada produto consome (também literal do documento fonte):

| Produto | Consome |
|---|---|
| Centro de Inteligência | Business Questions, Knowledge, Rules, Playbooks |
| Maestro WMS | Knowledge, Rules, Playbooks |
| IA Borges | Knowledge, Business Questions, Rules |
| Aplicativo | Ainda não detalhado nos documentos-fonte — por ora, tratar como "a definir" em `/08-products/APP/PRODUCT_APP.md`, sem inventar escopo |

### 5.1 Mecanismo de consumo, em duas fases

**Fase atual — Borges Core como documentação.** Cada produto mantém um único arquivo `PRODUCT_{CODIGO}.md` em `/08-products/{CODIGO}`, listando exatamente quais IDs (BQ, KPI, RULE, PLAYBOOK etc.) aquele produto implementa. A equipe de engenharia lê esses documentos e implementa a lógica manualmente no produto — sempre apontando de volta para o ID de origem em comentário/documentação técnica, nunca reescrevendo a definição.

**Fase futura — Borges Core como serviço.** O mesmo conteúdo, hoje em Markdown, se torna consultável via banco de dados ou API, e os produtos resolvem Business Questions em tempo de execução consultando o Borges Core diretamente, em vez de ter a regra fixada no código do produto.

### 5.2 Nota de rastreabilidade retroativa

O catálogo de métricas do Centro de Inteligência (definido na especificação técnica da Sprint 2, antes deste documento existir) foi criado diretamente na documentação do produto — faturamento, pedidos, ticket_medio, vendas por canal, entre outras. A partir da criação do Borges Core, esse é exatamente o tipo de definição que deveria nascer primeiro como `METRIC_xxx`/`KPI_xxx` aqui, com o produto apenas referenciando os IDs. Essa migração é sinalizada aqui como observação — não é executada nesta tarefa, que é apenas de estrutura.

---

## 6. Convenção oficial de documentação

### 6.1 Nomes de arquivo

Já definidos na seção 2.3 — `{ID}_{Slug}.md`.

### 6.2 Versões

Todo documento carrega `versao` no front-matter (`v1`, `v2`...). Nunca se cria uma cópia do arquivo para uma nova versão (nada de `_v2.md`) — o histórico de mudança vive no controle de versão (Git); o front-matter só declara a versão atual. Mudanças estruturais relevantes (ex.: novo campo obrigatório em um tipo de template) são registradas como um `LEARNING_xxx` em `/06-learning`, não apagadas.

### 6.3 Idiomas

Português é o idioma padrão de todo o conteúdo. Os termos do próprio método (Business Question, Facts, Knowledge, Playbook, Learning, Rule, Model, Insight, Alert, Action, Recommendation) permanecem em inglês, exatamente como já aparecem no Manifesto, no Product Vision e no Product Architecture — não são traduzidos porque são nomes próprios do método, não palavras comuns. Se, no futuro, uma versão em outro idioma for necessária, o sufixo de idioma entra no nome do arquivo (`_EN.md`) — nunca uma pasta paralela duplicada.

### 6.4 Exemplos

Um exemplo real nunca fica embutido solto dentro do corpo de um documento de definição (Knowledge, Rule, Playbook). Todo exemplo real vira um `CASE_xxx` em `/06-learning/cases`, referenciado pelo documento de definição via `relacionados`. Isso existe para impedir que um documento de conceito vire uma colcha de retalhos de anedotas ao longo dos anos.

### 6.5 Referências

Toda referência entre documentos é feita pelo campo `relacionados` do front-matter, usando o ID do documento referenciado — nunca por link solto de texto corrido, nunca por cópia de trecho de outro documento.

### 6.6 Front-matter padrão

Todo documento do repositório, independentemente do tipo, carrega:

```
id, tipo, titulo, dominio, produtos_consumidores, clientes, status (rascunho/ativo/obsoleto), versao, criado_em, atualizado_em, relacionados
```

---

## 7. Análise crítica

### 7.1 Pontos fortes

A estrutura espelha exatamente os 5 Pilares e o Business Engine já validados no Manifesto, no Product Vision e no Product Architecture — não introduz nenhum conceito novo, apenas dá endereço físico ao que já foi decidido. IDs curtos e estáveis, separados do slug legível, conciliam a necessidade de máquina (referência, futura migração para banco) com a de leitura humana, sem conflito entre as duas. A separação entre Playbook genérico e Playbook de cliente, e entre Case/Learning (temporário, datado) e Knowledge (consolidado), cria um ciclo real de maturação do conhecimento, em vez de um despejo plano de documentos soltos. A fronteira entre Borges Core (conhecimento) e cada produto (execução) já está declarada no documento oficial de arquitetura — *"todo conhecimento pertence ao Borges Core"* — e a estrutura física apenas reforça essa fronteira em vez de criar uma nova.

### 7.2 Riscos

**Gaveta morta.** Nenhuma pasta, por si só, garante que alguém volte e atualize uma Rule ou um Knowledge quando o contexto que os originou mudar. Estrutura não substitui dono — precisa de um responsável por pilar, não só de um lugar certo para o documento.

**Fork silencioso de Playbook.** Um Playbook de cliente pode, na prática, divergir tanto do genérico que deixa de ser uma variação e vira outra coisa — sem que ninguém formalize isso como atualização do genérico. Esse julgamento (quando a exceção de um cliente deveria virar regra geral) é humano, a estrutura não decide isso sozinha.

**Fronteira ambígua entre Knowledge, Model e Rule.** A diferença entre "isso explica" (Knowledge), "isso calcula confiança" (Model) e "isso dispara" (Rule) é sutil na prática e vai gerar dúvida real na hora de classificar um documento novo. Recomenda-se que essa classificação seja literalmente a primeira pergunta de qualquer revisão de documento novo, não algo que a estrutura resolve sozinha.

**Duplicação já em curso.** O catálogo de métricas do Centro de Inteligência (Sprint 2, anterior à criação deste repositório) foi definido direto na especificação do produto. É uma duplicação de fato — a métrica deveria nascer aqui, o produto deveria só referenciar. Se o Borges Core for criado sem migrar essa definição, a divergência entre os dois já começa no primeiro dia.

**Colisão de numeração manual.** Numeração sequencial por prefixo falha quando duas pessoas criam, por exemplo, `RULE_015` ao mesmo tempo, em paralelo. Isso exige um processo simples — reservar o próximo número num índice central antes de criar o arquivo — desde o início, não só quando o conflito já tiver acontecido.

### 7.3 Como manter essa biblioteca viva durante anos

Vincular a manutenção ao próprio ritual da consultoria, que o Manifesto já descreve: *"toda reunião gera perguntas, toda melhoria gera um Playbook, todo problema recorrente gera uma regra"*. Ao final de cada ciclo de consultoria com um cliente, checagem obrigatória: o que foi aprendido virou `CASE` ou `LEARNING` antes da reunião ser arquivada? Definir um dono por Pilar — alguém responde por Knowledge como um todo, alguém por Rules como um todo — mesmo que não escreva cada documento individualmente. Usar `/_meta/INDEX.md` como painel de saúde, não só lista: sinalizar documentos sem atualização há muito tempo, ou sem nenhuma referência vinda de outro documento (órfãos).

### 7.4 Como evitar que vire um repositório de documentos esquecidos

Nenhum documento deveria existir sem estar referenciado por ao menos um outro — um Knowledge sem nenhuma Rule ou Business Question que o use é sinal de conhecimento acumulado sem aplicação prática, e vale mais não criar do que criar solto. Preferir poucos documentos vivos e efetivamente usados a muitos documentos completos e ignorados — a própria diretriz recebida para esta tarefa, *"a qualidade da organização é mais importante do que a quantidade de documentos"*, deveria virar critério de aceite de revisão, não permanecer só como princípio abstrato.
