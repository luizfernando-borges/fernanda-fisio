# Borges Performance — Área do Cliente / Centro de Inteligência
## Arquitetura Técnica e Plano de Execução — MVP V1

**Escopo:** validação com Blowback e HGZ. Sem billing, sem multi-tenant complexo, sem IA avançada, sem marketplace de apps, sem subdomínio por cliente. Cada decisão abaixo prioriza o menor sistema que resolve a dor real do Vitor: *"Como está minha empresa hoje e onde devo agir?"*

---

## 1. Arquitetura técnica inicial

**Monolito modular**, não microserviços. Um único projeto Next.js cobre frontend e backend (API Routes / Server Actions). Isso é intencional: com 2 clientes e uma equipe pequena, separar serviços só criaria overhead de deploy e debug sem nenhum ganho real.

- **Frontend + Backend:** Next.js (App Router), TypeScript
- **Banco:** PostgreSQL gerenciado (Neon ou Supabase — sem servidor próprio para administrar)
- **ORM:** Prisma
- **Autenticação:** Auth.js (NextAuth)
- **Importação de dados:** pipeline própria (upload CSV/XLSX + leitura de Google Sheets via Service Account), rodando dentro do próprio Next.js — sem fila de mensagens, sem worker separado
- **Agendamento:** Vercel Cron para importações periódicas (1x/dia é suficiente no MVP)
- **Deploy:** Vercel (app) + banco gerenciado externo
- **Domínio:** `app.borgesperformance.com.br`, tenant selecionado por rota (`/[empresa]/...`), **não** por subdomínio

Camadas dentro do monolito:

```
Apresentação (app/)  →  Serviços de domínio (lib/services)  →  Acesso a dados (Prisma)  →  Integrações (lib/integrations)
```

Essa separação em camadas é o único "investimento" arquitetural feito antecipadamente — é barato agora e evita reescrever tudo quando a lógica de negócio crescer.

---

## 2. Estrutura de pastas

```
/app
  /(auth)
    /login
  /(app)
    /select-empresa
    /[empresa]
      /dashboard
      /comercial
      /operacao
      /estoque
      /logistica
      /projetos
      /plano-de-acao
      /reunioes
      /integracoes
      /configuracoes
  /api
    /auth/[...nextauth]
    /import
    /cron

/components
  /ui              → botões, cards, tabelas, inputs (base)
  /dashboard        → KpiCard, TrendChart, InsightBlock
  /layout           → Sidebar, Header, CompanySwitcher

/lib
  /db               → Prisma client
  /auth             → helpers de sessão e permissão
  /services          → regras de negócio, um arquivo por módulo (vendas, estoque, etc.)
  /integrations
    /google-sheets
    /csv
  /utils

/prisma
  schema.prisma
  /migrations

/types
/config
```

Estrutura modular por área de negócio (comercial, estoque, logística...), não por tipo técnico — isso facilita separar um módulo em serviço próprio no futuro, se necessário.

---

## 3. Entidades principais do banco

| Entidade | Função |
|---|---|
| `Company` | Empresa cliente (Blowback, HGZ) — raiz do isolamento multiempresa |
| `User` | Usuário do sistema (equipe Borges ou equipe do cliente) |
| `UserCompanyRole` | Relação N:N entre usuário e empresa, com papel (`borges_admin`, `cliente_admin`, `cliente_membro`) |
| `DataSource` | Fonte de dados configurada por empresa (planilha Google, upload CSV) |
| `ImportBatch` | Histórico de cada importação: origem, status, erros |
| `SalesDaily` | Faturamento, pedidos, ticket médio, por dia/canal |
| `SalesChannel` | Canal de venda (Mercado Livre, Shopee, Amazon, Magalu, site próprio) |
| `Product` | Cadastro de produto/SKU |
| `InventorySnapshot` | Foto de estoque por produto e data (para ruptura e curva ABC) |
| `Project` | Projetos em andamento |
| `ActionItem` | Item do plano de ação: título, prioridade, responsável, status |
| `Meeting` | Registro de reunião (data, participantes, notas) |

Todas as entidades operacionais (`SalesDaily`, `Product`, `InventorySnapshot`, `Project`, `ActionItem`, `Meeting`, `DataSource`) carregam `companyId` obrigatório desde o dia 1.

---

## 4. Modelo multiempresa simples

Multi-tenant **single database, shared schema**, isolamento por coluna `companyId` — não schema-per-tenant, não database-per-tenant. Isso seria overengineering para 2 clientes.

- Um usuário pode pertencer a mais de uma empresa (`UserCompanyRole`)
- Toda query de dado operacional passa obrigatoriamente por um filtro de `companyId`, centralizado numa camada de acesso a dados (não espalhado em cada página)
- Empresa ativa fica definida pela URL (`/[empresa]/dashboard`), não por subdomínio nem por estado global escondido
- Preparado para crescer: como `companyId` já existe em tudo desde o início, migrar para isolamento mais forte (Row Level Security do Postgres, por exemplo) no futuro não exige migração de dado — só de política de acesso

---

## 5. Fluxo de autenticação

