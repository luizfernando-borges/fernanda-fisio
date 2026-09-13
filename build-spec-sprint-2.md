# Borges Performance — Centro de Inteligência
## Especificação de Build — Sprint 2

**Objetivo da sprint:** garantir que dados reais da Blowback e da HGZ entrem no banco, corretamente, de forma rastreável. Não é sobre exibir bonito — é sobre confiar no número. O Dashboard Executivo consome o resultado disso na sprint seguinte; aqui o critério de sucesso é "o dado está certo no banco", não "a tela está bonita".

Decisão que atravessa todo este documento: nenhuma das 10 métricas é calculada pelo sistema a partir de dado bruto de produto ou estoque — não existe `Product` nem `InventorySnapshot` na V1. Todas são números agregados que o próprio cliente já sabe e relata por dia (inclusive `produtos_criticos` e `ruptura_skus`, que são contagens do cliente, não uma varredura de SKU feita pelo sistema). Isso é o que mantém o modelo genérico `Metric`/`MetricSnapshot` simples nesta fase.

---

## 1. Estrutura do template Google Sheets

- Uma aba fixa por planilha, nome padrão: **`Metricas_Diarias`**
- Uma linha por dia — o cliente adiciona uma linha nova a cada dia (ou preenche várias linhas de uma vez para importar histórico)
- Linha 1 = cabeçalho fixo, com os nomes de coluna exatamente como especificado na seção 2 (validação tolera maiúsculas/minúsculas e acentos, mas a palavra precisa bater)
- Data no formato `DD/MM/AAAA`
- Valores numéricos aceitam vírgula ou ponto como separador decimal; sem separador de milhar (ex.: `12500.50`, não `12.500,50`)
- Célula vazia é permitida e significa "sem dado esse dia para essa métrica" — não é erro
- Cada empresa (Blowback, HGZ) tem sua própria planilha, sua própria `DataSource`; não há planilha compartilhada entre empresas

## 2. Colunas obrigatórias

| Coluna (cabeçalho exato) | Métrica (`Metric.chave`) | Tipo | Nível de exigência |
|---|---|---|---|
| `data` | — (não é métrica, define a linha) | data | Obrigatória — linha sem data válida é descartada |
| `faturamento` | `faturamento` | número (R$) | Obrigatória — sem ela, a importação é aceita mas o lote fica marcado como incompleto |
| `pedidos` | `pedidos` | número (inteiro) | Obrigatória, mesmo motivo de `faturamento` |
| `vendas_mercado_livre` | `vendas_mercado_livre` | número (R$) | Recomendada |
| `vendas_shopee` | `vendas_shopee` | número (R$) | Recomendada |
| `vendas_site` | `vendas_site` | número (R$) | Recomendada |
| `pedidos_atrasados` | `pedidos_atrasados` | número (inteiro) | Recomendada |
| `produtos_criticos` | `produtos_criticos` | número (inteiro) | Recomendada |
| `ruptura_skus` | `ruptura_skus` | número (inteiro) | Recomendada |
| `estoque_total` | `estoque_total` | número (R$, valor total de estoque) | Recomendada |

`ticket_medio` **não é uma coluna da planilha** — é calculado automaticamente pelo sistema (`faturamento ÷ pedidos` do mesmo dia) logo após a importação. Isso evita que o cliente calcule algo que o sistema já sabe fazer com menos risco de erro de digitação.

"Obrigatória" aqui tem um sentido específico: `data`, `faturamento` e `pedidos` são as únicas colunas que, se ausentes do cabeçalho, impedem a importação de gerar valor (um Centro de Inteligência sem faturamento e pedidos não serve pra nada). As demais são "recomendadas": a importação funciona sem elas, mas o sistema registra um aviso claro dizendo quais métricas não têm dado nessa fonte.

## 3. Exemplo de planilha

Aba `Metricas_Diarias`:

| data | faturamento | pedidos | vendas_mercado_livre | vendas_shopee | vendas_site | pedidos_atrasados | produtos_criticos | ruptura_skus | estoque_total |
|---|---|---|---|---|---|---|---|---|---|
| 28/06/2026 | 42350.00 | 187 | 25100.00 | 12800.00 | 4450.00 | 6 | 4 | 2 | 318500.00 |
| 29/06/2026 | 39820.50 | 172 | 23400.00 | 11900.00 | 4520.50 | 9 | 5 | 3 | 315200.00 |
| 30/06/2026 | 51120.00 | 210 | 30200.00 | 15600.00 | 5320.00 | 4 | 3 | 1 | 322800.00 |
| 01/07/2026 | 28900.00 | 129 | 16800.00 | 9100.00 | 3000.00 | 12 | 7 | 5 | 298400.00 |
| 02/07/2026 | | | | | | | | | |

A última linha (dia atual, ainda sem fechamento) fica vazia de propósito — mostra que célula vazia não quebra nada; ela simplesmente não gera `MetricSnapshot` até ser preenchida.

## 4. Fluxo de importação

Mesmo pipeline para Google Sheets e CSV/XLSX a partir do passo 3 — o que muda é só a origem da leitura.

