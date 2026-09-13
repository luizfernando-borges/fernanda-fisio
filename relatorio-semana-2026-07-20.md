# Relatório da semana — Centro de Inteligência Borges

Período: 13/07 a 20/07/2026

## O que aconteceu

**13/07** — Fundação do projeto: primeiro commit, scaffold Next.js + Prisma + Auth.js, modelo de dados inicial.

**14/07** — Correções de build (Next 16, tipagem do Prisma), primeira migration do banco, leitura de Google Sheets via link público (sem precisar de conta de serviço), usuário de teste com acesso a Blowback e HGZ, catálogo dinâmico de atividades operacionais.

**15/07** — Sprint 5.2 (estabilização da Visão Operacional) e Sprint 6 (Centro de Qualidade V1) no ar.

**17/07** — Ajuste do Centro de Qualidade com base nos procedimentos reais da Blowback (PDFs exportados do Notion: Pós-Venda, Pré-Venda, Recebimento de devoluções). Status e Responsável foram separados em E-commerce/Expedição (são times e vocabulários diferentes), campo Detalhes adicionado, Loja tornou-se opcional. Deploy confirmado por você via log da Vercel.

**19/07** — Entrega da Fase 1 da Visão Geral da Operação: uma tela única (`/visao-geral`) que consolida Blowback + HGZ sem depender de filtro — KPIs, gráficos, rankings, resumo automático e comparativo Hoje/Semana/Mês. Sem migration nova no banco. Código commitado e enviado ao GitHub.

## Pendência em aberto

O deploy desse último commit (Visão Geral) apareceu como **"BLOCKED"** no painel da Vercel — diferente de todos os deploys anteriores da semana, que ficaram "READY" normalmente. Eu perdi o acesso às ferramentas de consulta da Vercel antes de confirmar a causa exata.

Hipótese mais provável, **não confirmada**: o commit foi registrado com o e-mail lf.borges.lima@gmail.com, que o GitHub/Vercel pode ter associado a uma conta diferente (aparece como "BorgesLuiz") da que normalmente autoriza deploys neste projeto (luizfernando-borges / luizfernando.dublin@gmail.com). A Vercel tem uma proteção que bloqueia deploy de produção quando o autor do commit não é um membro autorizado do time — é o tipo de bloqueio mais compatível com o que vi antes de perder acesso.

## Conclusão

**Último movimento: meu.** Codei, commitei e enviei a Fase 1 da Visão Geral para o GitHub, e comecei a investigar por que o deploy ficou bloqueado na Vercel.

**Próximo movimento: seu.** Preciso que você abra o painel da Vercel (projeto `central-inteligencia-bp`) e veja o deploy mais recente (commit `2019e9e`). Se aparecer um pedido de aprovação/autorização do autor do commit, é só aprovar por lá.

**Próximos passos:**
1. Você libera (ou verifica) o deploy bloqueado na Vercel — ou me diz o que aparece lá, que eu ajudo a diagnosticar.
2. Depois de liberado, testar a tela `/visao-geral` no ar com os dois logins (Blowback e HGZ).
3. Fase 2 (fora do escopo desta entrega, só quando você der sinal): estruturar Canal/Fornecedor/NF-e nas atividades operacionais e desenhar o modelo de Recebimento individual.
