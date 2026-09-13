# Borges Core — Arquitetura da Documentação

**Papel deste documento:** especificação estrutural do repositório `borges-core`. Não contém manifesto, playbooks, regras ou KPIs reais — apenas a arquitetura que vai abrigá-los. Nenhuma decisão de produto é tomada ou alterada aqui.

**Premissa de design:** o Borges Core é o patrimônio intelectual da Borges Performance — conhecimento de negócio, marketplace, e-commerce, logística, operações e consultoria, organizado para durar anos e para alimentar mais de um produto (Centro de Inteligência hoje; Maestro WMS, IA Borges, App e APIs no futuro) sem que cada produto precise redescobrir ou reescrever o que já existe.

**Fronteira importante:** `borges-core` é um repositório separado do código de cada produto. Ele não contém especificação técnica de sprint, schema de banco ou arquitetura de aplicação — isso vive no repositório de cada produto (ex.: os documentos de arquitetura e build spec do Centro de Inteligência continuam onde estão hoje). O que o `borges-core` contém é o conhecimento de negócio que qualquer produto pode consumir.

---

## 1. Estrutura completa do repositório

```
/borges-core
  /00-governanca
  /01-manifesto
  /02-visao
    /ecossistema
    /produtos
  /03-arquitetura-de-negocio
    /dominios
  /04-perguntas-de-negocio
    /por-dominio
  /05-conhecimento
    /marketplace
    /ecommerce
    /logistica
    /estoque
    /comercial
    /operacoes
    /administrativo
    /consultoria
    /frameworks
    /glossario
  /06-playbooks
    /genericos
    /clientes
      /BLWBK
      /HGZ
  /07-regras
    /por-dominio
  /08-recomendacoes
    /por-dominio
  /09-prompts
    /por-caso-de-uso
  /10-kpis
    /por-dominio
  /11-aprendizado
    /decisoes
    /retrospectivas
    /casos
    /erros
  /12-clientes
    /BLWBK
    /HGZ
  /13-produtos
    /CI
    /WMS
    /IA
    /APP
    /API
  /14-templates
  /15-estudos
  /_meta
```

### 1.1 Função de cada pasta

| Pasta | Função | O que NÃO vai aqui |
|---|---|---|
| `/00-governanca` | Regras do próprio repositório: convenções, taxonomia, processo de contribuição, changelog da estrutura | Conteúdo de negócio |
| `/01-manifesto` | Propósito, crenças e princípios da Borges Performance — o "porquê" que quase nunca muda | Estratégia de produto (isso é `/02-visao`) |
| `/02-visao` | Visão de longo prazo do ecossistema e de cada produto individualmente | Roadmap de sprint (fica no repositório do produto) |
| `/03-arquitetura-de-negocio` | Como o negócio dos clientes (vendedores de marketplace/e-commerce) é estruturado — cadeia de valor, papéis, processos — independente de qualquer produto Borges | Definição de KPI ou regra (isso é `/10-kpis` e `/07-regras`) |
| `/04-perguntas-de-negocio` | Catálogo de perguntas que os produtos precisam responder (ex.: "Como estão minhas vendas?") | A resposta em si — só a pergunta e o que ela referencia |
| `/05-conhecimento` | Biblioteca de conceitos, definições e frameworks por domínio — o "dicionário e manual" do setor | Regra de inferência executável (isso é `/07-regras`) |
| `/06-playbooks` | Sequências de ação recomendadas — genéricas e adaptadas por cliente | Regra de disparo automático (referenciada, não duplicada, de `/07-regras`) |
| `/07-regras` | Fonte de verdade das regras de inferência (o "Rule Engine" em forma de documento) | Recomendação de ação (isso é `/08-recomendacoes`, referenciada) |
| `/08-recomendacoes` | Catálogo de recomendações associadas a regras — o que sugerir quando uma regra dispara | A regra em si (só referência) |
| `/09-prompts` | Prompts estruturados por caso de uso, para uso futuro por IA Borges e por qualquer produto que precise de leitura textual automática | Modelo de IA ou implementação técnica |
| `/10-kpis` | Definição formal de cada indicador: fórmula, unidade, polaridade, domínio | Meta customizada de cliente (isso é `/12-clientes`) |
| `/11-aprendizado` | Histórico vivo: decisões tomadas e por quê, retrospectivas, casos reais, erros documentados | Registro de tarefa do dia a dia (isso é gestão de projeto, não patrimônio) |
| `/12-clientes` | Perfil e contexto de cada cliente, e um índice do que existe sobre ele espalhado pelo resto do repositório | Cópia de playbook/KPI (só referência ao original) |
| `/13-produtos` | Para cada produto do ecossistema: o que ele consome do Borges Core e qual sua fronteira de escopo | Documentação técnica/build spec do produto (fica no repositório do produto) |
| `/14-templates` | Um molde por tipo de documento existente no repositório | Conteúdo preenchido |
| `/15-estudos` | Pesquisas, benchmarks e análises externas, datadas — a camada "em observação" antes de virar conhecimento consolidado | Verdade já estável (isso graduou para `/05-conhecimento`) |
| `/_meta` | Índice mestre, tabela de códigos, mapa de níveis | Conteúdo de negócio |