1. **Cadastro da fonte** (`/integracoes`): o usuário cola o link/ID da planilha e escolhe o template `Metricas_Diarias`. O sistema tenta uma leitura de teste imediatamente — se não conseguir acessar, a fonte já nasce em estado de erro, com a mensagem exata do problema (ver seção 8)
2. **Disparo da importação**: por cron diário (planilha já configurada) ou pelo botão "Importar agora" (manual, a qualquer momento) — para CSV/XLSX, o disparo é sempre manual, no momento do upload
3. **Leitura**: sistema lê a aba `Metricas_Diarias` (Google Sheets) ou o arquivo enviado (CSV/XLSX), extrai o cabeçalho (linha 1) e as linhas de dado
4. **Validação de template** (seção 5, nível fonte): confere se o cabeçalho tem `data` e ao menos `faturamento`/`pedidos` reconhecíveis
5. **Processamento linha a linha** (seção 5, nível linha): cada linha válida gera até 9 `MetricSnapshot` (um por coluna de métrica preenchida) mais o cálculo de `ticket_medio`
6. **Cálculo de métricas derivadas**: após processar as linhas, `ticket_medio` é calculado para cada dia que teve `faturamento` e `pedidos` válidos e maior que zero
7. **Fechamento do lote**: `ImportBatch` é atualizado com o resultado final (linhas ok, linhas com erro, log detalhado)
8. **Atualização da fonte**: `DataSource.status` e `últimaImportação` refletem o resultado desse lote

Fora do escopo desta sprint: nada acontece depois do passo 8. Não há geração de `Insight`/`Alert` a partir desses dados ainda — isso é uma sprint futura, que vai ler o `MetricSnapshot` já gravado aqui.

## 5. Regras de validação

**Nível fonte (antes de processar qualquer linha):**
- Sem permissão de leitura na planilha → bloqueia, `DataSource.status = com_erro`
- Aba `Metricas_Diarias` não existe → bloqueia
- Cabeçalho sem a coluna `data`, ou sem nenhuma das colunas `faturamento`/`pedidos` → bloqueia, template considerado inválido
- Coluna do cabeçalho que não bate com nenhuma `Metric.chave` conhecida e não é `data` → não bloqueia; é ignorada na gravação e listada como "coluna não reconhecida" no log do lote
- Coluna reconhecida ausente do cabeçalho (ex.: cliente não vende no Shopee e nunca teve a coluna `vendas_shopee`) → não bloqueia; registrado como aviso, não como erro

**Nível linha:**
- `data` vazia ou em formato inválido → linha inteira descartada, contabilizada em linhas com erro
- Duas linhas com a mesma `data` no mesmo lote → vale a última ocorrência da planilha; a anterior é registrada como aviso de sobrescrita
- Valor de métrica não numérico (texto, símbolo) → só aquela célula é ignorada, o resto da linha segue normalmente
- Valor negativo em métricas que não podem ser negativas (`faturamento`, `pedidos`, `estoque_total`, `pedidos_atrasados`, `produtos_criticos`, `ruptura_skus`) → célula ignorada, registrada como erro de campo
- Célula vazia → não é erro; simplesmente não gera `MetricSnapshot` para aquela métrica naquele dia

**Nível lote (fechamento):**
- Nenhuma linha processada com sucesso → `ImportBatch.status = falha`
- Pelo menos uma linha ok e pelo menos uma com problema → `status = parcial` (os dados válidos são gravados mesmo assim — um lote parcial nunca é descartado por inteiro)
- Todas as linhas ok → `status = sucesso`

## 6. Como gravar em MetricSnapshot

- Chave de identidade de um snapshot: `companyId + metricId + data` (a `dimensão` fica nula para as 10 métricas desta sprint — nenhuma delas é quebrada por canal como dimensão, já que canal já é a própria métrica, ex. `vendas_shopee`)
- Gravação é sempre **upsert**: se já existe um snapshot para essa combinação, o valor é atualizado — isso é o que permite reimportar a mesma planilha (ou uma correção do cliente) sem gerar duplicidade
- Todo snapshot importado guarda o `importBatchId` de origem, para rastreabilidade ("de onde veio esse número")
- `ticket_medio`, por ser calculado e não lido direto da planilha, é gravado com uma marcação de origem diferente (`calculada`, contra `importada` dos demais) — mesma tabela, mesmo `importBatchId` do lote que originou o cálculo
- Nota técnica para quem for implementar: como `dimensão` é opcional (nula) nessas 10 métricas, a chave de unicidade não pode depender de comparação direta de nulo (bancos tratam NULL como "diferente de qualquer coisa" em índices únicos) — resolver com um valor padrão consistente (ex.: string vazia) no lugar de nulo, para a unicidade realmente funcionar

## 7. Como registrar ImportBatch

