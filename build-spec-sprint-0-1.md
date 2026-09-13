# Borges Performance — Centro de Inteligência
## Especificação de Build — Sprint 0 e Sprint 1

Backlog pronto para execução. Sem código — apenas o que construir, em que ordem, e como saber que está pronto. Cada tarefa deve ser lida junto do princípio central do produto: a interface fala a língua do empresário (como está a empresa / o que aconteceu / por que / onde agir), mesmo que o banco por trás seja genérico.

---

## SPRINT 0 — Fundação técnica

**Objetivo da sprint:** infraestrutura de pé, banco completo criado, autenticação funcionando ponta a ponta. Nenhuma tela de produto (Dashboard, Integrações, Plano de Ação) é construída aqui — isso é Sprint 1 em diante.

### 0.1 Tarefas exatas, em ordem

1. Criar repositório Git e projeto Next.js (App Router, TypeScript, sem `src/` extra — manter raiz limpa)
2. Configurar ESLint + Prettier com regras padrão do Next.js — sem customização elaborada
3. Provisionar banco Postgres gerenciado (Neon ou Supabase), ambiente único de desenvolvimento
4. Instalar Prisma, conectar ao banco via `DATABASE_URL`
5. Modelar o schema completo (as 10 entidades da seção 0.3) e rodar a primeira migration
6. Configurar Auth.js com provider de magic link (email), usando um serviço de envio (Resend ou equivalente)
7. Criar `.env.example` com todas as variáveis necessárias documentadas (seção 0.4)
8. Criar a estrutura de pastas do projeto (seção 0.2)
9. Criar layout raiz (tipografia, cores da marca Borges Performance, favicon) — reaproveitar identidade visual já usada no site institucional da Borges
10. Criar uma página protegida mínima de teste (ex.: `/app-teste`, descartável) só para provar que sessão + middleware funcionam — será substituída pela estrutura real na Sprint 1
11. Conectar o repositório à Vercel, configurar variáveis de ambiente lá, validar deploy de preview
12. Escrever script de seed: cria `Company` Blowback e HGZ, cria usuários de teste, cria `UserCompanyRole` ligando cada um
13. Rodar o seed no banco de desenvolvimento e validar manualmente os dados
14. Testar o fluxo de login ponta a ponta em produção/preview (não só local)

### 0.2 Estrutura de pastas esperada ao fim da Sprint 0

```
/app
  /(auth)
    /login/page.tsx
  /api
    /auth/[...nextauth]/route.ts
  layout.tsx          → layout raiz (tipografia, cores, favicon)
  page.tsx             → raiz: redireciona para /login ou área autenticada conforme sessão

/lib
  /db/client.ts        → instância única do Prisma Client
  /auth/config.ts       → configuração do Auth.js (provider de magic link)

/prisma
  schema.prisma
  /seed.ts
  /migrations

/config
  site.ts               → nome do produto, cores da marca, textos fixos

/types
  index.ts               → tipos compartilhados

.env.example
```

Pastas de `/components`, `/lib/services`, `/lib/integrations` e a estrutura `/[empresa]/...` **não** são criadas ainda — entram na Sprint 1 e seguintes, quando têm o que conter.

### 0.3 Schema inicial do banco (todas as 10 entidades)

Todas as tabelas são criadas nessa sprint, mesmo as que só passam a ser usadas depois — isso evita migration disruptiva mais tarde. Só `Company`, `User` e `UserCompanyRole` recebem dado real (via seed) na Sprint 0.

| Entidade | Campos principais | Observação |
|---|---|---|
| `Company` | id, nome, slug (único), createdAt | slug vira o segmento `/[empresa]` da URL |
| `User` | id, nome, email (único), createdAt | sem senha — autenticação é por magic link |
| `UserCompanyRole` | id, userId, companyId, papel (`borges_admin`\|`cliente_admin`\|`cliente_membro`), createdAt | par único (userId, companyId) |
| `DataSource` | id, companyId, tipo (`google_sheets`\|`csv`), config, status, últimaImportação | vazia até a sprint de Integrações |
| `ImportBatch` | id, dataSourceId, companyId, iniciadoEm, finalizadoEm, status, linhasOk, linhasComErro, log | vazia até a sprint de Integrações |
| `Metric` | id, chave, nome, unidade, agregação, configLimiar | vazia até a sprint de Dashboard/Insights |
| `MetricSnapshot` | id, companyId, metricId, data, dimensão, valor, importBatchId | vazia até a sprint de Integrações |
| `Insight` | id, companyId, metricId, ruleKey, título, descrição, severidade, período, status | vazia até a sprint de Insights |
| `Alert` | id, companyId, metricId, insightId, título, mensagem, nível, status, disparadoEm, actionItemId | vazia até a sprint de Insights |
| `ActionItem` | id, companyId, título, descrição, prioridade, status, responsável, prazo, originAlertId, createdAt | vazia até a sprint de Plano de Ação |