- Auth.js com **magic link por email** (sem senha para gerenciar, mais simples e seguro para o público-alvo)
- Sessão via JWT
- Fluxo: `Login → valida sessão → se usuário tem 1 empresa, vai direto ao Centro de Inteligência → se tem mais de 1, mostra Seleção de Empresa`
- Middleware do Next.js protege todas as rotas de `/(app)/*`, verificando sessão válida **e** se o usuário tem `UserCompanyRole` para a empresa do slug acessado
- Papéis: `borges_admin` (equipe da consultoria, acesso a todas as empresas), `cliente_admin`, `cliente_membro`
- Fora de escopo no MVP: login social, SSO — desnecessário para 2 clientes e adiciona complexidade sem benefício agora

---

## 6. Importação de Google Sheets / CSV

**CSV/XLSX:**
1. Upload manual pela tela de Integrações
2. Parse no servidor (`papaparse` / `xlsx`)
3. Validação contra um template de colunas esperado por módulo (ex.: template de vendas diárias, template de estoque)
4. Upsert nas tabelas finais
5. Registro em `ImportBatch` com status e erros linha a linha

**Google Sheets:**
1. Service Account da Borges, compartilhada como leitora nas planilhas dos clientes (mais simples que OAuth por usuário)
2. `DataSource` guarda `sheetId` + range por empresa/módulo
3. Mesmo pipeline de validação e upsert do CSV
4. Execução via botão "importar agora" ou Vercel Cron 1x/dia — **não** é preciso tempo real no MVP

Padronizar templates de planilha é o que reduz a complexidade de parsing — vale mais investir tempo nisso do que em um parser genérico e tolerante a qualquer formato.

---

## 7. Páginas da V1

Todas seguem o mesmo princípio em cada tela: **o que aconteceu, por que aconteceu, o que fazer agora.**

- `/login`
- `/select-empresa`
- `/[empresa]/dashboard` — faturamento, pedidos, ticket médio, evolução diária, canais de venda
- `/[empresa]/comercial` — desempenho por canal e produto
- `/[empresa]/operacao` — atrasos operacionais
- `/[empresa]/estoque` — estoque crítico, rupturas, curva ABC
- `/[empresa]/logistica` — indicadores logísticos e atrasos
- `/[empresa]/projetos` — projetos em andamento
- `/[empresa]/plano-de-acao` — ações prioritárias, responsável, status
- `/[empresa]/reunioes` — registros de reunião
- `/[empresa]/integracoes` — configuração de fontes de dados, status de importação
- `/[empresa]/configuracoes` — usuários, papéis, dados da empresa

---

## 8. Componentes principais

- `KpiCard` — valor, variação, tendência
- `TrendChart` — evolução diária (Recharts)
- `ChannelBreakdown` — quebra por canal de venda
- `CriticalProductsTable` — produtos críticos / ruptura
- `ABCCurveChart` — curva ABC
- `ActionItemList` / `ActionItemCard` — plano de ação
- `InsightBlock` — bloco de "por que aconteceu", gerado por regras simples (não IA) no MVP
- `ImportStatusBanner` — status da última importação e erros
- `CompanySwitcher` — troca de empresa ativa
- `DataTable` — tabela genérica reutilizável

---

## 9. Roadmap técnico em sprints (semanas)

| Sprint | Entrega |
|---|---|
| 0 | Setup: Next.js, Prisma, Postgres, deploy Vercel, autenticação básica, schema inicial do banco |
| 1 | Multiempresa completo, seleção de empresa, módulo Integrações, pipeline de importação CSV |
| 2 | Dashboard Executivo (faturamento, pedidos, ticket médio, evolução diária, canais) |
| 3 | Estoque: crítico, rupturas, curva ABC |
| 4 | Comercial, Operação, Logística (atrasos) |
| 5 | Projetos, Plano de Ação, Reuniões/Registros |
| 6 | Integração Google Sheets, regras de `InsightBlock`, polish visual |
| 7 | Validação com Blowback e HGZ, ajustes, hardening (backup, logs, revisão de acesso) |

~8 semanas até MVP validável com os dois clientes.

---

## 10. Riscos técnicos

- **Qualidade de dado de planilha:** cliente pode editar estrutura sem avisar. Mitigar com templates protegidos e validação que falha de forma clara, não silenciosa.
- **Vazamento de dado entre empresas:** isolamento por coluna exige disciplina em toda query. Mitigar centralizando acesso a dados numa camada única que sempre exige `companyId` — nunca query solta em página.
- **Cota da Google Sheets API:** baixo risco no MVP (poucos clientes, poucas leituras/dia), mas deve ser monitorado se o número de fontes crescer.
- **Regra de "por que aconteceu" sem IA:** tende a virar lógica hardcoded espalhada. Mitigar mantendo as regras centralizadas em `lib/services`, um lugar só.
- **Tentação de escopo:** vontade de integrar Bling/Mercado Livre/Shopee cedo. Manter fora do MVP como definido — essas integrações têm complexidade de auth e rate limit que não vale pagar agora.
- **Histórico curto de dados:** gráficos de tendência começam pobres. Aceitável — melhora naturalmente com o tempo de uso.

---

## Princípio de crescimento

Nada aqui impede virar SaaS depois — só evita construir isso agora:

- `companyId` em tudo desde o dia 1 → não exige migração de dado para reforçar isolamento depois
- Camada de integrações com interface comum → plugar Bling/ML/Shopee no futuro sem reescrever o pipeline de importação
- Papéis de usuário já modelados → dá para acrescentar planos/billing sem redesenhar `User`/`UserCompanyRole`
- Nenhuma empresa fixa em código — tudo via tabela `Company`, então adicionar o 3º cliente é dado, não deploy