- Criado no início do processamento, com status `em_andamento`
- Campos preenchidos ao final: `finalizadoEm`, `status` (sucesso/parcial/falha), `linhasOk`, `linhasComErro`
- `log` é uma lista estruturada de entradas, cada uma com: linha (quando aplicável), coluna (quando aplicável), tipo (`erro` ou `aviso`), mensagem em linguagem clara — não código de erro genérico
- O lote fica associado à `DataSource` que o originou e à `Company` (redundante com a fonte, mas evita join extra nas telas de histórico)
- Todo lote fica salvo, mesmo os que falham 100% — histórico de importação nunca é apagado, só acumulado (é o que dá confiança ao cliente de que o sistema não esconde problema)

## 8. Estados de erro

**Estado da fonte (`DataSource.status`):**
| Estado | Significado |
|---|---|
| `nunca_importado` | fonte cadastrada, nenhuma importação rodou ainda |
| `ativa` | última importação teve sucesso total |
| `parcial` | última importação teve algumas linhas com problema, mas gravou o que deu |
| `com_erro` | última importação falhou por completo (sem acesso, aba ausente, template inválido) |

**Mensagens claras — exemplos que a interface deve mostrar (não apenas logar):**
- "Não foi possível acessar a planilha. Compartilhe-a com [email do Service Account] como leitor."
- "A aba 'Metricas_Diarias' não foi encontrada nesta planilha."
- "Nenhuma coluna reconhecida no cabeçalho. Confira se a primeira linha segue o template."
- "Linha 8: data vazia ou inválida — linha ignorada."
- "Linha 12, coluna 'estoque_total': valor 'N/D' não é um número — célula ignorada."
- "Métrica 'vendas_shopee' não encontrada nesta planilha — nenhum dado importado para ela nesta importação."
- "23 de 25 linhas importadas com sucesso. 2 linhas com erro — veja o detalhe abaixo."

A régua é: toda mensagem de erro cita o que aconteceu e, quando possível, o que fazer a respeito — nunca um erro técnico cru.

## 9. Seed das métricas principais (catálogo `Metric`)

| chave | nome | unidade | agregação | origem |
|---|---|---|---|---|
| `faturamento` | Faturamento | R$ | soma | importada |
| `pedidos` | Pedidos | unidades | soma | importada |
| `ticket_medio` | Ticket Médio | R$ | média | calculada |
| `vendas_mercado_livre` | Vendas — Mercado Livre | R$ | soma | importada |
| `vendas_shopee` | Vendas — Shopee | R$ | soma | importada |
| `vendas_site` | Vendas — Site Próprio | R$ | soma | importada |
| `pedidos_atrasados` | Pedidos Atrasados | unidades | soma | importada |
| `produtos_criticos` | Produtos Críticos | unidades | soma | importada |
| `ruptura_skus` | SKUs em Ruptura | unidades | soma | importada |
| `estoque_total` | Estoque Total | R$ | soma | importada |

`configLimiar` de cada métrica fica com um valor padrão neutro nesta sprint (sem regra de insight ligada ainda) — o campo existe no schema desde a Sprint 0, mas só passa a ser usado de fato na sprint do motor de insights.

## 10. Critérios de aceite

- Planilha Google seguindo o template importa sem erro e cada coluna preenchida vira um `MetricSnapshot` correto
- `ticket_medio` aparece calculado automaticamente para todo dia com `faturamento` e `pedidos` válidos
- Planilha sem uma ou mais colunas recomendadas (ex.: sem `vendas_shopee`) importa normalmente, com aviso claro listando o que não foi encontrado
- Linha com erro (data inválida ou valor não numérico) não derruba o lote inteiro — as demais linhas são gravadas
- Reimportar a mesma planilha (sem mudança ou com correção) não gera `MetricSnapshot` duplicado — atualiza o existente
- Upload de CSV/XLSX segue exatamente as mesmas regras de validação e produz o mesmo resultado que a leitura via Google Sheets
- Tela de Integrações mostra o status atual da fonte e o histórico dos últimos lotes, cada um com seu log legível
- Seed cria as 10 métricas do catálogo corretamente, com origem `importada` ou `calculada` conforme a tabela da seção 9
- Todo lote de importação (inclusive os que falham) fica registrado e visível — nada é descartado silenciosamente

## 11. O que não fazer

- Não construir o Dashboard Executivo — no máximo uma tela crua de conferência dos dados importados (tabela simples de `MetricSnapshot` por data), só para validar que o dado entrou certo; isso não é o dashboard da próxima sprint
- Não implementar o motor de regras de insight nem gerar `Insight`/`Alert` a partir desses dados
- Não criar `Product` ou `InventorySnapshot` — `produtos_criticos` e `ruptura_skus` continuam sendo números que o cliente relata, não uma varredura de SKU feita pelo sistema
- Não suportar múltiplas abas ou templates variáveis por planilha — uma aba fixa (`Metricas_Diarias`) por fonte
- Não permitir edição manual de `MetricSnapshot` pela interface — só entra dado via importação nesta sprint
- Não integrar Bling
- Não tentar tolerar qualquer estrutura de planilha livre — o cliente segue o template, ou a Borges ajusta a planilha do cliente para o padrão antes de cadastrar a fonte
- Não implementar leitura em tempo real via webhook do Google Sheets — cron diário mais botão manual é suficiente
- Não criar permissão granular por métrica — quem acessa a empresa acessa todas as métricas dela