Todas as tabelas com `companyId` têm índice nessa coluna desde a criação — é a base do isolamento multiempresa que vem na Sprint 1.

### 0.4 Variáveis de ambiente

| Variável | Função |
|---|---|
| `DATABASE_URL` | conexão com o Postgres |
| `AUTH_URL` | URL base para o Auth.js |
| `AUTH_SECRET` | segredo de assinatura de sessão |
| `EMAIL_SERVER` ou `RESEND_API_KEY` | envio do magic link |
| `EMAIL_FROM` | remetente do magic link (ex.: `contato@borgesperformance.com.br`) |
| `NODE_ENV` | padrão do Next.js |

Não incluir ainda: credenciais de Google Sheets, Bling, ou qualquer serviço de billing — essas variáveis só entram quando a funcionalidade correspondente for implementada. Variável ausente deve quebrar o boot do projeto com erro claro, não falhar silenciosamente em runtime.

### 0.5 Autenticação

- Auth.js, provider de magic link por email, sessão JWT
- Página `/login`: campo de email, envia link, mensagem de confirmação
- Middleware protege qualquer rota fora de `/login` e `/api/auth/*`, redirecionando para `/login` se não houver sessão
- Critério de prova: usuário loga, sessão persiste entre reloads, expira conforme configurado

### 0.6 Critérios de aceite da Sprint 0

- Projeto sobe local e em preview Vercel sem erro
- Login por magic link funciona ponta a ponta em ambiente publicado (não só localhost)
- As 10 tabelas existem no banco, migrations aplicadas sem erro
- Seed roda de forma idempotente (pode rodar de novo sem duplicar ou quebrar) e popula Blowback, HGZ e os usuários de teste corretamente
- `.env.example` completo; subir o projeto sem as variáveis falha com mensagem clara
- Nenhuma tela de produto (Dashboard, Integrações, Plano de Ação, sidebar) foi construída — isso fica explicitamente fora do escopo aceito nesta sprint

---

## SPRINT 1 — Área do Cliente e Multiempresa simples

**Objetivo da sprint:** a casca de navegação real do produto — login leva à empresa certa, sidebar mostra os módulos (3 ativos, 5 "em breve"), troca de empresa funciona, acesso é protegido por empresa. Nenhuma lógica de negócio (métricas, insights, importação) entra aqui — os 3 módulos "ativos" recebem apenas o esqueleto visual correto, não o conteúdo.

### 1.1 Fluxo de login → empresa

1. Usuário loga (fluxo da Sprint 0)
2. Sistema consulta `UserCompanyRole` do usuário
3. Uma empresa só → redireciona direto para `/[empresa]/dashboard`
4. Mais de uma empresa → mostra `/select-empresa`
5. `borges_admin` sempre vê todas as empresas em `/select-empresa`, independente de quantas são

### 1.2 Seleção de empresa (`/select-empresa`)

- Lista as empresas do usuário como cards simples (nome, e logo se houver)
- Clicar leva a `/[empresa]/dashboard`
- Tela só existe para quem tem mais de uma empresa — não é vista pelo cliente comum de uma empresa só

### 1.3 Proteção por empresa

- Todo acesso a `/[empresa]/*` verifica se existe `UserCompanyRole` do usuário logado para aquele slug de empresa
- Sem vínculo → bloqueio (redirect para `/select-empresa` ou página de acesso negado, não 500)
- `borges_admin` tem acesso a qualquer empresa, mesmo sem `UserCompanyRole` explícito para ela (ou com um vínculo automático — decisão de implementação, mas o comportamento observável é: borges_admin nunca é bloqueado)
- Essa verificação é a única "trava" de segurança multiempresa da V1 — não há isolamento a nível de banco (RLS) ainda, é responsabilidade da camada de aplicação

### 1.4 Sidebar

- Fixa, presente em toda rota `/[empresa]/*`
- Topo: logo Borges Performance + nome/seletor da empresa ativa
- Itens ativos (clicáveis, com conteúdo real por trás, mesmo que mínimo nesta sprint): **Dashboard**, **Plano de Ação**, **Integrações**
- Itens "em breve" (clicáveis, levam a um placeholder): Comercial, Estoque, Logística, Projetos, Reuniões
- Item ativo da navegação atual fica destacado visualmente

### 1.5 CompanySwitcher

- Dropdown no topo da sidebar, lista as empresas do usuário
- Trocar seleção navega para `/[nova-empresa]/dashboard`
- Se o usuário tem só uma empresa, o componente fica oculto ou desabilitado — não mostra um dropdown vazio de opção única

### 1.6 Rotas `/[empresa]/...`