---

## 2. Convenções de nomenclatura

### 2.1 Prefixos por tipo de documento

| Tipo de conteúdo | Prefixo | Exemplo |
|---|---|---|
| Manifesto | `MAN` | `MAN_001_Proposito_Borges_Performance.md` |
| Visão | `VIS` | `VIS_CI_001_Visao_Centro_Inteligencia.md` |
| Arquitetura de negócio | `BA` | `BA_003_Modelo_Operacional_Marketplace.md` |
| Pergunta de negócio | `BQ` | `BQ_001_Como_estao_minhas_vendas.md` |
| Conhecimento (Knowledge Library) | `BPK` | `BPK_001_Mercado_Livre.md` |
| Playbook genérico | `PB` | `PB_Expedicao_Base.md` |
| Playbook de cliente | `PB_{CLIENTE}` | `PB_BLWBK_Expedicao.md` |
| Regra (Rule Engine) | `RULE` | `RULE_Queda_Conversao.md` |
| Recomendação | `REC` | `REC_Queda_Conversao.md` |
| Prompt | `PROMPT` | `PROMPT_Leitura_Executiva.md` |
| KPI | `KPI` | `KPI_Pedidos_Expedidos.md` |
| Decisão registrada | `LRN_DECISION` | `LRN_DECISION_003_Metrica_Generica.md` |
| Caso real | `LRN_CASO` | `LRN_CASO_BLWBK_Ruptura_2026Q2.md` |
| Estudo | `STUDY` | `STUDY_Algoritmo_ML_2026.md` |
| Template | `TPL` | `TPL_Playbook.md` |
| Perfil de cliente | `CLI` | `CLI_BLWBK_Perfil.md` |

### 2.2 Códigos de escopo

Usados como componente do nome de arquivo quando o documento é específico de um cliente, produto ou domínio.

- **Cliente:** `BLWBK` (Blowback), `HGZ` (HGZ) — lista viva em `/_meta/CODIGOS.md`
- **Produto:** `CI` (Centro de Inteligência), `WMS` (Maestro WMS), `IA` (IA Borges), `APP` (App Mobile), `API` (APIs Borges)
- **Domínio:** `COM` (comercial), `EST` (estoque), `LOG` (logística), `OPS` (operações), `ADM` (administrativo), `MKT` (marketplace/e-commerce geral), `CONS` (consultoria)

### 2.3 Regra de montagem do nome

```
PREFIXO[_CODIGO-DE-ESCOPO]_NUMERO_Slug_Em_Title_Case.md
```

- Numeração sequencial de 3 dígitos, única por prefixo (ex.: todo `BQ_xxx` compartilha a mesma sequência, independente de domínio)
- Slug sem acento, palavras separadas por `_`, cada palavra capitalizada
- Código de escopo (cliente/produto/domínio) é opcional e só aparece quando o documento é específico daquele escopo — um documento de conhecimento geral não carrega código de cliente
- Nenhum arquivo excede ~60 caracteres de nome

### 2.4 Metadados no cabeçalho de cada documento (front-matter)

Toda a rastreabilidade entre pastas — o que evita duplicação — é feita por metadado, não por cópia de conteúdo. Todo documento do repositório carrega um cabeçalho estruturado com:

- `id`: o próprio nome do arquivo, sem extensão
- `tipo`: um dos prefixos da seção 2.1
- `nivel`: um ou mais níveis da seção 3
- `dominio`: um ou mais domínios da seção 2.2
- `produtos`: quais produtos consomem esse conhecimento (pode ser mais de um)
- `clientes`: quais clientes esse documento se aplica, quando fizer sentido
- `status`: rascunho / ativo / obsoleto
- `relacionados`: lista de `id`s de outros documentos referenciados (ex.: um `RULE` aponta para o `KPI` que ele observa e para o `REC` que ele aciona)
- `criado_em` / `atualizado_em`

Esse cabeçalho é o que permite, no futuro, transformar o repositório em banco de dados ou base de um motor de inferência sem precisar reestruturar pasta nenhuma — a pasta é a visão humana de navegação, o metadado é o esquema de dado.

---

## 3. Níveis

Nível não é uma pasta física — é uma lente aplicada sobre a estrutura da seção 1, declarada no metadado `nivel` de cada documento. Isso evita ter que escolher entre "organizar por tipo" ou "organizar por nível": um mesmo documento pode ser navegado das duas formas.

