# Relatório — Centro de Qualidade: conexão da planilha real de Reclamações

**Data:** 17/07/2026
**Projeto:** Centro de Inteligência — Borges Performance
**Módulo:** Centro de Qualidade (`/[empresa]/qualidade`)
**Commit em produção:** `18a5d6a` (Vercel, build concluído às 15:33)

## Contexto

A Sprint 6 já tinha construído a fundação do Centro de Qualidade: uma tela nova, independente de Operações e Integrações, capaz de conectar uma planilha do Google Sheets e listar casos importados (Loja, Marketplace, Produto, Data, Responsável, Status, Problema e Link do chamado). Na época, esses campos foram desenhados sem dado real — a planilha de Reclamações ainda não tinha sido conectada de verdade.

Quando você tentou conectar a planilha real (`Reclamação 3ºTrimestre 2026`), a importação falhou porque o cabeçalho real não batia com o que a Sprint 6 tinha assumido: não existe coluna Loja, e existem duas colunas de Status e duas de Responsável, não uma. Você pausou a conexão e disse que ia trazer o material do Notion com os procedimentos reais antes de eu mexer em mais nada. Esta etapa começou com você enviando três PDFs exportados do Notion (Atendimento Pós-Venda, Atendimento Pré-Venda e Operacional: Recebimento de devoluções) e pedindo para eu entender o processo antes de continuar.

## O que os documentos revelaram

O PDF "Operacional: Recebimento de devoluções" documenta exatamente a planilha que você tentou conectar — mesmo link, mesma aba, período "3º Trimestre 2026 (15/07 a 30/09)", ou seja, um procedimento atualizado, não desatualizado como você temia. Ele resolveu as duas dúvidas que tinham ficado em aberto.

A primeira é que Status (E-Commerce) e Status (Expedição) não são a mesma informação duplicada — são dois processos reais, cada um conduzido por uma equipe diferente. O Atendimento E-Commerce usa valores como "Em andamento", "Tratativa por Ticket", "Aguardando devolução", "Iniciar Lote G" e "Verificar ajuste em carteira". A Equipe de Entrada, Garantias e Inventário usa outro vocabulário, referente ao que acontece depois que o produto chega fisicamente: "Voltando ao estoque", "Vender como recondicionado — Caixa danificada", "Vender como recondicionado — Produto danificado", "Iniciar Lote G" e "Lote G iniciado". O mesmo vale para Responsável: são duas pessoas diferentes, uma por lado. Juntar os dois num campo só, como a Sprint 6 tinha feito, perderia informação real do processo.

A segunda dúvida era sobre "Lote G" — no seu primeiro pedido, você tinha descrito "lote G e iniciar lote G" como se fossem abas da planilha. Confirmei diretamente na planilha (tentando abrir uma aba chamada "Garantias" e outra "Lote G" via link público) que nenhuma das duas existe — a planilha tem uma única aba. "Lote G" e "Iniciar Lote G" são valores dentro da própria coluna de Status, não abas separadas.

O documento também esclareceu o campo "Detalhes da Reclamação": além da descrição inicial do problema, o procedimento manda registrar todo o histórico do caso como comentário na célula (atualizações, retornos do marketplace, contato com o cliente, etc.). Isso é uma limitação que vale registrar: comentário de célula do Google Sheets não é exportado pelo link público que o sistema usa para ler a planilha — só o texto que estiver escrito diretamente na célula é capturado. O histórico via comentário não entra automaticamente.

## O que foi implementado

Com as duas dúvidas resolvidas e sua confirmação ("deixe tudo conforme está sendo preenchido" para Status/Responsável, e "toda a fonte é Blowback" para Loja), fiz as seguintes mudanças:

- O campo único `status` do caso virou dois campos: `statusEcommerce` e `statusExpedicao`. O campo único `responsavel` virou `responsavelEcommerce` e `responsavelExpedicao`. Os quatro continuam texto livre, exatamente como vêm da planilha — nenhum fluxo fechado (PENDENTE → RESOLVIDO, por exemplo) foi criado, seguindo a mesma decisão da Sprint 6 de não presumir workflow antes da hora.
- Foi adicionado o campo `detalhes`, opcional, para guardar o texto da coluna "Detalhes da Reclamação" (com a limitação de comentários de célula explicada acima).
- A coluna Loja deixou de ser obrigatória no cabeçalho da planilha. Quando ela não existe — como no caso da planilha de Reclamações da Blowback — o sistema usa um valor padrão configurado na própria fonte de dados. Por isso o formulário de "Conectar planilha" ganhou um campo novo, opcional, chamado "Loja padrão": ao reconectar a planilha de Reclamações, esse campo deve ser preenchido com "Blowback".
- O reconhecimento de colunas foi ajustado para os nomes reais da planilha: "Status do pedido E-Commerce", "Status do pedido Expedição", "Responsável E-Commerce", "Responsável da Expedição", "Detalhes da reclamação", "Data inicial" e "Problema informado pelo cliente" agora são reconhecidos diretamente, sem precisar renomear nada na planilha.
- A tela de casos e o filtro de Status foram atualizados: a lista agora mostra as duas colunas de Responsável e as duas de Status lado a lado, e o filtro de Status (ainda um único campo na tela, como pedido desde a Sprint 6) passou a buscar em qualquer um dos dois lados.
- A regra de reimportação sem duplicar (chave por link do chamado, ou combinação de campos quando não há link) continua a mesma — ela já estava alinhada com a regra da planilha de nunca alterar o Link do Chamado depois de cadastrado.

Essas mudanças exigiram uma migration no banco de dados, que você rodou (`npx prisma migrate dev` + `npx prisma generate`) antes do deploy. O build no Vercel concluiu sem erros, TypeScript passou limpo, e o commit `18a5d6a` já está em produção.

## Escopo por empresa

Você confirmou nesta etapa que esse controle de Reclamações e Devoluções — a planilha inteira — é hoje só da Blowback; a HGZ não tem esse tipo de controle. Isso já está refletido no desenho: cada fonte de dados pertence a uma única empresa, então a planilha da Blowback nunca vai gerar casos para a HGZ. Você também observou que as atividades logísticas (entradas, conferências, garantias, Full) valem para as duas empresas — isso já é coberto pelo módulo de Operações, que é um módulo separado do Centro de Qualidade, então não havia nada a ajustar por causa disso.

## O que falta

A planilha de Reclamações ainda precisa ser reconectada na tela do Centro de Qualidade, agora preenchendo "Loja padrão: Blowback" no formulário — sem isso a importação continua barrando a mesma mensagem de antes. A aba "Garantias" (para onde os casos são transferidos via a coluna "Check de Transferência") ainda não foi vista; o Centro de Qualidade continua sem nenhum KPI, gráfico ou fluxo de status fechado, por decisão deliberada da Sprint 6 — isso só entra depois de haver algumas semanas de dado real importado.