```
/app/(client)/[empresa]/layout.tsx        → valida acesso à empresa, monta sidebar + CompanySwitcher
/app/(client)/[empresa]/dashboard/page.tsx       → esqueleto visual: 3 blocos vazios (o que aconteceu / por que / onde agir)
/app/(client)/[empresa]/plano-de-acao/page.tsx    → esqueleto: lista vazia com estado "nenhuma ação ainda"
/app/(client)/[empresa]/integracoes/page.tsx      → esqueleto: estado "nenhuma fonte conectada ainda"
/app/(client)/[empresa]/comercial/page.tsx        → EmptyModulePlaceholder
/app/(client)/[empresa]/estoque/page.tsx          → EmptyModulePlaceholder
/app/(client)/[empresa]/logistica/page.tsx        → EmptyModulePlaceholder
/app/(client)/[empresa]/projetos/page.tsx         → EmptyModulePlaceholder
/app/(client)/[empresa]/reunioes/page.tsx         → EmptyModulePlaceholder
```

Diferença importante entre os dois tipos de página vazia:
- **Dashboard / Plano de Ação / Integrações:** o esqueleto já usa a estrutura visual final (onde os KPIs, a lista de ações ou a lista de fontes vão aparecer), só que com estado vazio — porque essas telas ganham conteúdo real nas próximas sprints, sobre a mesma estrutura.
- **Comercial / Estoque / Logística / Projetos / Reuniões:** usam o componente genérico `EmptyModulePlaceholder` (nome do módulo + frase curta do que vai entregar) — porque ainda não têm data model nem estrutura definida.

### 1.7 Critérios de aceite da Sprint 1

- Usuário com 2 empresas (ex.: um `borges_admin`) vê `/select-empresa` e navega corretamente para qualquer uma
- Usuário com 1 empresa só (ex.: `cliente_admin` da Blowback) pula direto para `/blowback/dashboard`
- Acessar a URL de uma empresa à qual o usuário não tem vínculo é bloqueado, exceto para `borges_admin`
- Sidebar exibe os 3 módulos ativos e os 5 "em breve", todos navegáveis
- CompanySwitcher troca de empresa corretamente e a URL reflete a empresa ativa
- As 8 rotas de módulo existem e renderizam sem erro (3 com esqueleto estrutural, 5 com placeholder genérico)
- Nenhuma métrica, insight, alerta ou importação real aparece em nenhuma tela — são todos estados vazios

---

## 3. Riscos de implementação

- **Antecipar lógica de negócio:** a pasta `/[empresa]/dashboard` já existir pode tentar o dev a começar a puxar dado real. O critério de aceite da Sprint 1 é explícito para conter isso: só esqueleto.
- **Falha silenciosa na proteção por empresa:** um bug no middleware pode tanto vazar dado entre empresas quanto bloquear indevidamente o `borges_admin`. Testar os dois cenários de forma explícita antes de fechar a sprint, não só o caminho feliz.
- **Entrega de email do magic link:** funciona em teste local e falha em produção por configuração de domínio (SPF/DKIM) mal feita no provedor de email. Validar entrega em ambiente publicado, não só localhost, ainda na Sprint 0.
- **Slug de empresa mal definido:** se o slug for editável livremente depois, links quebram e há risco de colisão. Definir slug uma vez, na criação, e não expor edição de slug na V1.
- **Seed desalinhado com o schema:** conforme o schema evoluir nas próximas sprints, o seed pode quebrar. Manter o script de seed simples e idempotente, e rodá-lo a cada sprint como parte do critério de aceite.

## 4. O que NÃO fazer nessa etapa

- Não criar billing ou planos
- Não criar subdomínio por cliente — a empresa é sempre um segmento de URL (`/[empresa]`) dentro do mesmo domínio
- Não integrar Bling
- Não implementar Google Sheets ou CSV/XLSX ainda — a tela de Integrações existe vazia, sem conexão real
- Não implementar o motor de regras de insight nem gerar `Insight`/`Alert` — essas tabelas existem no schema, mas ficam vazias
- Não implementar CRUD funcional de `ActionItem` — a tela de Plano de Ação existe vazia
- Não construir Comercial, Estoque, Logística, Projetos ou Reuniões além do placeholder genérico
- Não criar microserviços, fila de mensagens ou worker separado
- Não montar pipeline de CI/CD elaborado ou múltiplos ambientes de staging — um ambiente de desenvolvimento + preview da Vercel é suficiente agora
- Não adicionar login social ou SSO
- Não implementar Row Level Security no Postgres — o isolamento por empresa nesta fase é só na camada de aplicação

## 5. Checklist final antes de codar

- [ ] Projeto e conta Vercel criados, vinculados ao repositório
- [ ] Banco Postgres (Neon ou Supabase) provisionado, string de conexão em mãos
- [ ] Provedor de envio de email (Resend ou equivalente) escolhido, chave de API disponível, domínio de envio configurado
- [ ] Repositório criado, com README apontando para os documentos de arquitetura, especificação funcional e este documento de build
- [ ] Nome oficial e slug desejado de Blowback e HGZ confirmados com o Vitor
- [ ] Emails reais dos usuários de teste (`borges_admin`, `cliente_admin` de cada empresa) definidos
- [ ] Cores, tipografia e logo da Borges Performance disponíveis para o layout raiz
- [ ] Este documento revisado e aprovado como backlog de Sprint 0 e Sprint 1