| Nível | O que reúne | Pastas físicas principais |
|---|---|---|
| Estratégico | Propósito, princípios, visão de longo prazo, estrutura do negócio dos clientes | `/01-manifesto`, `/02-visao`, `/03-arquitetura-de-negocio` |
| Produto | Fronteira e consumo de conhecimento de cada produto do ecossistema | `/13-produtos`, subpasta `/produtos` de `/02-visao` |
| Conhecimento | O núcleo reutilizável: conceitos, perguntas, playbooks genéricos, KPIs, glossário | `/04-perguntas-de-negocio`, `/05-conhecimento`, `/06-playbooks/genericos`, `/10-kpis` |
| Cliente | O que é específico de Blowback, HGZ e futuros clientes | `/12-clientes`, `/06-playbooks/clientes` |
| Técnico | Conhecimento já traduzido para uma forma quase executável — o que vira motor de regras e recomendação | `/07-regras`, `/08-recomendacoes` |
| IA | Conhecimento preparado para consumo por modelos de linguagem | `/09-prompts` |
| Templates | Moldes de criação de qualquer novo documento | `/14-templates` |
| Estudos | Pesquisa datada, ainda não consolidada como verdade estável | `/15-estudos` |

Duas pastas são transversais — não pertencem a um nível único porque falam sobre o repositório e sobre o tempo, não sobre um recorte de conteúdo:

- `/00-governanca` — sobre a estrutura do repositório em si
- `/11-aprendizado` — sobre a evolução do conhecimento ao longo do tempo, cruzando todos os níveis acima (uma decisão registrada pode ser estratégica, técnica ou de cliente, dependendo do caso)

---

## 4. Ciclo de vida entre pastas (o que evita duplicação de fato)

A estrutura só cumpre a promessa de "nunca duplicar conhecimento" porque existem três mecanismos explícitos, não apenas boa vontade:

1. **Genérico primeiro, cliente depois, por referência.** Um playbook nasce em `/06-playbooks/genericos`. Quando um cliente precisa de uma versão adaptada, o documento em `/06-playbooks/clientes/{CLIENTE}` referencia o genérico no metadado `relacionados` e descreve só a diferença — nunca copia o conteúdo inteiro. Se o Vitor da Blowback ensina algo que vale para qualquer cliente, a atualização sobe para o genérico, e todo cliente herda.
2. **Estudo vira conhecimento, não o contrário.** Uma descoberta nova entra em `/15-estudos` (datada, sujeita a ficar velha). Só quando se prova estável e reaplicável, ela "gradua" para `/05-conhecimento` — a biblioteca principal nunca fica poluída de achado temporário, e a distinção entre "sabemos" e "estamos observando" fica explícita.
3. **Produto consome, não redefine.** Cada produto tem um único documento de fronteira em `/13-produtos/{CODIGO}/CONSUMO.md`, listando quais KPIs, regras, playbooks e domínios de conhecimento ele usa — por referência de `id`, nunca por cópia. Quando o Maestro WMS precisar do conceito de ruptura de SKU, ele aponta para o mesmo `KPI_Ruptura_SKUs.md` e `RULE_Queda_Estoque.md` que o Centro de Inteligência já usa, em vez de reescrever a definição.

---

## 5. Por que essa estrutura sustenta o crescimento sem duplicar conhecimento

O risco natural de um ecossistema com vários produtos (Centro de Inteligência, Maestro WMS, IA Borges, App, APIs) é cada um desenvolver sua própria versão do que é "ruptura de estoque", sua própria régua de "queda de conversão", seu próprio texto de manifesto — e essas versões divergirem silenciosamente ao longo dos anos. Essa arquitetura previne isso de três formas concretas:

Primeiro, porque a organização é por **tipo de conhecimento**, não por produto ou por cliente. Um KPI, uma regra ou um playbook têm exatamente um endereço físico no repositório, independente de quantos produtos ou clientes o usam — quem precisa dele aponta para lá, ninguém copia. Isso é o oposto de uma wiki solta por produto, onde a mesma definição acaba escrita três vezes de três jeitos levemente diferentes.

Segundo, porque o **metadado** (produtos, clientes, domínio, nível) carrega a informação de "quem usa o quê" sem exigir que o conteúdo exista em mais de um lugar. Isso é também o que prepara o repositório para virar banco de dados e motor de inferência no futuro, como o projeto já prevê — a migração não vai exigir reorganizar nada, só importar o que já está estruturado.

Terceiro, porque existe uma fronteira clara entre **conhecimento de negócio** (Borges Core) e **implementação de produto** (repositório de cada produto). O Centro de Inteligência de hoje já define um catálogo de métricas (`Metric`) e um motor de regras próprio (Sprint 4, a caminho) — a intenção desta arquitetura é que, à medida que o Maestro WMS e a IA Borges nascerem, eles leiam a mesma fonte de verdade de negócio (`/10-kpis`, `/07-regras`, `/05-conhecimento`) e apenas implementem sua própria camada técnica em cima dela, em vez de recriar o entendimento do negócio do zero. Consultoria, produto e IA passam a compartilhar um único cérebro — só a forma de acessá-lo muda.

Por fim, o modelo genérico → cliente → aprendizado (seção 4) é o que faz o patrimônio **crescer com o tempo em vez de só acumular**: cada cliente novo não começa do zero, e cada lição aprendida com um cliente eleva o padrão para todos os próximos — que é, no fundo, o próprio motivo de existir de uma consultoria que virou produto.
